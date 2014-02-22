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
	this.tabIndex = -1;
	
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
	tab.setTabGroupView(this);
	this.tabGroupView.add(tab.tabView);
};

TabGroupView.prototype.addWindow = function(window) {
	this.window = window;
	this.window.window.add(this.tabGroupView);
};

TabGroupView.prototype.open = function() {
	this.window.window.open();
};

/**
 * setActiveTab
 * @param {Object} tabIndex
 */
TabGroupView.prototype.setActiveTab = function(tabIndex) {
	if(this.tabIndex == tabIndex) {
		return;
	}
	//remove current active tab
	if(this.tabIndex != -1) {
		this.tabs[this.tabIndex].unsetActive();
	}
	this.tabIndex = tabIndex;
	this.tabs[this.tabIndex].setActive();
};

TabGroupView.prototype.addEventListener = function(name, callback) {
	if(name == "open") {
		this.window.window.addEventListener(name, callback);
	} else {
		this.tabGroupView.addEventListener(name, callback);
	}
};

module.exports = TabGroupView;