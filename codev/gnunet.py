# https://docs.gnunet.org/
# https://grothoff.org/christian/habil.pdf
# https://www.gnunet.org/en/use.html
# https://clehaxze.tw/gemlog/2022/08-10-gnunet-file-sharing-tutorial-and-an-alternative-to-ipfs.gmi
# https://wiki.archlinux.org/title/GNUnet
# https://manpages.debian.org/unstable/gnunet/
# https://git.gnunet.org/gnunet.git/tree/

# a gnunet peer (instance) for each project group
# ".codev" file in a project group directory:
# , associated ego for publishing
# , level of anonymity

# backup: projects, gnunet keys, lsh keys

# https://diffoscope.org/
# https://www.gnu.org/software/diffutils/manual/html_node/index.html

# GNUnet: audio conversasion is already implemented
# figure out how to send/receive streams to/from gnunet
# https://git.gnunet.org/gnunet.git/tree/src/contrib/service/conversation
# https://jami.net/
# https://packages.debian.org/bookworm/jami-daemon

class Gnunet
	def publish():
		# create ref links of the project files, in ".cache/gnunet/publish"
		# this way GNUnet can publish the files using the indexed method
		# note that projects reside in non'removable BTRFS'formated disks
		
	def unpublish():
	
	def download():
	
	def pull():
	
	def pull_request():

	def publish_website(remote_host :String, user :String):
		# we still need a website so the unfortunate users of conventional internet can see and find us
		
		# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
		# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml
		# create a user in one of "hashbang.sh" servers
		# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
		
		# currently, the ~/Public folder isn't exposed over HTTP by default
		# use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
		# download ~/.config/systemd/user/SimpleHTTPServer@.service
		# rename to SimpleHTTPServer@1025.service and upload to ~/.config/systemd/user/
		# https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
		# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/hashbang/templates/etc/skel/Mail/new/msg.welcome.j2
		
		# no need for an ssh client (like lsh), just use curl sftp upload
		
		# create an html web'page "~/Public/project_name/index.html", showing the files in the project
		# https://nanoc.app/about/
		# https://github.com/nanoc/nanoc
		# https://docs.antora.org/
		# when converting to html, convert tabs to html tables, to have elastic tabstops
		
		# alternaties to hashbang.sh:
		# http://m-net.arbornet.org/index.php
		# https://freeshell.de/
		# https://envs.net/
		# https://tilde.club/
		# https://ninthfloor.org/
		# copy the public key to the server:
		# https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
		# or we can use a Docker container on top of cloud services:
		# https://hub.docker.com/
		# https://cloud.google.com/run
		# https://render.com/docs/docker
		# https://fly.io/
		# https://www.ibm.com/cloud/free/
		
		# hashbang init:
		
		# if "remote_host" or "user" are empty, ask for them
		
		# printf "\nHost %s\n  User %s\n" "$remote_host" "$user" >> ~/.ssh/config
		# 
		# { echo "$user" | sed -n "/^[a-z][a-z0-9]{0,30}$/!{q1}"; } || {
		# 	echo "\"$user\" is not a valid username"
		# 	echo "a valid username must:"
		# 	echo ", be between between 1 and 31 characters long"
		# 	echo ", consist of only 0-9 and a-z (lowercase only)"
		# 	echo ", begin with a letter"
		# 	exit 1
		# }
		# 
		# ssh "$user"@"$remote_host" && return
		# 
		# # if there is no SSH keys, create a key pair
		# # ssh-keygen -t ed25519
		# # openssh key format: ssh-ed25519 ...
		# 
		# echo
		# echo " please choose a server to create your account on"
		# echo
		# hbar
		# printf -- '  %-1s | %-4s | %-36s | %-8s | %-8s\n' \
		# 	"#" "Host" "Location" "Users" "Latency"
		# hbar
		# 
		# host_data=$(wget -q -O - --header 'Accept:text/plain' https://hashbang.sh/server/stats)
		# 
		# while IFS="|" read -r host _ location current_users max_users _; do
		# 	host=$(echo "$host" | cut -d. -f1)
		# 	latency=$(time_cmd "wget -q -O /dev/null \"${host}.hashbang.sh\"")
		# 	n=$((n+1))
		# 	printf -- '  %-1s | %-4s | %-36s | %8s | %-8s\n' \
		# 		"$n" \
		# 		"$host" \
		# 		"$location" \
		# 		"$current_users/$max_users" \
		# 		"$latency"
		# done <<-INPUT
		# "$host_data"
		# INPUT
		# 
		# echo
		# while true; do
		# 	printf ' Enter Number 1-%i : ' "$n"
		# 	read -r choice
		# 	case "$choice" in
		# 		''|*[!0-9]*) number="no";;
		# 	esac
		# 	if [ "$number" != "no" ] && [ "$choice" -ge 1 ] && [ "$choice" -le $n ]; then
		# 		break;
		# 	fi
		# done
		# 
		# host=$(echo "$host_data" | head -n "$choice" - | tail -n1 | cut -d \| -f1)
		# 
		# pulic_key=$(cat ~/.ssh/id_ed25519.pub)
		# host=de1.hashbang.sh
		# wget --post-data="{\"user\":\"$user\",\"key\":\"$public_key\",\"host\":\"$host\"}" \
		# --header='Content-Type: application/json' https://hashbang.sh/user/create
