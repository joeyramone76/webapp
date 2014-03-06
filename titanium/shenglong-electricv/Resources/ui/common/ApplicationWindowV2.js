/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: 应用主窗口webview，创建webview，添加监听事件，loading加载提示
 * 		创建tableView以实现pull to refresh的功能
 */
function ApplicationWindow(opts) {
	var config = {
		top: Ti.App.app_config.submenuHeight,
		tabHeight: Ti.App.app_config.tabHeight
	};
	
	var width = Ti.Platform.displayCaps.platformWidth,
		height = Ti.Platform.displayCaps.platformHeight,
		dpi = Ti.Platform.displayCaps.dpi,
		webviewHeight = 0;
	
	if(height == 568) {
		config.top += 19;
	}
	webviewHeight = Ti.App.height - config.top - config.tabHeight;
	if(height == 480) {
		webviewHeight -= 19;
	}
	
	var that = this;
	
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
	
	url = url + "?r=" + new Date().getTime();

	var webview = Ti.UI.createWebView({
		url: url,
		hideLoadIndicator: true,
		top: 0,
		height: webviewHeight,
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
	var LoadView = require("ui/common/view/LoadView");
	var loadView = new LoadView({
		top: config.top,
		height: webviewHeight
	});
	var ActivityIndicator = require("ui/common/ActivityIndicator");
	var activityIndicator = new ActivityIndicator();
	
	/**
	 * beforeload
	 */
	webview.addEventListener('beforeload', function(e) {
		logger.info("beforeload");
	});
	
	/**
	 * error
	 */
	webview.addEventListener('error', function(e) {
		activityIndicator.hide();
	});
	
	/**
	 * load
	 * this表示webview
	 */
	webview.addEventListener('load', function(e) {
		if(this.isBack) {
			this.isBack = false;
		}
		if(this.template_url.indexOf("http") == 0) {
			return;
		}
		//change content
		loadView.show();
		activityIndicator.show();
		
		webUtil = require('utils/webUtil');
		var beginDate = new Date();
		logger.info("---------------getContent start:" + beginDate.getTime());
		content = webUtil.getContent(this);
		logger.info(content);
		var endDate = new Date();
		logger.info("---------------getContent end:" + endDate.getTime() + " use time:" + (endDate.getTime() - beginDate.getTime()));
		
		var date = new Date();
		Ti.App.fireEvent('app:changeContent', {
			time: date.getTime(),
			type: this.menu.type,
			code: this.menu.code,
			pageId: this.menu.pageId,
			newsId: this.menu.newsId,
			content: content.content,
			parentMenu: content.menu
		});
		
		logger.info("load");
		//after render then hide
		//activityIndicator.hide();
		//loadView.hide();
	});
	
	/**
	 * webview pull to refresh
	 */
	var webviewSection = Ti.UI.createTableViewSection({
		
	});
	var webviewRow = Ti.UI.createTableViewRow({
		height: 'auto',
		layout: 'vertical'
	});
	webviewRow.add(webview);
	webviewSection.add(webviewRow);
	var tableView = Ti.UI.createTableView({
		top: config.top,
		data: [webviewSection]
	});
	
	var border = Ti.UI.createView({
		backgroundColor: "#576c89",
		height: 2,
		bottom: 0
	});
	var tableHeader = Ti.UI.createView({
		backgroundColor: "#e2e7ed",
		width: 320,
		height: 60
	});
	//bottom border 2 pixel
	tableHeader.add(border);
	
	var arrow = Ti.UI.createView({
		backgroundImage: "/images/whiteArrow.png",
		width: 23,
		height: 60,
		bottom: 10,
		left: 20
	});
	var statusLabel = Ti.UI.createLabel({
		text: "下拉刷新页面",
		left: 55,
		width: 200,
		bottom: 30,
		height: "auto",
		color: "#576c89",
		textAlign: "center",
		font: {fontSize:13,fontWeight:"bold"},
		shadowColor: "#999",
		shadowOffset: {x:0,y:1}
	});
	
	var companyNameLabel = Ti.UI.createLabel({
		text: "盛隆电气",
		left: 55,
		width: 200,
		bottom: 15,
		height: "auto",
		color: "#576c89",
		textAlign: "center",
		font: {fontSize: 12},
		shadowColor: "#999",
		shadowOffset: {x:0,y:1}
	});
	
	var actInd = Ti.UI.createActivityIndicator({
		left: 20,
		bottom: 13,
		width: 30,
		height: 30
	});
	tableHeader.add(arrow);
	tableHeader.add(statusLabel);
	tableHeader.add(companyNameLabel);
	tableHeader.add(actInd);
	
	tableView.headerPullView = tableHeader;
	var pulling = false;
	var reloading = false;
	
	function beginReloading() {
		// just mock out the reload
		setTimeout(endReloading, 2000);
	}
	
	function endReloading() {
		// simulate loading
		tableView.setContentInsets({top: 0}, {animated: true});
		reloading = false;
		statusLabel.text = "下拉刷新页面";
		actInd.hide();
		arrow.show();
	}
	
	tableView.addEventListener('scroll', function(e) {
		var offset = e.contentOffset.y;
		if(offset <= -65.0 && !pulling && !reloading) {
			var t = Ti.UI.create2DMatrix();
			t = t.rotate(-180);
			pulling = true;
			arrow.animate({transform: t, duration: 180});
			statusLabel.text = "释放即可刷新";
		}
	});
	
	var event_dragEnd = "dragEnd";
	if(Ti.version >= '3.0.0') {
		event_dragEnd = "dragend";
	}
	tableView.addEventListener(event_dragEnd, function(e) {
		if(pulling && !reloading) {
			reloading = true;
			pulling = false;
			arrow.hide();
			actInd.show();
			
			statusLabel.text = "努力加载中...";
			tableView.setContentInsets({top: 60}, {animated: true});
			arrow.transform = Ti.UI.create2DMatrix();
			beginReloading();
		}
	});
	
	/**
	 * 自定义事件
	 * 由三级菜单进入页面，显示返回按钮
	 */
	Ti.App.addEventListener('app:visitPage', function(e) {
		//显示返回按钮
		that.submenu.showLeftButton(JSON.parse(e.parentMenu));
		
		var menu = JSON.parse(e.menu);
		
		//url = menu.url + "?r=" + new Date().getTime();
		url = menu.url;
		
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
		webview.timestamp = e.timestamp;
	
		//webview.reload();
		webview.setUrl(url);
	});
	
	Ti.App.addEventListener('app:visitNews', function(e) {
		//显示返回按钮
		that.submenu.showLeftButton(JSON.parse(e.parentMenu));
		
		var sl_news_id = e.sl_news_id;
		
		url = '/website/news_template.html' + "?r=" + new Date().getTime();
		url = '/website/news_template.html';
		
		webview.type = 4;
		webview.sl_news_id = sl_news_id;
		webview.timestamp = e.timestamp;
	
		//webview.reload();
		webview.setUrl(url);
	});
	
	Ti.App.addEventListener('app:hideLoading', function(e) {
		logger.info("app:hideLoading");
		activityIndicator.hide();
		loadView.hide();
	});
	
	Ti.App.addEventListener('app:log', function(e) {
		logger.info('------------------webview:' + e.message);
	});
	
	/**
	 * 构建子菜单
	 */
	var viewHelper = require("ui/helper/viewHelperV2");
	this.submenu = new viewHelper.createSubMenu(this.window, webview, opts);
	
	this.submenu.leftImage.addEventListener('click', function(e) {
		webview.isBack = true;
		that.submenu.hideLeftButton();
		
		//change webview menu
		var menu = that.submenu.backBtn.menu;
		
		//url = menu.url;
		
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
		
		webview.goBack();
		//webview.setUrl(url);
	});
	
	this.window.add(tableView);
	this.window.add(loadView.loadView);
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