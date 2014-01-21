function MenuWindow(opts) {
	var self = this;
	var isMobileWeb = Ti.Platform.osname === 'mobileweb',
		isTizen = Ti.Platform.osname === 'tizen',
		isIOS = (Ti.Platform.osname == 'iphone' || Ti.Platform.osname == 'ipad');
	
	var menuWindow = Ti.UI.createWindow({
		backgroundColor: '#ffffff',
		layout: 'vertical',
		width: Ti.UI.Fill,
		height: 200,
		bottom: -200
	});
	
	var weatherButton = Ti.UI.createButton({
		title: '天气',
		color: '#000000'
	});
	isTizen || (weatherButton.style = Ti.UI.iPhone.SystemButtonStyle.BORDERED);
	
	menuWindow.add(weatherButton);
	
	weatherButton.addEventListener('click', function() {
		opts.welcomeWindow.menuWindow = menuWindow;
		opts.welcomeWindow.open({modal: true});
	});
	
	var cancelButton = Ti.UI.createButton({
		title: '取消',
		color: '#000000'
	});
	isTizen || (cancelButton.style = Ti.UI.iPhone.SystemButtonStyle.PLAIN);
	
	menuWindow.add(cancelButton);
	
	cancelButton.addEventListener('click', function() {
		var animation = Ti.UI.createAnimation();
		animation.duration = 400;
		animation.bottom = -200;
		menuWindow.close(animation);
	});
	
	return menuWindow;
}

module.exports = MenuWindow;