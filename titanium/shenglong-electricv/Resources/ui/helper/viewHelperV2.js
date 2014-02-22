/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
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
		arrowTop: 12,//(40 - 15) / 2
		arrowIndex: 101,
		arrowLeft: 6,
		arrowRight: 6,
		arrowBgColor: '#ffffff',
		splitWidth: 1,
		splitHeight: 40,
		splitTop: 0,
		leftBackgroundImage: '/images/back_tag.png',
		rightBackgroundImage: '/images/more_tag.png',
		splitBackgroundImage: '/images/top_line.png',
		opacity: 1,
		scrollBgColor: '#ffffff',//#F8F8FF
		scrollBgIndex: 100,
		scrollBgTop: 0,
		contentWidth: 440,
		arrowContentWidth: 40,
		contentHeight: 40,
		submenuHeight: 30,
		scrollViewWidth: 260,// 320 arrowWidth
		marginLeft: 10,
		buttonWidth: 60,
		fontSize: 16,
		fontWidth: 18,
		fontColor: '#808080',
		borderColor: '#DCDCDC',
		activeFontColor: '#A52A2A',
		activeBorderColor: 'C0C0C0',
		activeBgColor: '#fff'
	};
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
	
	var leftBg = Ti.UI.createView({
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
	var leftImage = Ti.UI.createView({
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
	var leftSplit = Ti.UI.createView({
		backgroundImage: config.splitBackgroundImage,
		height: config.splitHeight,
		width: config.splitWidth,
		top: config.splitTop,
		left: config.arrowLeft,
		visible: false,
		zIndex: config.arrowIndex,
		opacity: config.opacity
	});
	leftBg.add(leftImage);
	leftBg.add(leftSplit);
	window.add(leftBg);
	var rightBg = Ti.UI.createView({
		contentWidth: config.arrowWidth,
		contentHeight: config.contentHeight,
		top: config.scrollBgTop,
		right: -10,
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
	
	var MaskWindow = require('ui/common/MaskWindow');
	var maskWindow = new MaskWindow();
	
	var MenuWindow = require('ui/common/MenuWindow');
	var menuWindow = new MenuWindow(opts);
	menuWindow.maskWindow = maskWindow;
	rightBg.addEventListener('click', function(e) {
		var animation = Ti.UI.createAnimation();
		animation.duration = 400;
		animation.bottom = 0;
		maskWindow.open();
		menuWindow.open(animation);
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
	leftImage.show();
	leftSplit.show();
	rightImage.show();
	rightSplit.show();
	
	window.add(scrollView);
	
	var submenuView = [];
	var submenuLabel = [],
		submenuName = "",
		left = 0,
		url = "",
		submenuBgColor,
		submenuBorderColor,
		submenuFontColor,
		activeTabIndex = 0,
		menu;
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
			borderRadius: 10,
			borderWidth: 1,
			borderColor: submenuBorderColor,
			width: config.buttonWidth,
			height: config.submenuHeight,
			left: left,
			name: submenus[i].name
		}));
		scrollView.add(submenuView[i]);
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
		
		(function(url, i) {
			submenuView[i].addEventListener('click', function(e) {
				if(i == activeTabIndex) {
					/*webview.setUrl(url);
					webview.reload();
					return;*/
				}
				if(activeTabIndex >= 0) {
					submenuView[activeTabIndex].setBackgroundColor(config.scrollBgColor);
					submenuView[activeTabIndex].setBorderColor(config.borderColor);
					submenuLabel[activeTabIndex].setColor(config.fontColor);
				}
				activeTabIndex = i;
				submenuView[activeTabIndex].setBackgroundColor(config.activeBgColor);
				submenuView[activeTabIndex].setBorderColor(config.activeBorderColor);
				submenuLabel[activeTabIndex].setColor(config.activeFontColor);
				
				//url = url + "?r=" + new Date().getTime();
				//webview change content
				webview.setUrl(url);
				
				var menu = submenus[i];
				webUtil = require('utils/webUtil');
				webUtil.setWebviewAttribute(webview, menu);
			
				//webview.reload();
			});
		})(url, i);
	}
	
	this.changeSubmenu = function(submenus) {
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
				borderRadius: 10,
				borderWidth: 1,
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
			
			(function(url, i) {
				submenuView[i].addEventListener('click', function(e) {
					if(i == activeTabIndex) {
						/*webview.setUrl(url);
						webview.reload();
						return;*/
					}
					if(activeTabIndex >= 0) {
						submenuView[activeTabIndex].setBackgroundColor(config.scrollBgColor);
						submenuView[activeTabIndex].setBorderColor(config.borderColor);
						submenuLabel[activeTabIndex].setColor(config.fontColor);
					}
					activeTabIndex = i;
					submenuView[activeTabIndex].setBackgroundColor(config.activeBgColor);
					submenuView[activeTabIndex].setBorderColor(config.activeBorderColor);
					submenuLabel[activeTabIndex].setColor(config.activeFontColor);
					
					//url = url + "?r=" + new Date().getTime();
					//webview change content
					webview.setUrl(url);
					
					var menu = submenus[i];
					webUtil = require('utils/webUtil');
					webUtil.setWebviewAttribute(webview, menu);
				
					//webview.reload();
				});
			})(url, i);
		}
	};
};
exports.viewHelper = viewHelper;
exports.createSubMenu = viewHelper.createSubMenu;