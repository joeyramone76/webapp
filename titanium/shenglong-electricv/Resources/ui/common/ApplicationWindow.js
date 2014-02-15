/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 应用主窗口webview
 */
function ApplicationWindow(opts) {
	var config = {
		top: 30,
		tabHeight: 45
	};
	
	var self = Ti.UI.createWindow({
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

	var webview;
	if(opts.menu.code == '001') {// first time to open app
		webview = Ti.UI.createWebView({
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
	} else {
		webview = Ti.UI.createWebView({
			hideLoadIndicator: true,
			top: 40,
			menu: opts.menu,//menu
			code: opts.menu.code,
			type: opts.menu.type,
			pageId: opts.menu.pageId,
			newsId: opts.menu.newsId,
			parentCode: opts.menu.parentCode,
			sl_cid: opts.menu.sl_cid,
			template_url: opts.menu.url//template
		});
	}
	
	
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
		if(menu.code == webview.code) {
			return;
		}
		if(e.timestamp == webview.timestamp) {
			return;
		}
		if(e.sl_news_id) {
			return;
		}
		if(webview.code.indexOf(menu.code.substr(0, 3)) != 0) {
			return;
		}
		
		webview.setUrl(menu.url);
		
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
		webview.timestamp = e.timestamp;
	
		webview.reload();
	});
	
	Ti.App.addEventListener('app:visitNews', function(e) {
		var sl_news_id = e.sl_news_id;
		if(e.timestamp == webview.timestamp) {
			return;
		}
		if(e.menu) {
			return;
		}
		if(webview.code.indexOf("002") != 0) {
			return;
		}
		
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