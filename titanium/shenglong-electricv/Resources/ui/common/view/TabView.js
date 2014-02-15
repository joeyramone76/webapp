/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: tabView
 */
function TabView(opts) {
	var self = Ti.UI.createView(opts);
	
	//icon
	var icon = Ti.UI.createView({
		backgroundImage: opts.icon
	});
	self.add(icon);
	
	//title
	var title = Ti.UI.createLabel({
		text: opts.title
	});
	self.add(title);
	
	return self;
};

TabView.prototype.addEventListener = function(name, callback) {
	this.addEventListener(name, callback);
};

module.exports = TabView;