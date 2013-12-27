function ApplicationWindow(title, url) {
	var self = Ti.UI.createWindow({
		title:title,
		backgroundColor:'white'
	});

	var webview = Ti.UI.createWebView({
		url: url
	});
	
	var viewHelper = require("ui/helper/viewHelper");
	viewHelper.createSubMenu(self);
	
	self.add(webview);

	return self;
};

module.exports = ApplicationWindow;