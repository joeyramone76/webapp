/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 弹出菜单，从下到上弹出
 */
function MenuWindow(opts) {
	var self = this;
	var isMobileWeb = Ti.Platform.osname === 'mobileweb',
		isTizen = Ti.Platform.osname === 'tizen',
		isIOS = (Ti.Platform.osname == 'iphone' || Ti.Platform.osname == 'ipad');
		
	var width = Ti.Platform.displayCaps.platformWidth,
		height = Ti.Platform.displayCaps.platformHeight,
		dpi = Ti.Platform.displayCaps.dpi;
	
	var config = {
		windowHeight: 640,
		usedWidth: 640,
		usedHeight: 1136,
		
		backgroundColor: '#DDDDDD',
		
		buttonBackgroundColor: '#ffffff',//#F1F1F1
		buttonBorderWidth: 1,
		buttonBorderColor: '#B5B5B5',
		buttonWidth: 511,
		buttonHeight: 148,
		buttonTop: 92,
		buttonMargin: 48,
		titleColor: '#363636',
		subTitleColor: '#5C5C5C',
		buttonImageLeft: 61,
		buttonImageTop: 28,
		buttonImageWidth: 102,
		buttonImageHeight: 92,
		buttonTitleLeft: 207,
		buttonTitleTop: 28,
		buttonSubTitleLeft: 207,
		buttonSubTitleTop: 82,
		
		cancelButtonBackgroundColor: '#D4D4D4',
		cancelButtonBorderWidth: 1,
		cancelButtonBorderColor: '#BFBFBF',
		cancelButtonColor: '#123787',
		cancelButtonTop: 540,
		cancelButtonHeight: 100,
		cancelButtonBottom: 0
	};
	
	config.windowHeight = config.windowHeight / 2;
	
	config.buttonWidth = Math.ceil(config.buttonWidth / 2);
	config.buttonHeight = Math.ceil(config.buttonHeight / 2);
	config.buttonImageWidth = Math.ceil(config.buttonImageWidth / 2);
	config.buttonImageHeight = Math.ceil(config.buttonImageHeight / 2);
	config.buttonTop = config.buttonTop / 2;
	config.buttonMargin = config.buttonMargin / 2;
	config.buttonImageLeft = Math.ceil(config.buttonImageLeft / 2);
	config.buttonImageTop = Math.ceil(config.buttonImageTop / 2);
	config.buttonTitleLeft = Math.ceil(config.buttonTitleLeft / 2);
	config.buttonTitleTop = Math.ceil(config.buttonTitleTop / 2);
	config.buttonSubTitleLeft = Math.ceil(config.buttonSubTitleLeft / 2);
	config.buttonSubTitleTop = Math.ceil(config.buttonSubTitleTop / 2);
	
	config.cancelButtonTop = config.cancelButtonTop / 2;
	config.cancelButtonHeight = Math.ceil(config.cancelButtonHeight / 2);
	
	var menuWindow = Ti.UI.createWindow({
		backgroundColor: config.backgroundColor,
		//layout: 'vertical',
		width: Ti.UI.Fill,
		height: config.windowHeight,
		bottom: -200,
		zIndex: 1001
	});
	
	var weatherButton = Ti.UI.createView({
		borderWidth: config.buttonBorderWidth,
		borderColor: config.buttonBorderColor,
		backgroundColor: config.buttonBackgroundColor,
		width: config.buttonWidth,
		height: config.buttonHeight,
		top: config.buttonTop
	});
	var transform_image = Ti.UI.create2DMatrix();
	transform_image.scale(0.5, 0.5);
	var weatherImage = Ti.UI.createView({
		backgroundImage: '/images/weather.png',
		left: config.buttonImageLeft,
		top: config.buttonImageTop,
		width: config.buttonImageWidth,
		height: config.buttonImageHeight,
		transform: transform_image
	});
	weatherButton.add(weatherImage);
	var weatherTitle = Ti.UI.createLabel({
		text: '天气',
		color: config.titleColor,
		font: {fontSize: 20,fontWeight:'bold'},
		left: config.buttonTitleLeft,
		top: config.buttonTitleTop
	});
	weatherButton.add(weatherTitle);
	var weatherSubTitle = Ti.UI.createLabel({
		text: '今天天气如何？',
		color: config.subTitleColor,
		font: {fontSize: 16},
		left: config.buttonSubTitleLeft,
		top: config.buttonSubTitleTop
	});
	weatherButton.add(weatherSubTitle);
	menuWindow.add(weatherButton);
	
	var mapButton = Ti.UI.createView({
		borderWidth: config.buttonBorderWidth,
		borderColor: config.buttonBorderColor,
		backgroundColor: config.buttonBackgroundColor,
		width: config.buttonWidth,
		height: config.buttonHeight,
		top: config.buttonTop + config.buttonHeight + config.buttonMargin
	});
	var mapImage = Ti.UI.createView({
		backgroundImage: '/images/map.png',
		left: config.buttonImageLeft + 8,
		top: config.buttonImageTop,
		width: config.buttonImageWidth - 16,
		height: config.buttonImageHeight,
		transform: transform_image
	});
	mapButton.add(mapImage);
	var mapTitle = Ti.UI.createLabel({
		text: '地图',
		color: config.titleColor,
		font: {fontSize: 20,fontWeight:'bold'},
		left: config.buttonTitleLeft,
		top: config.buttonTitleTop
	});
	mapButton.add(mapTitle);
	var mapSubTitle = Ti.UI.createLabel({
		text: '如何到达盛隆？',
		color: config.subTitleColor,
		font: {fontSize: 16},
		left: config.buttonSubTitleLeft,
		top: config.buttonSubTitleTop
	});
	mapButton.add(mapSubTitle);
	menuWindow.add(mapButton);
	
	weatherButton.addEventListener('click', function() {
		opts.welcomeWindow.menuWindow = menuWindow;
		opts.welcomeWindow.open({modal: true});
	});
	
	var cancelButton = Ti.UI.createButton({
		title: '取   消',
		borderWidth: config.cancelButtonBorderWidth,
		borderColor: config.cancelButtonBorderColor,
		color: config.cancelButtonColor,
		width: Ti.UI.FILL,
		height: config.cancelButtonHeight,
		bottom: config.cancelButtonBottom,
		backgroundColor: config.cancelButtonBackgroundColor
	});
	isTizen || (cancelButton.style = Ti.UI.iPhone.SystemButtonStyle.PLAIN);
	
	menuWindow.add(cancelButton);
	
	cancelButton.addEventListener('click', function() {
		var animation = Ti.UI.createAnimation();
		animation.duration = 400;
		animation.bottom = -200;
		menuWindow.close(animation);
	});
	
	this.maskWindow = null;
	/*menuWindow.addEventListener('open', function(e) {
		var MaskWindow = require('ui/common/MaskWindow');
		var maskWindow = new MaskWindow();
		this.maskWindow = maskWindow;
		this.maskWindow.open();
	});*/
	
	menuWindow.addEventListener('close', function(e) {
		this.maskWindow.close();
	});
	
	return menuWindow;
}

module.exports = MenuWindow;