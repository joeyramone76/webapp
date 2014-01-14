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
		type: opts.menu.type,
		pageId: opts.menu.pageId,
		newsId: opts.menu.newsId,
		parentCode: opts.menu.parentCode,
		sl_cid: opts.menu.sl_cid,
		template_url: opts.menu.url//template
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
		//change content
		url = this.url;
		
		webUtil = require('utils/webUtil');
		content = webUtil.getContent(this);
		
		Ti.App.fireEvent('app:changeContent', {
			type: this.menu.type,
			pageId: this.menu.pageId,
			newsId: this.menu.newsId,
			content: content
		});
		
		activityIndicator.hide();
	});
	
	Ti.App.addEventListener('app:visitPage', function(e) {
		var menu = JSON.parse(e.menu);
		
		webview.setUrl(menu.url);
		
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
	
		webview.reload();
	});
	Ti.App.addEventListener('app:visitNews', function(e) {
		var sl_news_id = e.sl_news_id;
		
		webview.setUrl('/website/news_template.html');
		webview.type = 4;
		webview.sl_news_id = sl_news_id;
	
		webview.reload();
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