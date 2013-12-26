function ApplicationWindow(title, url) {
	var self = Ti.UI.createWindow({
		title:title,
		backgroundColor:'white'
	});

	var webview = Ti.UI.createWebView({
		url: url
	});

	self.add(webview);

	return self;
};

module.exports = ApplicationWindow;