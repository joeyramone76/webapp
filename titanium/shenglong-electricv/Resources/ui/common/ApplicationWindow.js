function ApplicationWindow(title, webview) {
	var self = Ti.UI.createWindow({
		title:title,
		backgroundColor:'white'
	});

	self.add(webview);

	return self;
};

module.exports = ApplicationWindow;