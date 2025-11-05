script_dir="$(dirname "$(realpath "$0")")"

ovl_dir="$script_dir"/../.cache/ovl
rm -r "$ovl_dir"
mkdir -p "$ovl_dir"

mkdir -p "$ovl_dir"/etc
touch "$ovl_dir"/etc/.default_boot_services

mkdir -p "$ovl_dir"/etc/runlevels/default
ln -sf /etc/init.d/local "$ovl_dir"/etc/runlevels/default

printf '#!/usr/bin/env sh
# run only once
rm -f /etc/local.d/auto-setup-alpine.start
rm -f /etc/runlevels/default/local
sh /codev/alpine/new.sh
' > "$ovl_dir"/etc/local.d/auto-setup-alpine.start

cp -r "$script_dir/.. "$ovl_dir"/codev

tar --owner=0 --group=0 -czf localhost.apkovl.tar.gz -C ovl "$script_dir"/../.cache/

rm -r "$ovl_dir"
