#!/usr/bin/env bash
## Restore point-in-time backup of WordPress.

source /opt/wpn/etc/wpn_conf.sh

## Require arguments
if [  -z "$1" ]; then
    cat <<USAGE
wpn_restore.sh restores an existing site snapshot backup.

Usage: wpn_restore.sh \$sitepath \$dow

\$sitepath   path to WordPress Network to restore
\$dow        lowercase day-of-week abbreviation indicating backup 
             to restore. Must be one of sun, mon, tue, wed, thu, fri, or sat.
USAGE

    exit 1;
fi

sitepath=$1
dow=$2
site=$(basename "$sitepath")

if [ ! -d "$sitepath" ]; then
  echo "${sitepath} doesn't exist, nothing to restore."
  exit 0
fi

if [ -z "${dow}" ]; then
  echo "No snapshot specified."
  echo "The following snapshots exist:"

  # If we don't have a target s3 bucket, use the local filesystem.
  if [ -z "${wpn_s3_snapshot_dir}" ]; then
    ls --human-readable --full-time -t --reverse "${sitepath}/snapshots/" | cut -d ' ' -f 5,6,7,9
  # Otherwise use aws s3. Trailing slash required.
  else
    aws s3 ls --human-readable "${wpn_s3_snapshot_dir}/" | grep "${site}" | sort
  fi

  exit 0
fi

# If we don't have a target s3 bucket, use the local filesystem.
if [ -z "${wpn_s3_snapshot_dir}" ]; then
  snapshotfile="${sitepath}/snapshots/${site}.${wpn_host_suffix}.${dow}.tar.gz"

  # Verify the file is there
  if [ ! -f "$snapshotfile" ]; then
    echo "No snapshot at ${snapshotfile}"
    exit 0
  fi

# Otherwise use aws s3
else
  snapshotfile="${wpn_s3_snapshot_dir}/${site}.${wpn_host_suffix}.${dow}.tar.gz"
fi

echo "Restoring ${dow} snapshot of ${sitepath}."

# If we don't have a target s3 bucket, use the local filesystem.
if [ -z "${wpn_s3_snapshot_dir}" ]; then

# Tarballs include the $site folder, so we need to strip that off
    # when extracting
    sudo -u apache tar -xvzf  "${snapshotfile}" -C "${sitepath}" --strip-components=1 --no-overwrite-dir
# Otherwise use aws s3
else

    # Tarballs include the $site folder, so we need to strip that off
    # when extracting
    sudo -u apache bash -c "aws s3 cp '${snapshotfile}' - | tar -xvzf - -C '${sitepath}' --strip-components=1 --no-overwrite-dir" || exit 1;
fi


echo "Files from snapshot restored." 
echo "Now run wpn_importdb.sh ${sitepath} to restore the db for the site."
