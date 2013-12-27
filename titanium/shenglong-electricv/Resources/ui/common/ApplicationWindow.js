function ApplicationWindow(opts) {
	var self = Ti.UI.createWindow({
		title: opts.title,
		backgroundColor:'white'
	});
	
	var url = opts.menu.url;
	if(url == "") {
		url = "http://m.shenglong-electric.com.cn/";
	}

	var webview = Ti.UI.createWebView({
		url: url
	});
	
	var viewHelper = require("ui/helper/viewHelper");
	viewHelper.createSubMenu(self, webview, opts);
	
	self.add(webview);

	return self;
};

module.exports = ApplicationWindow;