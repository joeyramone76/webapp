/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: 创建tabGroup
 */
var tabGroupHelper = {};
tabGroupHelper.createAppTabs = function(tabGroupView, welcomeWindow) {
	var Window = require('ui/common/ApplicationWindow');
	var TabView = require('ui/common/view/TabView');
	
	var config = require('ui/config/config');
	var menus = config.menus;
	var menu = menus[0];
	
	var appTabs = [];
	var appWin = new Window({
		title: L(menu.name),
		menuName: menu.name,
		menu: menu,
		welcomeWindow: welcomeWindow,
		url: 'website/page_home_template.html'
	});
	var icon = "";
	var width = Math.floor(640 / menus.length / 2);
	for(var i = 0, l = menus.length ; i < l ; i++) {
		if(menus[i].icon == "") {
			icon = "/images/KS_nav_ui.png";
		} else {
			icon = menus[i].icon;
		}
		appTabs.push(new TabView({
			width: width,
			title: L(menus[i].name),
			icon: icon,
			window: appWin,
			tabIndex: i,
			menu: menus[i],
			code: menus[i].code,
			type: menus[i].type,
			pageId: menus[i].pageId,
			newsId: menus[i].newsId,
			parentCode: menus[i].parentCode,
			sl_cid: menus[i].sl_cid,
			template_url: menus[i].url//template
		}));
		tabGroupView.addTab(appTabs[i]);
	}
	tabGroupView.addWindow(appWin);
};

tabGroupHelper.bindEvent = function(tabGroup, welcomeWindow) {
	tabGroup.addEventListener("open", function(e) {
		welcomeWindow.open({modal: true});
	});
	tabGroup.addEventListener("focus", function(e) {
		
	});
};

exports.tabGroupHelper = tabGroupHelper;
exports.createAppTabs = tabGroupHelper.createAppTabs;
exports.bindEvent = tabGroupHelper.bindEvent;