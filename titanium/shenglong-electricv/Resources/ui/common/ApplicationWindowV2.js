/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: 应用主窗口webview
 */
function ApplicationWindow(opts) {
	var config = {
		top: 30,
		tabHeight: 45
	};
	
	this.window = Ti.UI.createWindow({
		title: opts.title,
		backgroundColor:'white',
		navBarHidden: true
	});
	
	var url = "";
	if(typeof opts.url != "undefined") {
		url = opts.url;
	} else {
		url = opts.menu.url;
	}
	if(url == "") {
		url = "http://m.shenglong-electric.com.cn/";
	}
	
	var logger = require('utils/logger');

	var webview = Ti.UI.createWebView({
		url: url,
		hideLoadIndicator: true,
		top: config.top,
		height: Ti.App.height - config.top - config.tabHeight,
		menu: opts.menu,//menu
		code: opts.menu.code,
		type: opts.menu.type,
		pageId: opts.menu.pageId,
		newsId: opts.menu.newsId,
		parentCode: opts.menu.parentCode,
		sl_cid: opts.menu.sl_cid,
		template_url: opts.menu.url//template
	});
	this.webview = webview;
	
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
		var beginDate = new Date();
		logger.info("---------------getContent start:" + beginDate.getTime());
		content = webUtil.getContent(this);
		var endDate = new Date();
		logger.info("---------------getContent end:" + endDate.getTime() + " use time:" + (endDate.getTime() - beginDate.getTime()));
		
		Ti.App.fireEvent('app:changeContent', {
			type: this.menu.type,
			code: this.menu.code,
			pageId: this.menu.pageId,
			newsId: this.menu.newsId,
			content: content
		});
		
		activityIndicator.hide();
	});
	
	Ti.App.addEventListener('app:visitPage', function(e) {//自定义事件
		var menu = JSON.parse(e.menu);
		
		webview.setUrl(menu.url);
		
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
		webview.timestamp = e.timestamp;
	
		webview.reload();
	});
	
	Ti.App.addEventListener('app:visitNews', function(e) {
		var sl_news_id = e.sl_news_id;
		
		webview.setUrl('/website/news_template.html');
		webview.type = 4;
		webview.sl_news_id = sl_news_id;
		webview.timestamp = e.timestamp;
	
		webview.reload();
	});
	
	Ti.App.addEventListener('app:log', function(e) {
		logger.info('------------------webview:' + e.message);
	});
	
	var viewHelper = require("ui/helper/viewHelper");
	viewHelper.createSubMenu(this.window, webview, opts);
	
	this.window.add(webview);
	this.window.add(activityIndicator);
	
	var welcomebutton = Ti.UI.createButton({
		title: '@'
	});
	
	welcomebutton.addEventListener('click', function() {
		opts.welcomeWindow.open({modal: true});
	});
	
	this.window.rightNavButton = welcomebutton;
};

module.exports = ApplicationWindow;