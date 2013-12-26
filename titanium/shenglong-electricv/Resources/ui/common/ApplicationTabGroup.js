var messageWin;
function ApplicationTabGroup() {
	//create module instance
	var self = Ti.UI.createTabGroup(),
		Window = require('ui/common/ApplicationWindow');
	
	var webview = Ti.UI.createWebView({
		url: 'http://www.google.com'
	});

	//create app tabs
	var winHome = new Window(L('home'), webview),
		winNews = new Window(L('news'), webview),
		winProduct = new Window(L('product'), webview),
		winCustomer = new Window(L('customer'), webview),
		winConnect = new Window(L('connect'), webview),
		winSettings = new Window(L('settings'), webview);

	var tabHome = Ti.UI.createTab({
		title: L('home'),
		icon: '/images/KS_nav_ui.png',
		window: winHome
	});
	winHome.containingTab = tabHome;
	
	var tabNews = Ti.UI.createTab({
		title: L('news'),
		icon: '/images/KS_nav_ui.png',
		window: winNews
	});
	winNews.containingTab = tabNews;
	
	var tabProduct = Ti.UI.createTab({
		title: L('product'),
		icon: '/images/KS_nav_ui.png',
		window: winProduct
	});
	winProduct.containingTab = tabProduct;
	
	var tabCustomer = Ti.UI.createTab({
		title: L('customer'),
		icon: '/images/KS_nav_ui.png',
		window: winCustomer
	});
	winCustomer.containingTab = tabCustomer;
	
	var tabConnect = Ti.UI.createTab({
		title: L('connect'),
		icon: '/images/KS_nav_ui.png',
		window: winConnect
	});
	winConnect.containingTab = tabConnect;

	var tabSettings = Ti.UI.createTab({
		title: L('settings'),
		icon: '/images/KS_nav_views.png',
		window: winSettings
	});
	winSettings.containingTab = tabSettings;

	self.addTab(tabHome);
	self.addTab(tabNews);
	self.addTab(tabProduct);
	self.addTab(tabCustomer);
	self.addTab(tabConnect);
	self.addTab(tabSettings);

	return self;
};

module.exports = ApplicationTabGroup;
