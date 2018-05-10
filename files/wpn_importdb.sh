#!/usr/bin/env bash
## Sync Wordpress files & DB from source host

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
wpn_importdb.sh imports a Wordpress database file.

Usage: wpn_importdb.sh \$sitepath [\$dbfile]

\$sitepath  Wordpress Network path
\$dbfile    Wordpress database file to load

If \$dbfile is not given, then \$sitepath/db/wpn_\$site_dump.sql will be used.
USAGE

  exit 1;
fi

sitepath=$1
echo "Processing $sitepath"

if [[ ! -e $sitepath ]]; then
    echo "No site exists at ${sitepath}."
    exit 1;
fi

## Grab the basename of the NEW site to use in a few places.
site=$(basename "$sitepath")

if [[ ! -z "$2" ]]
then
    dbfile=$2
else
    dbfile="${sitepath}/db/wpn_${site}_dump.sql"
fi

if [[ ! -f $dbfile ]]; then
    echo "No file exists at ${dbfile}."
    exit 1;
fi

## Load sql-dump to local DB
echo "Importing database for $site from file at $dbfile."
sudo -u apache bash -c "mysql -h ${wpn_dbhost} -P ${wpn_dbport} -u ${wpn_dbsu} -p${wpn_dbsu_pass} -D wpn_${site}_${env_name} < ${dbfile}" || exit 1;

echo "Database imported."

## Restored DBs might need updates
sudo -u apache wp core update --path="${sitepath}/wp" --locale=en_US --minor || exit 1;
sudo -u apache wp plugin update --path="${sitepath}/wp" --all --minor || exit 1;
sudo -u apache wp theme update --path="${sitepath}/wp" --all || exit 1;
