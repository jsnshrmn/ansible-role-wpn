#!/usr/bin/env bash
## Sync Wordpress files & DB from source host

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
wpn_dump.sh performs a dump of the database for a Wordpress Network.

Usage: wpn_dump.sh \$sitepath
            
\$sitepath  Wordpress Network to sql dump (eg. /srv/example).
USAGE

  exit 1;
fi

sitepath=$1

echo "Dumping $sitepath database"

## Bail if the site doesn't exist
if [[ ! -e $sitepath ]]; then
    exit 1;
fi

## Grab the basename of the site to use in a few places.
site=$(basename "$sitepath")

dbfile="${sitepath}/db/wpn_${site}_dump.sql"

## Make the database dump directory
sudo -u apache mkdir -p "$sitepath/db"

## Perform sql-dump
sudo -u apache drush -r "$sitepath/wpn" sql-dump --result-file="$sitepath/db/wpn_${site}_dump.sql"
sudo -u apache bash -c "mysqldump -h ${my_dbhost} -P ${my_dbport} -u ${my_dbsu} -p${my_dbsu_pass} wpn_${site}_${env_name} > ${dbfile}" || exit 1;

## Set perms
wpn_perms.sh --sticky "$sitepath/db"

echo "Finished dumping $sitepath database."
