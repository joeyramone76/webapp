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
		
		var fontColor = '#fff';
		
		//日期
		var dateView = Ti.UI.createView({
			height: Ti.UI.SIZE,
			layout: 'horizontal'
		});
		welcomeWindow.add(dateView);
		var dateLabel = Ti.UI.createLabel({
			color: fontColor,
			font: {fontSize: 26},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: date.getFullYear() + "年" + date.getMonth() + "月" + date.getDate() + "日",
			top: 20,
			left: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		dateView.add(dateLabel);
		
		var weekday = new Array(7);
		weekday[0] = "星期天";
		weekday[1] = "星期一";
		weekday[2] = "星期二";
		weekday[3] = "星期三";
		weekday[4] = "星期四";
		weekday[5] = "星期五";
		weekday[6] = "星期六";
		var weekLabel = Ti.UI.createLabel({
			color: fontColor,
			font: {fontSize: 16},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: weekday[date.getDay()],
			bottom: 3,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		dateView.add(weekLabel);
		
		//天气情况
		var todayWeather = Ti.UI.createView({
			height: Ti.UI.SIZE,
			layout: 'horizontal'
		});
		welcomeWindow.add(todayWeather);
		
		var temperatureLabel = Ti.UI.createLabel({
			color: fontColor,
			font: {fontSize: 60},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '2°',
			top: 10,
			left: 10,
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE
		});
		todayWeather.add(temperatureLabel);
		var situationImageLabel = Ti.UI.createLabel({
			backgroundImage: 'images/weather/icons/duoyun.png',
			width: 42,
			height: 30,
			bottom: 14
		});
		//todayWeather.add(situationImageLabel);
		var situationTextLabel = Ti.UI.createLabel({
			color: fontColor,
			font: {fontSize: 24},
			showColor: '#aaa',
			showOffset: {x:5, y:5},
			shadowRadius: 3,
			text: '北京',
			width: Ti.UI.SIZE,
			height: Ti.UI.SIZE,
			left: 10,
			bottom: 10
		});
		todayWeather.add(situationTextLabel);
		
		var weathersView = Ti.UI.createView({
			height: 140
		});
		var weathersData = [],
			row,
			firstLabelTop = 10,
			firstLabelLeft = 10,
			marginTop = 30,
			marginLeft = 60,
			top,
			left,
			weatherLabel,
			windLabel,
			temperatureLabel;
		for(var i = 0 ; i < 4 ; i++) {
			top = firstLabelTop + i * marginTop;
			left = firstLabelLeft;
			//date
			dateLabel = Ti.UI.createLabel({
				color: fontColor,
				left: left,
				text: '今天',
				width: Ti.UI.SIZE,
				height: 20,
				top: top,
				showOffset: {x:5, y:5},
			});
			weathersView.add(dateLabel);
			
			//temperature
			left = firstLabelLeft + 1 * marginLeft;
			temperatureLabel = Ti.UI.createLabel({
				color: fontColor,
				left: left,
				text: '2°',
				width: Ti.UI.SIZE,
				height: 20,
				top: top,
				showOffset: {x:5, y:5},
			});
			weathersView.add(temperatureLabel);
			
			//picture
			left = firstLabelLeft + 2 * marginLeft;
			situationImageLabel = Ti.UI.createLabel({
				backgroundImage: 'images/weather/icons/duoyun.png',
				width: 32,//42
				height: 20,//30
				top: top,
				left: left - 10
			});
			weathersView.add(situationImageLabel);
			
			//weather
			left = firstLabelLeft + 3 * marginLeft;
			weatherLabel = Ti.UI.createLabel({
				color: fontColor,
				left: left,
				text: '晴朗',
				width: Ti.UI.SIZE,
				height: 20,
				top: top,
				showOffset: {x:5, y:5},
			});
			weathersView.add(weatherLabel);
			
			//wind
			left = firstLabelLeft + 4 * marginLeft;
			windLabel = Ti.UI.createLabel({
				color: fontColor,
				left: left,
				text: '微风',
				width: Ti.UI.SIZE,
				height: 20,
				top: top,
				showOffset: {x:5, y:5},
			});
			weathersView.add(windLabel);
		}
		welcomeWindow.add(weathersView);
		
		var todayLimitCarLabel = Ti.UI.createLabel({
			color: '#fff',
			font: {fontSize: 20},
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
			font: {fontSize: 20},
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
			title: '进入应用',
			top: 20
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