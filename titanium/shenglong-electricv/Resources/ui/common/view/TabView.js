/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: tabView
 */
function TabView(opts) {
	this.tabGroupView = opts.tabGroupView;
	this.isActive = 0;
	
	var config = {
		height: 90,
		iconWidth: 50,
		iconHeight: 42,
		fontSize: 9,
		fontWeight: 'bold',
		fontColor: '#939393',
		focusColor: '#113788',
		layout: 'vertical',
		top: 19
	};
	
	this.fontColor = config.fontColor;
	this.focusColor = config.focusColor;
	
	config.iconWidth = config.iconWidth / 2;
	config.iconHeight = config.iconHeight / 2;
	config.top = config.top / 2;
	
	opts.height = config.height / 2;
	opts.layout = config.layout;
	
	this.tabView = Ti.UI.createView(opts);
	
	//icon
	this.icon = Ti.UI.createView({
		backgroundImage: opts.icon,
		backgroundFocusedImage: opts.icon.replace(".png", "") + "_h.png",
		width: config.iconWidth,
		height: config.iconHeight,
		top: config.top
	});
	this.tabView.add(this.icon);
	
	//title
	this.title = Ti.UI.createLabel({
		text: opts.title,
		color: config.fontColor,
		font: {fontSize: config.fontSize, fontWeight: config.fontWeight}
	});
	this.tabView.add(this.title);
};

TabView.prototype.addEventListener = function(name, callback) {
	this.tabView.addEventListener(name, callback);
};

TabView.prototype.appendTo = function(tabGroupView) {
	this.tabGroupView = tabGroupView;
	this.tabGroupView.add(this.tabView);
};

TabView.prototype.setTabGroupView = function(tabGroupView) {
	this.tabGroupView = tabGroupView;
};

TabView.prototype.setActive = function() {
	this.icon.setFocusable(true);
	this.icon.setBackgroundImage(this.icon.backgroundImage.replace(".png", "") + "_h.png");
	this.title.setColor(this.focusColor);
};

TabView.prototype.unsetActive = function() {
	this.icon.setFocusable(false);
	this.icon.setBackgroundImage(this.icon.backgroundImage.replace("_h.png", "") + ".png");
	this.title.setColor(this.fontColor);
};

module.exports = TabView;