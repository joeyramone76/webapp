/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: tabView
 */
function TabView(opts) {
	var config = {
		height: 90,
		iconWidth: 50,
		iconHeight: 42,
		fontSize: 9,
		fontColor: '#939393',
		focusColor: '#113788',
		layout: 'vertical',
		top: 19
	};
	
	config.iconWidth = config.iconWidth / 2;
	config.iconHeight = config.iconHeight / 2;
	config.top = config.top / 2;
	
	opts.height = config.height / 2;
	opts.layout = config.layout;
	
	var self = Ti.UI.createView(opts);
	
	//icon
	var icon = Ti.UI.createView({
		backgroundImage: opts.icon,
		width: config.iconWidth,
		height: config.iconHeight,
		top: config.top
	});
	self.add(icon);
	
	//title
	var title = Ti.UI.createLabel({
		text: opts.title,
		color: config.fontColor,
		font: {fontSize: config.fontSize}
	});
	self.add(title);
	
	return self;
};

TabView.prototype.addEventListener = function(name, callback) {
	this.addEventListener(name, callback);
};

module.exports = TabView;