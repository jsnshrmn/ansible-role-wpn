#!/usr/bin/env bash
## Bootstrap an empty wpn site

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
wpn_init.sh builds a Wordpress Network.

Usage: wpn_init.sh \$sitepath

\$sitepath    local path for Wordpress Network (eg. /srv/example).

USAGE

  exit 1;
fi

sitepath="$(realpath  --canonicalize-missing --no-symlinks $1)"

## Don't blow away existing sites
if [[ -e "$sitepath" ]]; then
    echo "$sitepath already exists!"
    exit 1
fi

## Grab the base for sitepath to use as slug
site=$(basename "$sitepath")

## Sanitize the DB slug by excluding everything that MySQL doesn't like from $site
DBSLUG=$(echo -n  "${site}" | tr -C '_A-Za-z0-9' '_')

echo "Initializing site at ${sitepath}."

# Get external host suffix (rev proxy, ngrok, etc)
read -r -e -p "Enter host suffix: " -i "$wpn_host_suffix" my_host_suffix

# By default, we're operating at the root for a domain
subpath="";

# Get mysql host
read -r -e -p "Enter MYSQL host name: " -i "$wpn_dbhost" my_dbhost

# Get mysql port
read -r -e -p "Enter MYSQL host port: " -i "$wpn_dbport" my_dbport

# Get DB admin user
read -r -e -p "Enter MYSQL user: " -i "$wpn_dbsu" my_dbsu

# Get DB admin password
read -r -s -p "Enter MYSQL password: " my_dbsu_pass
while  [ -z "$my_dbsu_pass" ] || ! mysql --host="$my_dbhost" --port="$my_dbport" --user="$my_dbsu" --password="$my_dbsu_pass"  -e ";" ; do
    read -r -s -p "Can't connect, please retry: " my_dbsu_pass
done

# Add some whitespace because read doesn't
echo
echo "Let's build a site!"

## Make the parent directory
sudo -u apache mkdir -p "$sitepath"
sudo -u apache chmod 775 "$sitepath"

## Download wpn core
sudo -u apache wp core download --path="${sitepath}/wp" --locale=en_US || exit 1;

## Create the config file
sudo -u apache wp config create --path="${sitepath}/wp" --dbhost=${my_dbhost}:${my_dbport} --dbuser=${my_dbsu} --dbpass=${my_dbsu_pass} --dbname=wpn_${site}_${env_name} --locale=en_US || exit 1;

## Create the database
mysql -h ${my_dbhost} -P ${my_dbport} -u ${my_dbsu} -p${my_dbsu_pass} -e "create database wpn_${site}_${env_name}; GRANT ALL PRIVILEGES ON wpn_${site}_${env_name}.* TO '${my_dbsu}'@'%' IDENTIFIED BY '${my_dbsu_p
ass}'" || exit 1;

## Install wpn core
sudo -u apache wp core multisite-install  --path="${sitepath}/wp" --url="${site}.${my_host_suffix}${subpath}" --title="${site}" --admin_email=admin@${site}.${my_host_suffix}  --subdomains --skip-email || exit 1;

# Apply our standard permissions to the new site
wpn_perms_fix.sh "$sitepath"

## Apply the apache config
wpn_httpd_conf.sh "$sitepath" || exit 1;

echo "Finished building site at ${sitepath}."
