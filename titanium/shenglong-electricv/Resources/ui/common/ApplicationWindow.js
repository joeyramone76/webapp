function ApplicationWindow(opts) {
	var self = Ti.UI.createWindow({
		title: opts.title,
		backgroundColor:'white'
	});

	var webview = Ti.UI.createWebView({
		url: opts.url
	});
	
	var viewHelper = require("ui/helper/viewHelper");
	viewHelper.createSubMenu(self, opts);
	
	self.add(webview);

	return self;
};

module.exports = ApplicationWindow;