/*
if a directory is given: show its content
if a list of strings is given: show list view with them as root
	for directories show their content under them
	for devices, when they are selected, mount them and show their content underneath
*/

/*
new file in empty directory:
	, text
	, draw
	, picture from scanner
		https://wiki.archlinux.org/title/SANE
		https://github.com/alexpevzner/sane-airscan
	, picture from camera
	, video from camera
	, audio from mic
the last four are also available for inserting into text
*/

// action run when an item is activated

// archives: use libarchive to unarchive/archive

// in the left panel show the storage devices, and the projects group directories inside them
// list of storage devices is obtained using "sd"

// ask the user if she wants to format the device, if:
// , it's not formatted
// , it's a removable storage device whose format is not vfat/exfat/btrfs
// , it's an internal storage device whose format is not btrfs

// device actions: mount, unmount, format
// use "sd" program to mount the device (if it's not mounted)
// removable storages should have a little light on them, showing if they are in use or not

// projects on VFAT/exFAT formated devices, or remote devices, will be opened as read'only
// when you try to edit them, you will be asked to copy them into a local device

// when copying from a BTRFS to another BTRFS device, try to send instead of copying

// DirList
// new(rootDirs: [String])
// moveUp
// moveDown
// gotoFile
// findFile
