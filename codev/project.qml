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
		
		// https://gitea.com/user/sign_up
		// 	https://docs.gitea.com/development/api-usage
		// 	https://docs.gitea.com/api/#tag/repository/operation/GetTree
		// 	https://docs.gitea.com/api/#tag/repository/operation/repoGetContents
		// https://codeberg.org/
		
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
