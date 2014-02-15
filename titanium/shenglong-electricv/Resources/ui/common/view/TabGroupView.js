/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: tabGroupView
 */
function TabGroupView(opts) {
	this.tabs = [];
	this.window = null;
	var config = {
		height: 90,
		backgroundColor: '#F0F0F0',
		focusColor: '#113788'
	};
	config.height = config.height / 2;
	
	this.tabGroupView = Ti.UI.createView({
		backgroundColor: config.backgroundColor,
		width: Ti.UI.FILL,
		height: config.height,
		bottom: 0,
		borderRadius: 0,
		layout: 'horizontal'
	});
};

TabGroupView.prototype.addTab = function(tab) {
	this.tabs.push(tab);
	this.tabGroupView.add(tab);
};

TabGroupView.prototype.addWindow = function(window) {
	this.window = window;
	this.window.add(this.tabGroupView);
};

TabGroupView.prototype.open = function() {
	this.window.open();
};

/**
 * setActiveTab
 * @param {Object} tabIndex
 */
TabGroupView.prototype.setActiveTab = function(tabIndex) {
	
};

TabGroupView.prototype.addEventListener = function(name, callback) {
	if(name == "open") {
		this.window.addEventListener(name, callback);
	} else {
		this.tabGroupView.addEventListener(name, callback);
	}
};

module.exports = TabGroupView;