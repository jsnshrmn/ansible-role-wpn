#!/usr/bin/env bash
## Create Apache config for Wordpress Network
PATH=/opt/wpn/bin:/usr/local/bin:/usr/bin:/bin:/sbin:$PATH

source /opt/wpn/etc/wpn_conf.sh

## Require arguments
if [ ! -z "$1" ]
then
  sitepath=$1
  echo "Processing $sitepath"
else
  echo "Requires site path (eg. /srv/sample) as argument"
  exit 1;
fi

## Site should already be there
if [[ ! -e $sitepath ]]; then
    echo "$sitepath doesn't exist!"
    exit 1
fi

## Grab the basename of the site to use in conf.
site=$(basename "$sitepath")

## Make the apache config
echo "Generating Apache Config."
sudo -u apache mkdir "/srv/$site/etc"
wpn_perms.sh --sticky "$sitepath/etc"

sudo -u apache sh -c "sed "s/__wpn_base_dir__/$site/g" /opt/wpn/etc/wpn_init_httpd_template > /srv/$site/etc/srv_$site.conf" || exit 1;
sudo systemctl restart ${httpd_service} || exit 1;
