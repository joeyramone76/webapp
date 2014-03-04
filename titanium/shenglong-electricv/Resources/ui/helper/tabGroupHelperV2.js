/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: 创建tabGroup
 */
var tabGroupHelper = {};
tabGroupHelper.createAppTabs = function(tabGroupView, welcomeWindow) {
	var Window = require('ui/common/ApplicationWindowV2'),
		TabView = require('ui/common/view/TabView');
	
	var config = require('ui/config/config'),
		menus = config.menus,
		menu = menus[Ti.App.visitInfo.activeTabIndex];
	
	var appTabs = [],
		appWin = new Window({
		title: L(menu.name),
		menuName: menu.name,
		menu: menu,
		welcomeWindow: welcomeWindow,
		url: menu.url.substring(1)
	});
	
	var icon = "",
		width = Math.floor(640 / menus.length / 2),
		activeIndex = 0;
		
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
		
		//bind tab event
		(function(index) {
			appTabs[i].addEventListener('click', function(e) {
				if(tabGroupView.tabIndex == index) {
					return;
				}
				var visitInfo = Ti.App.Properties.getObject('Ti.App.visitInfo');
				visitInfo.activeTabIndex = index;
				Ti.App.Properties.setObject('Ti.App.visitInfo', visitInfo);
				
				var webview = appWin.webview;
				var menu = menus[index];
				
				//改变submenu信息
				var submenu = appWin.submenu;
				submenu.changeSubmenu(menu.submenus);
				visitInfo = Ti.App.Properties.getObject('Ti.App.visitInfo');
				menu = visitInfo.activeMenu[index];
			
				//url = menu.url + "?r=" + new Date().getTime();
				url = menu.url;
				webUtil = require('utils/webUtil');
				webUtil.setWebviewAttribute(webview, menu);
				
				//webview.reload();
				webview.setUrl(url);
				
				tabGroupView.setActiveTab(visitInfo.activeTabIndex);
			});
		})(i);
	}
	tabGroupView.addWindow(appWin);
	tabGroupView.setActiveTab(activeIndex);
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