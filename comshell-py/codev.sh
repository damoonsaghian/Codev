# https://digint.ch/btrbk/

# codev only acts on projects residing in non-removable BTRFS'formated disks

# for syncing we use an index file, and rename all files to their MD5 hash
# each line in the index file: hash path

# xattr: hash, hash'time
# if hash'time is younger than mtime, it means that hash is valid
# https://man7.org/linux/man-pages/man1/getfattr.1.html
# https://man7.org/linux/man-pages/man1/setfattr.1.html

# we will have three directories in a project's ".data/codev/" directory, containing hash'named files:
# , indexed: reflinks to the files in the project
# , remote: files downloaded from remote
# , pristine: the original files which where reflinked into the project directory

# diff will be based on the working directory, pristine and remote

# pull requests contain 2 index files: changed and pristine

# branches: multiple index files

# atomic operations in the server: make directories of hardlinks, mv directory

# openssh + opensc/opencryptoki/coolkey/softhsm: smartcard device to protect the private key

# ssh user@host "command"

# webrtc

# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml

hbar() {
	printf -- ' %72s\n' ' ' | tr ' ' '-'
}

time_cmd() {
	start_time=$(date +%s%3N)
		$1 1>/dev/null 2>&1
		end_time=$(date +%s%3N)
	return $(( end_time - start_time ))
}

# this function can be called with two parameters:
# first is obligatory, it's the question posed
# second parameter is optional, it's the default answer, and can be either Y or N
ask() {
	while true; do
		prompt=""
		default=""
		
		if [ "${2}" = "Y" ]; then
			prompt="Y/n"
			default=Y
		elif [ "${2}" = "N" ]; then
			prompt="y/N"
			default=N
		else
			prompt="y/n"
			default=
		fi
		
		# ask the question
		echo ""
		printf "%s [%s] " "$1" "$prompt"
		read -r reply
		
		# default?
		if [ -z "$reply" ]; then
			REPLY=$default
		fi
		
		# check if the reply is valid
		case "$reply" in
			Y*|y*) return 0 ;;
			N*|n*) return 1 ;;
		esac
	
	done
	echo " "
}

set_ssh_public_key() {
	for keytype in id_ed25519 id_ecdsa id_rsa id_dsa; do
		if [ -e ~/.ssh/${keytype}.pub ] && [ -e ~/.ssh/${keytype} ]; then
			if ask "  found a public key in \"~/.ssh/${keytype}.pub\"; use this key?" Y; then
				private_keyfile="${HOME}/.ssh/${keytype}"
				public_key="$(cat ~/.ssh/${keytype}.pub)"
				break
			fi
		fi
	done
	
	if [ -z "$public_key" ]; then
		echo "  no SSH key for login to server found, attempting to generate one"
		while true; do
		private_keyfile="$HOME/.ssh/id_ed25519"
		
			echo ""
			if [ ! -e "$private_keyfile" ] && [ ! -e "$private_keyfile.pub" ]; then
				if ask "  do you want to generate a new key?" Y; then
					if [ -e "$private_keyfile" ]; then
						if ask "  file exists: $private_keyfile; delete?" Y; then
							rm "$private_keyfile"
							if [ -e "${private_keyfile}.pub" ]; then
								rm "${private_keyfile}.pub"
							fi
						else
							continue
						fi
					fi
					if makekey "${private_keyfile}"; then
						break
					fi
				fi
			elif [ ! -e "$private_keyfile" ] && [ -e "${private_keyfile}.pub" ]; then
				if ask "  found public keyfile, missing private; do you wish to continue?" N; then
					echo "  using public key ${private_keyfile}.pub"
					break
				else
					echo "  resetting"
				fi
			elif [ ! -e "${private_keyfile}.pub" ]; then
				echo "  unable to find public key ${private_keyfile}.pub"
			else
				echo "  using public key ${private_keyfile}.pub"
				break
			fi
		done
		public_key=$(cat "${private_keyfile}.pub")
	fi
}

