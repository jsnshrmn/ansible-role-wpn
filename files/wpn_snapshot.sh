#!/usr/bin/env bash
## Create point-in-time backup of Wordpress.

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
    cat <<USAGE
wpn_snapshot.sh creates a db dump and tar GZip backup for a site.

Usage: wpn_snapshot.sh \$sitepath
            
\$sitepath   Wordpress Network to tar GZip (eg. /srv/example).

Backups will be stored at $sitepath/snapshots/$site.${wpn_host_suffix}.$dow.tar.gz. $dow is
the lowercase day-of-week abbreviation for the current day.

USAGE
    exit 1;
fi

sitepath=$1
site=$(basename "$sitepath")
dow=$( date +%a | awk '{print tolower($0)}')

if [[ ! -e "$sitepath" ]]; then 
    echo "Can't create snapshot of nonexistent site at $sitepath."
    exit 1;
fi

echo "Making ${dow} snapshot for $sitepath"

# Make a db backup in case the latest one is old
wpn_dump.sh $sitepath

# If we don't have a target s3 bucket, use the local filesystem.
if [ -z "${wpn_s3_snapshot_dir}" ]; then
    snapshotdir="$sitepath/snapshots"

    # Make sure we have a place to stick snapshots
    sudo -u apache mkdir -p "$snapshotdir"

    # Fix any permissions issues before tying to run backup.
    /opt/wpn/bin/wpn_perms_fix.sh "$sitepath"

    # Tar files required to rebuild, with $site as TLD inside tarball. 
    sudo -u apache tar -czf "$snapshotdir/$site.${wpn_host_suffix}.${dow}.tar.gz" -C /srv/ "${site}/etc" "${site}/db" "${site}/wp"
# Otherwise use aws s3
else
    snapshotdir=${wpn_s3_snapshot_dir}
    sudo -u apache tar -cf - -C /srv/ "${site}/etc" "${site}/db" "${site}/wp" | gzip --stdout --best | aws s3 cp - "$snapshotdir/$site.${wpn_host_suffix}.$dow.tar.gz" --sse
fi

echo "Snapshot created at ${snapshotdir}/${site}.${wpn_host_suffix}.${dow}.tar.gz"
