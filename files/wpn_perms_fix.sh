#!/usr/bin/env bash
## Fix perms of wpn site

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
wpn_perms_fix.sh sets our preferred permissions for all Wordpress paths in a site folder. 

Usage: wpn_perms_fix.sh \$sitepath

\$sitepath   Site to apply permissions (eg. /srv/example).
USAGE

  exit 1;
fi

sitepath=$1

echo "Fixing permissions for ${sitepath}."

# Set perms
wpn_perms.sh "$sitepath/wpn"
wpn_perms.sh --sticky "$sitepath/db"
wpn_perms.sh --sticky "$sitepath/etc"

# Pay specific attention to the file with the passwords 
sudo -u apache chmod 444 "$sitepath/wpn/wp-config.php"

exit 0
