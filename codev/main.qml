// https://api.kde.org/mauikit/index.html

// https://doc.qt.io/qt-6/qtremoteobjects-index.html

// start in lock mode
// lock after 10m idle, if lock inhibit is not active
// before lock, show a 10s countdown screen

// lock mode: read'only view, comminicate with emergency accounts

/*
30s idle after lock, poweroff screen
in modern systems, other hardwares (cpu, network ...) are automatically put into low consumption (high latency) mode,
	unless an application specifically request for low latency using Linux PM QoS
	https://docs.kernel.org/power/pm_qos_interface.html
*/

// in Linux, run in a mount namespace
// this way, by default, mounts (including securefs ones) are only visible to codev

// use lines on borders of scrolled QtQuick widgets to show the amount of overflowed content

// gnunet-arm -s -i fs

// create an app with appId "codev"
app.onActivate(function(app) {
	switch (app.getWindows()[0]) {
		nil =>
			projectViews = new Stack();
			
			overview = Overview(projectViews);
			
			rootView = new Overlay();
			rootView.add(projectViews);
			rootView.addOverlay(overview);
			// keybinding to show the overview
			
			window = new ApplicationWindow({
				application: app,
				maximized: true,
				titlebar: nil
			});
			window.setChild(rootView)
			
			// set keybinding to show the overview
		
		win => win.present()
	}
})
