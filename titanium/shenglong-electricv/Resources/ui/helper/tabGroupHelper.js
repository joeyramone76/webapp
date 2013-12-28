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

tabGroupHelper.bindEvent = function(window) {
	window.addEventListener("open", function(e) {
		var date = new Date();
		
		// 天气预报、车辆先行、定位
		var welcomeWindow = Ti.UI.createWindow({
			title: '盛隆提醒',
			backgroundImage: 'images/springFestival.jpg',
			layout: 'vertical'
		});
		//日期
		var dateLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 24},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: date.getFullYear() + "年" + date.getMonth() + "月" + date.getDate() + "日",
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			top: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		welcomeWindow.add(dateLabel);
		//天气情况
		var situationImageLabel = Ti.UI.createLabel({
			backgroundImage: 'images/weather/a0.jpg',
			width: 48,
			height: 48
		});
		welcomeWindow.add(situationImageLabel);
		var situationTextLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 24},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '晴朗',
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			top: 30,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		welcomeWindow.add(situationTextLabel);
		
		var temperatureLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 60},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '2度',
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			top: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		welcomeWindow.add(temperatureLabel);
		
		var todayLimitCarLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 24},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '星期六 限行尾号是：不限行',
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			top: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		welcomeWindow.add(todayLimitCarLabel);
		
		var tomorrowLimitCarLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 24},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '星期日 限行尾号是：不限行',
			textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
			top: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		welcomeWindow.add(tomorrowLimitCarLabel);
		
		enterBtn = Ti.UI.createButton({
			title: '进入应用'
		});
		welcomeWindow.add(enterBtn);
		enterBtn.addEventListener('click', function() {
			welcomeWindow.close();
		});
		welcomeWindow.open({modal: true});
	});
};

exports.tabGroupHelper = tabGroupHelper;
exports.createAppTabs = tabGroupHelper.createAppTabs;
exports.bindEvent = tabGroupHelper.bindEvent;