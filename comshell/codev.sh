# https://www.gnunet.org/en/
# https://www.gnunet.org/en/use.html
# https://docs.gnunet.org/

# gnunet-publish
# projects reside in non-removable BTRFS'formated disks
# when we want to publish a project, first we create a ref links of the project files, in ".cache/codev/publish"
# this way gnunet can publish the files using indexed method

# ".cache" directory will not be published

# each transaction contains the hash address of previous transaction of the user,
# plus the hash address of the last (at that moment) transaction of the other user

# the nonesense called blockchain:
# blockchain is not capable to replace current monetary system by design
# it's purpose is to create a side system for criminal activity
# an always growing database
# the whole blockchain (hundreds of gigabytes) must be downloaded for each full node
# full nodes are necessary if you want private and trustless transactions (otherwise why bother with blockchains)
# slow transactions (10 to 30 minutes)
# when the system is completely isolated from external world, and there is no IO point,
# how can we transfer current money and assets to this system
# if we really want to replace current monetary system, this is what we have to do
#
# Oxen instant tranactions on top of the blockchain is not a real solution (makes it less secure)
# it uses PoS instead of PoW, thus transactions can be cheap
# https://en.wikipedia.org/wiki/Proof_of_stake#Attacks
# https://tokens-economy.gitbook.io/consensus/chain-based-proof-of-stake/proof-of-stake-pos
#
# DAG based solutions (Hashgraph ...):
# old transactions can be deleted
# fast and cheap transactions
# but they need to be permissioned, otherwise they will be vulnarable to Sybil attacks in low transaction rates
# https://en.wikipedia.org/wiki/Consensus_(computer_science)#Permissioned_versus_permissionless_consensus
# https://en.wikipedia.org/wiki/Consensus_(computer_science)#[Permissionless_consensus_protocols]
#
# MaidSafe Safe Network:
# why bother when we have Gnunet
# moreover, its complicated group consensus mechanism is useless, we don't need any kind of consensus
# https://primer.safenetwork.org/
#
# Nano: at first it seems that it's going in the right direction by using block lattices
# where every account has its own blockchain
# but then it suprisingly reveals that there is a global big blockchain which must be downloaded by full nodes
# and consequetly there is a consensus mechanism using "open representative voting" instead of PoW
# the security of this simple consensus mechanism is due to the structure of its database,
# where each transaction are signed by both sender and receiver
# these choices make the transactions very fast
# maybe this tendency for global blockchains is to have an isolated token based system, and avoid IO nodes
# https://docs.nano.org/integration-guides/
# https://docs.nano.org/living-whitepaper/
#
# there must be some special nodes to import external money and assets

# ".cache/codev/destination": the latest
# ".cache/codev/pristine": the original files which where reflinked into the project directory
# diff will be based on the working directory, pristine and publish

# pull requests contain 2 index files: changed and pristine

# branches: multiple index files

# we can keep a directory tree (under ".meta" directory) of the history of specific changes made by pushers,
# and requests made by pull-requests, a history that shows who has done what
# it can be used, for example, to track down backdoors introduced in the code

# remove a project

# opensc/opencryptoki/coolkey/softhsm: smartcard device to protect the private key

# https://manpages.debian.org/unstable/gnunet/gnunet-conversation.1.en.html

# we still need a website so the unfortunate users of conventional internet can see and find us
# on a linux server use gnunet to download projects, and host a website
# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
# https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml
# create a user in one of "hashbang.sh" servers
# https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
# currently, the ~/Public folder isn't exposed over HTTP by default
# use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
# https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
#
# create an html web'page "~/Public/project_name/index.html", showing the files in the project
# https://nanoc.app/about/
# https://github.com/nanoc/nanoc
# https://docs.antora.org/
# when converting to html, convert tabs to html tables, to have elastic tabstops
#
# http://m-net.arbornet.org/index.php
# https://freeshell.de/
# https://envs.net/
# https://tilde.club/
# https://ninthfloor.org/
# copy the public key to the server:
# https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
#
# or we can use Alpine Docker containers on top of cloud services:
# https://hub.docker.com/_/alpine
# https://cloud.google.com/run
# https://render.com/docs/docker
# https://fly.io/
# https://www.ibm.com/cloud/free/

create_website() {
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


pull() {
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

case "$1" in
	init) init ;;
	publish) publish ;;
	unpublish) unpublish ;;
	clone) clone ;;
	push) push ;;
	pull) pull ;;
	*) echo 'usage: codev init/publish/unpublish/clone/push/pull' ;;
esac
