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
		url: url,
		hideLoadIndicator: true,
		top: 40
	});
	
	var ActivityIndicator = require("ui/common/ActivityIndicator");
	var activityIndicator = new ActivityIndicator();
	
	webview.addEventListener('beforeload', function(e) {
		activityIndicator.show();
	});
	
	webview.addEventListener('error', function(e) {
		activityIndicator.hide();
	});
	
	webview.addEventListener('load', function(e) {
		activityIndicator.hide();
	});
	
	var viewHelper = require("ui/helper/viewHelper");
	viewHelper.createSubMenu(self, webview, opts);
	
	self.add(webview);
	self.add(activityIndicator);
	
	var welcomebutton = Ti.UI.createButton({
		title: '@'
	});
	welcomebutton.addEventListener('click', function() {
		opts.welcomeWindow.open({modal: true});
	});
	self.rightNavButton = welcomebutton;

	return self;
};

module.exports = ApplicationWindow;