init() {
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
	
	# https://man.archlinux.org/listing/openssh
	# https://man.archlinux.org/man/core/openssh/ssh.1.en
	# https://man.archlinux.org/man/core/openssh/ssh-add.1.en
	# https://man.archlinux.org/man/core/openssh/ssh-keygen.1.en
	# https://wiki.archlinux.org/title/SSH_keys#ssh-agent
	
	# if there is no SSH keys, create a key pair
	# ssh-keygen -t ed25519
	# openssh key format: ssh-ed25519 ...

	# create a user in one of "hashbang.sh" servers
	# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
	
	# currently, the ~/Public folder isn't exposed over HTTP by default
	# use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
	# https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
	
	# delete the public key after sending it to the server (it can be regenerated form the private key)
	
	# for ssh man'in'the'middle attack in impossible
	# even if server's private key is compromised, it remains secure as long as the user's private key is safe
	# https://www.gremwell.com/ssh-mitm-public-key-authentication
	
	echo
	echo " please choose a server to create your account on"
	echo
	hbar
	printf -- '  %-1s | %-4s | %-36s | %-8s | %-8s\n' \
		"#" "Host" "Location" "Users" "Latency"
	hbar
	
	host_data=$(wget2 -q -O - --header 'Accept:text/plain' https://hashbang.sh/server/stats)
	
	while IFS="|" read -r host _ location current_users max_users _; do
		host=$(echo "$host" | cut -d. -f1)
		latency=$(time_cmd "wget2 -q -O /dev/null \"${host}.hashbang.sh\"")
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
	
	hbar
	
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
	wget2 --post-data="{\"user\":\"$user\",\"key\":\"$public_key\",\"host\":\"$host\"}" \
	--header='Content-Type: application/json' https://hashbang.sh/user/create
}

update_key() {
	remote_host=$1
	user=$2
}

create() {
	remote_host=$1
	# if it's empty, ask for it
	
	project_name=
	
	# "remote_host:~/Public/project_name" will be kept in "project_path/.data/codev/remote"
	
	# add the project's website to "~/Public/index.html"
}

delete() {
	remote_host=
	user=
	
	# remove project
	# remove the project's website from "~/Public/index.html"
}

push() {
	remote_host=
	user=
	
	# project owner pushes; others send emails
	# ssh to connect to your server; connect to others using email
	
	# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/mail/main.yml
	
	# post'mail script does push/pull'request, then sends a reply that says it's accepted or not
	# sender waits for reply
	#
	# run script when email is received:
	# procmail can execute custom script for specific email eg based on sender, subject and size
	# https://unix.stackexchange.com/questions/178396/run-script-on-receipt-of-email
	# https://unix.stackexchange.com/questions/76768/creating-an-email-that-can-trigger-a-script
	# https://stackoverflow.com/questions/5709846/run-linux-script-on-received-emails
	# https://serverfault.com/questions/261191/how-to-run-a-script-when-a-mail-arrives-in-mail-server-debian
	#
	# procmail: ~/Mail/new
	# hashbang email (postfix) is secure, because: "smtp_tls_security_level = secure"
	
	# emails are sign by a key corresponding to the destination email
	# keep all emails which you have sent your public key
	# if your (password protected) private keys are compromised, send a revoke and replace request to all
	# the new public key, must be signed by the user’s previous private key
	# this provides a chain from the initial user creation record to current
	# https://www.linuxjournal.com/content/ssh-key-rotation-posix-shell-sunset-nears-elderly-keys
	# https://tailscale.com/blog/rotate-ssh-keys/
	# https://askubuntu.com/questions/1042739/how-to-replace-the-ssh-private-public-key-pair
	
	# , separate keys for each mutual relation
	# , update keys frequently
	# this means that an attacker must, for each individual,
	# record all communications, and break a chain of public keys,
	# because only the first public keys are transfered unencrypted
	
	# i came to these ideas by my own, but later found that they are explored and implemented before:
	# https://en.wikipedia.org/wiki/Double_Ratchet_Algorithm
	# OMEMO, Matrix
	# but since implementing a file sharing system with them seems complicated, i don't use them
	# also i don't completely understand what they do when changing devices
	# if they transmit private keys over the network, they must be avoided
	
	# https://www.agwa.name/blog/post/ssh_signatures
	
	# emails are put on the Public directory, inside a directory with a random name, only known to the receiver
	# the receiver's client reads the directory at first, then wait for Websub notifications
	# https://indieweb.org/WebSub
	# https://en.wikipedia.org/wiki/WebSub
	# https://ably.com/topic/websub
	# https://blog.andrewshell.org/what-is-rsscloud/
	# https://websubhub.com/
	# http://phubb.cweiske.de/
	
	# private emails are encrypted by paired keys
	# to open it at the destination, we need the (password protected) private key
	
	# caertificates from institutions can be signed and transfered between pairs, using email
	
	# if a file named "lock" exists at the remote, and it's younger than 20 seconds, exit
	# if the index file in remote is not the same as ".cache/codev/indexed/index", exit
	# because it means that someone else has already pushed to the remote before you,
	# and you must pull and merge it before pushing
	# snapshot ".cache/codev/remote" into ".cache/codev/temp"
	# flatten the paths of all files in ".cache/codev/temp" using their hashes for the file names
	# if the file's modification time is the same as the one in the index file ".cache/codev/indexed/index",
	# take the hash from the index file, otherwise calculate the hash and add the file to the index file
	# move ".cache/codev/temp" to ".cache/codev/indexed"
	# sync up ".cache/codev/indexed" to the "~/Public" directory of the remote (using SFTP),
	# except the index file, and without deleting any file at the remote
	# https://manpages.debian.org/bullseye/openssh-client/sftp.1.en.html
	# https://man.archlinux.org/listing/openssh
	# create a file named "lock" in the remote
	# if index file in remote is not the same as the one in ".cache/codev/indexed", exit
	# because it means that someone else has already pushed to the remote before you,
	# and you must pull it before pushing
	# send ".cache/codev/indexed/index" to the remote
	# remove the lock file
	# delete those remote files which are not in index file
	# snapshot the ".cache/codev/remote" into ".cache/codev/pristine"
	
	# create an html web'page "~/Public/project_name/index.html", showing the files in the project
	# https://nanoc.app/about/
	# https://github.com/nanoc/nanoc
	# https://docs.antora.org/
	
	# we can keep a directory tree made from the history of specific changes made by pushers,
	# and requests made by pull-requests, a history that shows who has done what
	# it can be used, for example, to track down backdoors introduced in the code
	
	# ".cache" directory will not be synced to remote
}

pull() {
	remote_host=
	user=
	
	# download the index file from the "~/Public" directory of the remote, into ".cache/codev/index"
	# sync down the files mentioned in the index file
	# snapshot ".cache/codev/indexed" to ".cache/codev/temp"
	# delete the index file and ".cache/codev/tmp/.cache/"
	# rename the files in ".cache/codev/temp" based on the index file ".cache/codev/indexed/index"
	# move ".cache/codev/temp" to ".cache/codev/remote"
	# show the diff based on the working directory, pristine and remote
	# merge the remote into the working directory
	# snapshot the working directory into ".cache/codev/remote"
	
	# site's public key is trusted on first download
	# subsequent downloads are checked to be signed by previous keys
	# https: good for trust on first download
	# public key signing: for subsequent downloads
	
	# https://www.gnu.org/software/diffutils/manual/html_mono/diff.html
	# https://stackoverflow.com/questions/16902001/manually-merge-two-files-using-diff
	# file tree diff
	# https://stackoverflow.com/questions/776854/how-do-i-compare-two-source-trees-in-linux
	# https://github.com/dandavison/delta
	# https://github.com/so-fancy/diff-so-fancy
	# https://diffoscope.org/
	# https://github.com/MightyCreak/diffuse
	# http://meldmerge.org/
	# https://git-scm.com/docs/git-diff
}

backup() {
	# for all directories in $1
	# .cache/codev/backup-uuid
	
	# do not follow mount points when making backups
	
	# backup (encrypted) private keys, plus public keys of trusted pairs
}

# add or remove a user that can push
# ; codev add username
# ; codev remove username
user_add() {
	remote_host=
	user=
	username=$1
}
user_del() {
	remote_host=
	user=
	username=$1
}

if [ "$0" != "init" ] && [ "$0" != "pull" ] && [ "$0" != "backup" ] && [ ! -f ~/.config/codev ]; then
	echo 'first run "codev init <remote-host> <user>"'
fi

case "$1" in
	init) init ;;
	create) create ;;
	delete) delete ;;
	clone) clone ;;
	push) push ;;
	pull) pull ;;
	backup) backup ;;
	useradd) user_add ;;
	userdel) remove_user ;;
	*) echo 'usage: codev init/create/delete/push/pull/backup/useradd/userdel' ;;
esac
