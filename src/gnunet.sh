# "https://www.gnunet.org/en/use.html"
# "https://wiki.archlinux.org/title/GNUnet"
# "https://docs.gnunet.org/"
# "https://manpages.debian.org/unstable/gnunet/"
# "https://manpages.debian.org/unstable/gnunet/gnunet.conf.5.en.html"

# keys:
# , primary key pair (used for first encounter)
# , mutual key triplets (a private/public key pair plus the public key of a trusted account)
# backup (encrypted) keys

# opensc/opencryptoki/coolkey/softhsm: smartcard device to protect the private key (eg NitroKey)
# since private key does not leave the smartcard, it can't be backed up
# so we must be able to have multiple keys per identity, and to add keys to an identity,
# 	and to inform mutual pairs of this addition
# gnunet-identity does not have multiple keys per identity
# "https://www.kernel.org/doc/html/latest/process/maintainer-pgp-guide.html"

# Libgcrypt and libcrypto (OpenSSL) do not support NTRU Prime; wolfCrypt does
# "https://openquantumsafe.org/"

# "https://manpages.debian.org/unstable/gnunet/gnunet-directory.1.en.html"
# "https://manpages.debian.org/unstable/gnunet/gnunet-fs.1.en.html"

# "https://www.gnu.org/software/diffutils/manual/html_mono/diff.html"
# "https://stackoverflow.com/questions/16902001/manually-merge-two-files-using-diff"
# file tree diff
# "https://stackoverflow.com/questions/776854/how-do-i-compare-two-source-trees-in-linux"
# "https://github.com/dandavison/delta"
# "https://github.com/so-fancy/diff-so-fancy"
# "https://diffoscope.org/"
# "https://github.com/MightyCreak/diffuse"
# "http://meldmerge.org/"
# "https://git-scm.com/docs/git-diff"

publish() {
	# create ref links of the project files, in ".cache/gnunet/publish"
	# this way GNUnet can publish the files using the indexed method
	# note that projects reside in non-removable BTRFS'formated disks

	# ".cache" directory will not be published
	# also do not follow mount points
}

unpublish() {}

download() {}

pull() {}

pull_request() {}

website() {
	# we still need a website so the unfortunate users of conventional internet can see and find us
	# create/update website
	
	# on a linux server use gnunet to download projects, and host a website
	# apt-get --yes install openssh-client
	# https://man.archlinux.org/listing/openssh
	# https://man.archlinux.org/man/core/openssh/ssh.1.en
	# https://man.archlinux.org/man/core/openssh/ssh-add.1.en
	# https://man.archlinux.org/man/core/openssh/ssh-keygen.1.en
	# https://wiki.archlinux.org/title/SSH_keys#ssh-agent
	# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
	# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml
	# create a user in one of "hashbang.sh" servers
	# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
	# currently, the ~/Public folder isn't exposed over HTTP by default
	# use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
	# https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
	
	# ssh user@host "command"
	
	# why use openssh instead of libssh:
	# libssh must be compiled with openssl (not gcrypt) to support smartcards
	# although gcrypt itself supports pkcs11
	# https://github.com/simonsj/libssh/blob/master/doc/pkcs11.dox
	# also we need ssh-agent to open multiple keys with the same password
	# openssh + opensc/opencryptoki/coolkey/softhsm: smartcard device to protect the private key
	# and at last, libssh does not support NTRU Prime yet
	# https://www.openssh.com/txt/release-9.0
	
	# create an html web'page "~/Public/project_name/index.html", showing the files in the project
	# https://nanoc.app/about/
	# https://github.com/nanoc/nanoc
	# https://docs.antora.org/
	# when converting to html, convert tabs to html tables, to have elastic tabstops
	
	# http://m-net.arbornet.org/index.php
	# https://freeshell.de/
	# https://envs.net/
	# https://tilde.club/
	# https://ninthfloor.org/
	# copy the public key to the server:
	# https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
	
	# or we can use Alpine Docker containers on top of cloud services:
	# https://hub.docker.com/_/alpine
	# https://cloud.google.com/run
	# https://render.com/docs/docker
	# https://fly.io/
	# https://www.ibm.com/cloud/free/
	
	# hashbang init:
	
	remote_host=$1
	user=$2
	# if they are empty, ask for them
	
	printf "\nHost %s\n  User %s\n" "$remote_host" "$user" >> ~/.ssh/config
	
	{ echo "$user" | sed -n "/^[a-z][a-z0-9]{0,30}$/!{q1}"; } || {
		echo "\"$user\" is not a valid username"
		echo "a valid username must:"
		echo ", be between between 1 and 31 characters long"
		echo ", consist of only 0-9 and a-z (lowercase only)"
		echo ", begin with a letter"
		exit 1
	}
	
	ssh "$user"@"$remote_host" && return
	
	# if there is no SSH keys, create a key pair
	# ssh-keygen -t ed25519
	# openssh key format: ssh-ed25519 ...
	
	echo
	echo " please choose a server to create your account on"
	echo
	hbar
	printf -- '  %-1s | %-4s | %-36s | %-8s | %-8s\n' \
		"#" "Host" "Location" "Users" "Latency"
	hbar
	
	host_data=$(wget -q -O - --header 'Accept:text/plain' https://hashbang.sh/server/stats)
	# note that busybox wget in Alpine supports secure download from https
	# https://git.alpinelinux.org/aports/tree/main/busybox/0009-properly-fix-wget-https-support.patch
	# "ssl_client" package is automatically pulled in if both busybox and libssl is installed
	
	while IFS="|" read -r host _ location current_users max_users _; do
		host=$(echo "$host" | cut -d. -f1)
		latency=$(time_cmd "wget -q -O /dev/null \"${host}.hashbang.sh\"")
		n=$((n+1))
		printf -- '  %-1s | %-4s | %-36s | %8s | %-8s\n' \
			"$n" \
			"$host" \
			"$location" \
			"$current_users/$max_users" \
			"$latency"
	done <<-INPUT
	"$host_data"
	INPUT
	
	echo
	while true; do
		printf ' Enter Number 1-%i : ' "$n"
		read -r choice
		case "$choice" in
			''|*[!0-9]*) number="no";;
		esac
		if [ "$number" != "no" ] && [ "$choice" -ge 1 ] && [ "$choice" -le $n ]; then
			break;
		fi
	done
	
	host=$(echo "$host_data" | head -n "$choice" - | tail -n1 | cut -d \| -f1)
	
	pulic_key=$(cat ~/.ssh/id_ed25519.pub)
	host=de1.hashbang.sh
	wget --post-data="{\"user\":\"$user\",\"key\":\"$public_key\",\"host\":\"$host\"}" \
	--header='Content-Type: application/json' https://hashbang.sh/user/create
}

# audio conversasion is already implemented; add video
# "https://git.gnunet.org/gnunet.git/tree/src/conversation"
# "https://git.gnunet.org/gnunet.git/tree/src/conversation/gnunet_gst.c"
# "https://manpages.debian.org/unstable/gnunet/gnunet-conversation.1.en.html"
# figure out how to send/receive streams to/from gnunet
# send/receive streams to/from encoder/decoder pipline
# use pipewire to access camera
# use video widget to put it on gui

case "$1" in
	publish) publish ;;
	unpublish) unpublish ;;
	download) download ;;
	pull) pull ;;
	pull-request) pull_request ;;
	website) website ;;
esac
