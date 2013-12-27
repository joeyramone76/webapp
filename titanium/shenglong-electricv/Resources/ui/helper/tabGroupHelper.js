var tabGroupHelper = {};
tabGroupHelper.createAppTabs = function(window) {
	var Window = require('ui/common/ApplicationWindow');
	
	var config = require('ui/config/config');
	var menus = config.menus;
	
	var appTabs = [];
	var appWin = [];
	for(var i = 0, l = menus.length ; i < l ; i++) {
		appWin.push(new Window({
			title: L(menus[i].name),
			menuName: menus[i].name,
			menu: menus[i]
		}));
	}
	var icon = "";
	for(var i = 0, l = menus.length ; i < l ; i++) {
		if(menus[i].icon == "") {
			icon = "/images/KS_nav_ui.png";
		} else {
			icon = menus[i].icon;
		}
		appTabs.push(Ti.UI.createTab({
			title: L(menus[i].name),
			icon: icon,
			window: appWin[i]
		}));
		appWin[i].containingTab = appTabs[i];
		window.addTab(appTabs[i]);
	}
};
exports.tabGroupHelper = tabGroupHelper;
exports.createAppTabs = tabGroupHelper.createAppTabs;