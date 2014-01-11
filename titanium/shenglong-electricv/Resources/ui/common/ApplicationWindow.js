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
		top: 40,
		menu: opts.menu,
		code: opts.menu.code,
		type: opts.type,
		pageId: opts.menu.pageId,
		newsId: opts.menu.newsId,
		parentCode: opts.menu.parentCode,
		sl_cid: opts.menu.sl_cid,
		url: opts.menu.url//template
	});
	
	/**
	 * 正在加载提示
	 */
	var ActivityIndicator = require("ui/common/ActivityIndicator");
	var activityIndicator = new ActivityIndicator();
	
	/**
	 * beforeload
	 */
	webview.addEventListener('beforeload', function(e) {
		activityIndicator.show();
	});
	
	/**
	 * error
	 */
	webview.addEventListener('error', function(e) {
		activityIndicator.hide();
	});
	
	/**
	 * load
	 */
	webview.addEventListener('load', function(e) {
		activityIndicator.hide();
		//change content
		url = this.url;
		
		webUtil = require('utils/webUtil');
		webUtil.getContent(this);
		
		Ti.App.fireEvent('app:changeContent', {
			pageId: this.menu.pageId
		});
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