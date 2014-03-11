/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-11
 * Description: 创建子菜单
 * Modify: 2014-02-16 左侧返回功能
 */
var viewHelper = {};
/**
 * createSubMenu
 * @param {Object} window
 * @param {Object} webview
 * @param {Object} opts
 */
viewHelper.createSubMenu = function(window, webview, opts) {
	var config = {
		arrowWidth: 15,
		arrowHeight: 15,
		arrowTop: Math.floor((Ti.App.app_config.submenuHeight - 15) / 2),//(40 - 15) / 2
		arrowIndex: 101,
		arrowLeft: Math.floor((Ti.App.app_config.submenuHeight - 15) / 2),
		arrowRight: 6,
		arrowBgColor: '#ffffff',
		splitWidth: 1,
		splitHeight: Ti.App.app_config.submenuHeight,
		splitTop: 0,
		leftWidth: 10,
		leftBackgroundImage: '/images/back_tag.png',
		rightBackgroundImage: '/images/more_tag.png',
		splitBackgroundImage: '/images/top_line.png',
		opacity: 1,
		scrollBgColor: '#ffffff',//#F8F8FF
		scrollBgIndex: 100,
		scrollBgTop: 0,
		contentWidth: 440,
		arrowContentWidth: Ti.App.app_config.submenuHeight,
		contentHeight: Ti.App.app_config.submenuHeight,
		submenuHeight: 30,
		scrollViewWidth: 260,// 320 arrowWidth
		marginLeft: 10,
		buttonWidth: 60,
		fontSize: 16,
		fontWidth: 18,
		fontColor: '#696969',//#808080
		borderColor: '#ffffff',//DCDCDC
		borderRadius: 15,
		borderWidth: 1,
		activeFontColor: '#a62723',//#A52A2A
		activeBorderColor: '#ffffff',//#C0C0C0
		activeBgColor: '#DBDBDB'//#ffffff
	};
	config.scrollViewWidth = Ti.App.width - config.leftWidth - config.arrowContentWidth;
	this.config = config;
	
	var width = Ti.Platform.displayCaps.platformWidth,
		height = Ti.Platform.displayCaps.platformHeight,
		dpi = Ti.Platform.displayCaps.dpi;
	
	if(height == 568) {
		config.scrollBgTop += 19;
	}
	
	var submenus = opts.menu.submenus;
	
	config.contentWidth = 0;
	for(var i = 0, l = submenus.length ; i < l ; i++) {
		submenuName = submenus[i].showName;
		config.buttonWidth = config.fontWidth * submenuName.length;
		config.contentWidth += config.buttonWidth + config.marginLeft;
	}
	config.contentWidth += 20;
	if(config.contentWidth < 260) {
		config.contentWidth = 260;
	}
	
	var transform_arrow = Ti.UI.create2DMatrix();
	transform_arrow.scale(0.5, 0.5);
	
	//左侧返回按钮
	this.leftBg = Ti.UI.createView({
		contentWidth: config.arrowWidth,
		contentHeight: config.contentHeight,
		top: config.scrollBgTop,
		left: 0,
		height: config.contentHeight,
		width: config.arrowContentWidth,
		backgroundColor: config.arrowBgColor,
		zIndex: config.scrollBgIndex,
		opacity: config.opacity,
		layout: 'horizontal'
	});
	this.leftImage = Ti.UI.createView({
		backgroundImage: config.leftBackgroundImage,
		height: config.arrowHeight,
		width: config.arrowWidth,
		top: config.arrowTop,
		left: config.arrowLeft,
		visible: false,
		zIndex: config.arrowIndex,
		opacity: config.opacity,
		transform: config.transform_arrow
	});
	this.leftSplit = Ti.UI.createView({
		backgroundImage: config.splitBackgroundImage,
		height: config.splitHeight,
		width: config.splitWidth,
		top: config.splitTop,
		left: config.arrowLeft,
		visible: false,
		zIndex: config.arrowIndex,
		opacity: config.opacity
	});
	this.leftBg.add(this.leftImage);
	this.leftBg.add(this.leftSplit);
	window.add(this.leftBg);
	
	//右侧菜单按钮
	var rightBg = Ti.UI.createView({
		contentWidth: config.arrowWidth,
		contentHeight: config.contentHeight,
		top: config.scrollBgTop,
		right: 0,
		height: config.contentHeight,
		width: config.arrowContentWidth,
		backgroundColor: config.arrowBgColor,
		zIndex: config.scrollBgIndex,
		opacity: config.opacity,
		layout: 'horizontal'
	});
	var rightImage = Ti.UI.createView({
		backgroundImage: config.rightBackgroundImage,
		height: config.arrowHeight,
		width: config.arrowWidth,
		top: config.arrowTop,
		left: config.arrowLeft,
		zIndex: config.arrowIndex,
		opacity: config.opacity
	});
	var rightSplit = Ti.UI.createView({
		backgroundImage: config.splitBackgroundImage,
		height: config.splitHeight,
		width: config.splitWidth,
		top: config.splitTop,
		zIndex: config.arrowIndex,
		opacity: config.opacity
	});
	rightBg.add(rightSplit);
	rightBg.add(rightImage);
	window.add(rightBg);
	
	//mask窗口
	var MaskWindow = require('ui/common/MaskWindow');
	var maskWindow = new MaskWindow();
	
	//menu窗口
	var MenuWindow = require('ui/common/MenuWindow');
	var menuWindow = new MenuWindow(opts);
	menuWindow.maskWindow = maskWindow;
	
	maskWindow.addEventListener('click', function(e) {
		menuWindow.close();
	});
	rightBg.addEventListener('click', function(e) {
		menuWindow.open();
	});
	
	/**
	 * scrollView
	 */
	var scrollView = Titanium.UI.createScrollView({
		contentWidth: config.contentWidth,
		contentHeight: config.contentHeight,
		top: config.scrollBgTop,
		height: config.contentHeight,
		width: config.scrollViewWidth,
		//borderRadius: 10,
		backgroundColor: config.scrollBgColor,
		left: config.leftWidth,
		zIndex: config.scrollBgIndex,
		opacity: config.opacity
	});
	this.scrollView = scrollView;
	this.webview = webview;
	
	scrollView.addEventListener('scroll', function(e) {
		/*Ti.API.info('x ' + e.x + ' y ' + e.y);
		
		if(e.x > 10) {
			leftImage.show();
		} else {
			leftImage.hide();
		}
		if(e.x < config.contentWidth - config.scrollViewWidth - 10) {
			rightImage.show();
		} else {
			rightImage.hide();
		}*/
	});
	//this.leftImage.show();
	//this.leftSplit.show();
	rightImage.show();
	rightSplit.show();
	
	window.add(scrollView);
	
	this.backBtn = {};
	this.backBtn.menu = {};
	
	this.showLeftButton = function(menu) {
		that = this;
		this.leftImage.show();
		this.leftSplit.show();
		
		this.scrollView.setLeft(config.arrowContentWidth);
		this.scrollView.setWidth(Ti.App.width - config.arrowContentWidth - config.arrowContentWidth);
		
		this.backBtn.menu = menu;
		
		this.leftBg.addEventListener('click', function(e) {
			webview.isBack = true;
			that.hideLeftButton();
			
			//change webview menu
			var menu = that.backBtn.menu;
			
			//url = menu.url;
			
			webUtil = require('utils/webUtil');
			webUtil.setWebviewAttribute(webview, menu);
			
			webview.goBack();
			//webview.setUrl(url);
		});
	};
	
	this.hideLeftButton = function() {
		this.leftImage.hide();
		this.leftSplit.hide();
		
		this.scrollView.setLeft(config.leftWidth);
		this.scrollView.setWidth(Ti.App.width - config.leftWidth - config.arrowContentWidth);
		
		this.leftBg.removeEventListener('click', function() {
			
		});
	};
	
	this.changeSubmenu = function(submenus) {
		var that = this;
		
		var submenuView = [];
		var submenuLabel = [],
			submenuName = "",
			left = 0,
			url = "",
			submenuBgColor,
			submenuBorderColor,
			submenuFontColor,
			activeTabIndex = 0,
			menu,
			config = this.config,
			webview = this.webview;
		
		this.scrollView.removeAllChildren();
		
		var contentWidth = 0;
		for(var i = 0, l = submenus.length ; i < l ; i++) {
			submenuName = submenus[i].showName;
			config.buttonWidth = config.fontWidth * submenuName.length;
			contentWidth += config.buttonWidth + config.marginLeft;
		}
		contentWidth += 20;
		if(contentWidth < 260) {
			contentWidth = 260;
		}
		this.scrollView.setContentWidth(contentWidth);
		
		var visitInfo = Ti.App.Properties.getObject('Ti.App.visitInfo');
		var bottomTabIndex = visitInfo.activeTabIndex;
		activeTabIndex = visitInfo.activeSubMenu[bottomTabIndex].index;
		
		for(var i = 0, l = submenus.length ; i < l ; i++) {
			submenuName = submenus[i].showName;
			config.buttonWidth = config.fontWidth * submenuName.length;
			if(i == 0) {
				left = config.marginLeft;	
			} else {
				left = submenuView[i - 1].getLeft() + submenuView[i - 1].getWidth() + config.marginLeft;
			}
			if(i == activeTabIndex) {
				submenuBgColor = config.activeBgColor;
				submenuBorderColor = config.activeBorderColor;
				submenuFontColor = config.activeFontColor;
			} else {
				submenuBgColor = config.scrollBgColor;
				submenuBorderColor = config.borderColor;
				submenuFontColor = config.fontColor;
			}
			submenuView.push(Ti.UI.createView({
				backgroundColor: submenuBgColor,
				borderRadius: config.borderRadius,
				borderWidth: config.borderWidth,
				borderColor: submenuBorderColor,
				width: config.buttonWidth,
				height: config.submenuHeight,
				left: left,
				name: submenus[i].name
			}));
			this.scrollView.add(submenuView[i]);
			
			submenuLabel.push(Ti.UI.createLabel({
				text: submenuName,
				font: {fontSize: config.fontSize, fontWeight: 'bold'},
				color: submenuFontColor,
				width: 'auto',
				textAlign: 'center',
				height: 'auto'
			}));
			submenuView[i].add(submenuLabel[i]);
			if(submenus[i].url == "") {
				url = "http://m.shenglong-electric.com.cn/";
			} else {
				url = submenus[i].url;
			}
			
			menu = submenus[i];
			if(i == activeTabIndex) {
				visitInfo.activeMenu[bottomTabIndex] = menu;
			}
			Ti.App.Properties.setObject('Ti.App.visitInfo', visitInfo);
			this.hideLeftButton();
			
			(function(url, i) {
				//submenu click event
				submenuView[i].addEventListener('click', function(e) {
					var visitInfo = Ti.App.Properties.getObject('Ti.App.visitInfo');
					var bottomTabIndex = visitInfo.activeTabIndex;
		
					if(i == activeTabIndex) {
						
					}
					//remove current activeTab
					if(activeTabIndex >= 0) {
						submenuView[activeTabIndex].setBackgroundColor(config.scrollBgColor);
						submenuView[activeTabIndex].setBorderColor(config.borderColor);
						submenuLabel[activeTabIndex].setColor(config.fontColor);
					}
					
					activeTabIndex = i;
					
					submenuView[activeTabIndex].setBackgroundColor(config.activeBgColor);
					submenuView[activeTabIndex].setBorderColor(config.activeBorderColor);
					submenuLabel[activeTabIndex].setColor(config.activeFontColor);
					
					//webview change content
					
					var menu = submenus[i];
					
					visitInfo.activeSubMenu[bottomTabIndex].index = activeTabIndex;
					visitInfo.activeMenu[bottomTabIndex] = menu;
					Ti.App.Properties.setObject('Ti.App.visitInfo', visitInfo);
				
					webview.setHtml('test');
					
					that.hideLeftButton();
				});
			})(url, i);
		}
	};
	
	this.changeSubmenu(submenus);
};
exports.viewHelper = viewHelper;
exports.createSubMenu = viewHelper.createSubMenu;