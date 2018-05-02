#!/usr/bin/env bash
## Set permissions on the specified dir

source /opt/wpn/etc/wpn_conf.sh

if [  -z "$1" ]; then
  cat <<USAGE
wpn_perms.sh sets our preferred permissions for a Wordpress path. 

Usage: wpn_perms.sh [--sticky] \$dir
            
--sticky    Optional argument adds group write with sticky bit. 
            This is the default behavior for dev environments.  
\$inputdir      Folder to modify (eg. /srv/example/wp).
USAGE

  exit 1;
fi

# Process options and args
if [ "$1" == "--sticky" ] ; then 
    sticky="sticky"
    inputdir="$2"
else
    inputdir=$1
fi

# Validate arguments
if  [ -z "$inputdir" ] || [ ! -e "$inputdir" ]; then 
    echo "Error: Cowardly refusing to set perms on nonexistent \$inputdir \"${inputdir}\"."
    exit 1;
fi

if  [[ "${env_name}" == *dev ]] || [ "${sticky}" == "sticky" ]; then
  # Looser permissions in sticky mode and dev environments so that
  # files can be moved around by all group members
  dirperms='u=rwxs,g=rwxs,o='
  fileperms='u=rw,g=rw,o='
  policy="sticky group"
else
  # Default to more restrictive perms for wpn files in prod mode
  dirperms='u=rwx,g=rx,o='
  fileperms='u=rw,g=r,o='
  policy="strict (no group)"
fi

if [ ! -d "$inputdir" ]; then
  echo "cannot access ${inputdir}: No such directory"
  exit 1
fi

echo "Setting ${policy} permissions on ${inputdir}"

## Set SELinux context.  Useless over NFS/SMB.
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "${inputdir}(/.*)?"
sudo restorecon -R "${inputdir}"

## Set perms. Try as apache first, then as self.

## Find all of the dirs.
declare -a dirs
while IFS= read -r -d '' dir; do
  
  ## Add dir to the array.
  dirs+=( "$dir" )
done < <(find "${inputdir}" -type d -print0 2>/dev/null)

## Loop through the dirs, setting appropriate perms.
for dir in "${dirs[@]}"; do
  printf "." 

  ## Set group to apache.
  sudo -u apache chgrp apache "${dir}" 2>/dev/null || \
  chgrp apache "${dir}" 

  ## Set dir perms.
  sudo -u apache chmod ${dirperms} "${dir}" 2>/dev/null || \
  chmod ${dirperms} "${dir}" 
done

## Find all of the files.
declare -a files
while IFS= read -r -d '' file; do
  files+=( "$file" )
done < <(find "${inputdir}" -mindepth 1 -type f -print0 2>/dev/null)

## Loop through the files, setting appropriate perms.
for file in "${files[@]}"; do
  printf "." 

  ## Set group to apache.
  sudo -u apache chgrp apache "${file}" 2>/dev/null || \
  chgrp apache "${file}"

  ## Set file perms.
  sudo -u apache chmod ${fileperms} "${file}" 2>/dev/null || \
  chmod ${fileperms} "${file}"
done

echo "Done!"

# Returning 0 because variances in storage leads to a lot of false
# positives in detecting errors.
exit 0
