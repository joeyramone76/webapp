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
		// window container
		var welcomeWindow = Titanium.UI.createWindow({
			height:80,
			width:200,
			touchEnabled:false
		});

		// black view
		var indView = Titanium.UI.createView({
			height:80,
			width:200,
			backgroundColor:'#000',
			borderRadius:10,
			opacity:0.8,
			touchEnabled:false
		});
		welcomeWindow.add(indView);

		// message
		var message = Titanium.UI.createLabel({
			text:'盛隆电气欢迎您',
			color:'#fff',
			textAlign:'center',
			font:{fontSize:18,fontWeight:'bold'},
			height:'auto',
			width:'auto'
		});
		welcomeWindow.add(message);
		welcomeWindow.open();

		var animationProperties = {delay: 1500, duration: 1000, opacity: 0.1};
		if (Ti.Platform.osname == "iPhone OS") {
			animationProperties.transform =
				Ti.UI.create2DMatrix().translate(-200, 200).scale(0);
		}
		welcomeWindow.animate(animationProperties, function() {
			welcomeWindow.close();
		});
	});
};

exports.tabGroupHelper = tabGroupHelper;
exports.createAppTabs = tabGroupHelper.createAppTabs;
exports.bindEvent = tabGroupHelper.bindEvent;