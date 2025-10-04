gnunet_namespace="$1"
publish_name="$2"
download_dir="$3"

# download to $project_dir/.cache/gnunet/download
# create reflinks to $project_dir and $project_dir/.data/gnunet/pristine
# to download new version, download gnunet dir file (non'recursively)
# use gnunet_directory to get CHK of the files to be downloaded
# use gnunet-publish --simulate-only to obtain the CHK of old files in $project_dir/.cache/gnunet/download
# if there is a common CHK with different filenames, rename the file
# if there is a gnunet dir file with a new CHK, do the above for it
# now download the whole directory recursively
# this method ensures that a simple file rename will not impose a download
# note that this method will also replace corrupted files (eg due to bitrot)

# find the latest version
gnunet-search gnunet://fs/sks/$gnunet_namespace/"$publish_name"
# if above command succeeds (network is connected) but returns empty result: echo "not found"; exit
gnunet_url=

# to download a project, we need:
# , project name
# , namespaces (public keys of egos that can be used for publishing)
# if a namespace is revoked, try the next one
# the alternative namespaces can only be revealed if one has the revoke message
# the revoke message will be pre calculated (can take days or weeks)
# https://docs.gnunet.org/v0.20.x/developers/revocation/revocation.html
