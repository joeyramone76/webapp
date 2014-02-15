/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 创建tabGroup
 */
var tabGroupHelper = {};
tabGroupHelper.createAppTabs = function(window, welcomeWindow) {
	var Window = require('ui/common/ApplicationWindow');
	
	var config = require('ui/config/config');
	var menus = config.menus;
	
	var appTabs = [];
	var appWin = [];
	var icon = "";
	for(var i = 0, l = menus.length ; i < l ; i++) {
		if(i == 0) {
			appWin.push(new Window({
				title: L(menus[i].name),
				menuName: menus[i].name,
				menu: menus[i],
				welcomeWindow: welcomeWindow,
				url: 'website/page_home_template.html'
			}).window);
		} else {
			appWin.push(new Window({
				title: L(menus[i].name),
				menuName: menus[i].name,
				menu: menus[i],
				welcomeWindow: welcomeWindow
			}).window);
		}
		
		if(menus[i].icon == "") {
			icon = "/images/KS_nav_ui.png";
		} else {
			icon = menus[i].icon;
		}
		appTabs.push(Ti.UI.createTab({
			title: L(menus[i].name),
			icon: icon,
			window: appWin[i],
			//backgroundColor: '#ffffff',
			//backgroundDisabledColor: '#ffffff',
			//color: '#000000',
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
		appWin[i].containingTab = appTabs[i];
		window.addTab(appTabs[i]);
	}
};

tabGroupHelper.bindEvent = function(tabGroup, welcomeWindow) {
	tabGroup.addEventListener("open", function(e) {
		welcomeWindow.open({modal: true});
	});
	tabGroup.addEventListener("singletap", function(e) {
		
	});
	tabGroup.addEventListener("focus", function(e) {
		//check tabIndex
		var tab = this.tabs[e.index];
		var webview = e.tab.getWindow().getChildren()[3];
		
		var menu = tab.menu;
	
		//url = menu.url + "?r=" + new Date().getTime();
		url = menu.url;
		webview.setUrl(url);
		webUtil = require('utils/webUtil');
		webUtil.setWebviewAttribute(webview, menu);
		
		webview.reload();
	});
};

exports.tabGroupHelper = tabGroupHelper;
exports.createAppTabs = tabGroupHelper.createAppTabs;
exports.bindEvent = tabGroupHelper.bindEvent;