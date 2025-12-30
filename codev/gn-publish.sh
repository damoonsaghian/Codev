src_dir="$1"
gnunet_namespace="$2"
publish_name="$3"

# https://www.gnunet.org/en/use.html
# https://wiki.archlinux.org/title/GNUnet
# https://manpages.debian.org/unstable/gnunet/
# https://git.gnunet.org/gnunet.git/tree/src

# https://docs.gnunet.org/latest/users/subsystems.html
# https://docs.gnunet.org/latest/users/configuration.html#access-control-for-gnunet
# https://manpages.debian.org/unstable/gnunet/gnunet.1.en.html
# https://manpages.debian.org/unstable/gnunet/index.html
# https://wiki.archlinux.org/title/GNUnet

# "$project_dir/.data/gnunet/project" file contains these lines:
# , namespace (public key of the ego used for publishing)
# , project name
# , the level of anonymity
# if this file exists use it, try to copy from a siblibg project "$project_dir/../*/.data/gnunet",
# 	otherwise ask the user, and create one
# also there is "$project_dir/.data/gnunet/<namespace>" file containg alternative namespaces
# other than the main ego, create at least two alternative egos
# https://docs.gnunet.org/latest/developers/apis/revocation.html
# only the private key of the first ego is kept locally
# other private keys will be stored (encrypted) on one or more removable devices

# ask for password
# sd decrypt <egos-dir>
# gnunet-publish
# https://github.com/oszika/ecryptbtrfs

# create ref links (or read'only hard links) of the files in $project_dir/.data/gnunet/publish
# this way GNUnet can publish the files using the indexed method

# when ref/hard linking files to publish dir, skip symlinks

# skip .cache directory

# gnunet-search gnunet://fs/sks/$gnunet_namespace/$publish_name
# find the latest version, then compute the next version
sks_identifier=
sks_next_identifier=

# when a publish is in progress, and for minutes after that, inhibit suspend
# also when a shutdown is requested, notice the user, and ask to confirm
