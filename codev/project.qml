// if there is a saved session file for the project, restore it

// ".cache/codev/notif-*" files: notifications

/*
class Project {
	pull() {
		// first a three'way diff will be shown, based on the main branch, pristine, and the working directory
		// then the user will be asked to accept all or some parts of the diff
	}
	
	pullRequest() {
		// first publish the pristine and the working directory (except .cache)
		// then send the two addresses to the main developer
		
		// a pull request can be removed by sending a message to the main developer,
		// and unpublishing the two links
	}
	
	pullRequestAnswer(pristineUri, branchUri) {
		// this will be run by the main developer
		// make a diff based on the sent pristine and branch, plus our own working directory	
		
		// pull requests can be kept to trace backdoors found later, back to the origin author
	}
	
	publish(gnNamespace, projectName) {
		// gnPublish
	}
	
	publishPackage() {
		// spm publish
	}
	
	publishWebsite(remoteHost, user) {
		// we still need a website so the unfortunate users of conventional internet can see and find us
		
		hasbang can be used as free web host that allows to signup using http post
		https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.html
		https://github.com/hashbang/shell-server/blob/master/ansible/tasks/packages/main.yml
		create a user in one of "hashbang.sh" servers
		https://github.com/hashbang/hashbang.sh/blob/master/src/hashbang.sh
		
		currently, the ~/Public folder isn't exposed over HTTP by default
		use the `SimpleHTTPServer.service` systemd unit file (in `~/.config/systemd/user`, modify it to set port)
		download ~/.config/systemd/user/SimpleHTTPServer@.service
		rename to SimpleHTTPServer@1025.service and upload to ~/.config/systemd/user/
		https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer%40.service
		https://github.com/hashbang/shell-server/blob/master/ansible/tasks/hashbang/templates/etc/skel/Mail/new/msg.welcome.j2
		
		create an html web'page "~/Public/project_name/index.html", showing the files in the project
		when converting to html, convert tabs to html tables, to have elastic tabstops
		
		hashbang init:
		
		if "remote'host" or "user" are empty, ask for them
		
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
		
		// use ssh-keygen to sign/verify files
		// use gnunet-identity to obtain the Ed25519 key
		// openssh public key format: ed25519 ... user@hostname
		// openssh private key format:
		// -----BEGIN OPENSSH PRIVATE KEY-----
		// base64-encoded data, that may also be encrypted with a passphrase
		// -----END OPENSSH PRIVATE KEY-----
		// https://hstechdocs.helpsystems.com/manuals/globalscape/eft82/mergedprojects/admin/ssh_key_formats.htm
		// https://en.wikipedia.org/wiki/PKCS_8
	}
}
*/

/*
class ProjectView {
	dir: String,
	widget: Overlay, // floating layer can be used to view web'pages, images and videos
	mainView: ListBox,
	files: Files,
	centerView: Stack
	
	new(dirPath) {
		self.dirPath = dirPath;
		self.widget: Overlay = new Overlay();
		let mainBox = new Box(orient: HORIZONTAL);
		widget.setChild(mainBox);
		
		self.files = new Files();
		mainBox.append(files);
		
		self.centerView = new Stack();
		mainBox.append(centerView);
	}
}
*/
