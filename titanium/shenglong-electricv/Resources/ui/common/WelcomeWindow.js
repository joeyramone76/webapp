function WelcomeWindow() {
	var date = new Date();
	var self = this;
	this.isAndroid = Ti.Platform.name === 'android';
	this.isTizen = Ti.Platform.osname === 'tizen';
		
	// 天气预报、车辆先行、定位
	var welcomeWindow = Ti.UI.createWindow({
		title: '盛隆提醒',
		backgroundImage: 'images/springFestival.jpg',
		layout: 'vertical'
	});
	this.welcomeWindow = welcomeWindow;
	this.weatherImagePath = 'images/weather/icons/day/';
	this.weatherImageCachePath = '';
	
	var fontColor = '#fff';
	this.fontColor = fontColor;
	
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
	var weathersData = [],
		row,
		firstLabelTop = 10,
		firstLabelLeft = 10,
		marginTop = 30,
		marginLeft = 60,
		top,
		left,
		dateLabels = [],
		weatherLabels = [],
		windLabels = [],
		situationImageLabels = [],
		temperatureLabels = [];
	this.dateLabels = dateLabels;
	this.weatherLabels = weatherLabels;
	this.windLabels = windLabels;
	this.situationImageLabels = situationImageLabels;
	this.temperatureLabels = temperatureLabels;
	
	weathersData = this.readFile("data/weather/weather.txt");
	
	var todayWeather = Ti.UI.createView({
		height: Ti.UI.SIZE,
		layout: 'horizontal'
	});
	welcomeWindow.add(todayWeather);
	
	this.temperatureLabel = Ti.UI.createLabel({
		color: fontColor,
		font: {fontSize: 60},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: weathersData.results[0].weather_data[0].temperature + '',//°
		top: 10,
		left: 10,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	todayWeather.add(this.temperatureLabel);
	var fileName = this.getFileName(weathersData.results[0].weather_data[0].dayPictureUrl);
	this.situationImageLabel = Ti.UI.createLabel({
		backgroundImage: this.weatherImagePath + fileName,
		width: 42,
		height: 30,
		bottom: 14
	});
	//todayWeather.add(this.situationImageLabel);
	this.situationTextLabel = Ti.UI.createLabel({
		color: fontColor,
		font: {fontSize: 24},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: weathersData.results[0].currentCity,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE,
		left: 10,
		bottom: 10
	});
	todayWeather.add(this.situationTextLabel);
	
	// weathersView
	var weathersView = Ti.UI.createView({
		height: 140
	});
	
	var weather_data = weathersData.results[0].weather_data;
	for(var i = 0 ; i < weather_data.length ; i++) {
		top = firstLabelTop + i * marginTop;
		left = firstLabelLeft;
		//date
		dateLabels.push(Ti.UI.createLabel({
			color: fontColor,
			left: left,
			text: weather_data[i].date.substr(0, 2),
			width: Ti.UI.SIZE,
			height: 20,
			top: top,
			showOffset: {x:5, y:5},
		}));
		weathersView.add(dateLabels[i]);
		
		//temperature
		left = firstLabelLeft + 1 * marginLeft - 20;
		temperatureLabels.push(Ti.UI.createLabel({
			color: fontColor,
			left: left,
			text: weather_data[i].temperature,//°
			width: Ti.UI.SIZE,
			height: 20,
			top: top,
			showOffset: {x:5, y:5},
		}));
		weathersView.add(temperatureLabels[i]);
		
		//picture
		left = firstLabelLeft + 2 * marginLeft;
		fileName = this.getFileName(weather_data[i].dayPictureUrl);
		situationImageLabels.push(Ti.UI.createLabel({
			backgroundImage: this.weatherImagePath + fileName,
			width: 32,//42
			height: 20,//30
			top: top,
			left: left
		}));
		weathersView.add(situationImageLabels[i]);
		
		//weather
		left = firstLabelLeft + 3 * marginLeft + 10;
		weatherLabels.push(Ti.UI.createLabel({
			color: fontColor,
			left: left,
			text: weather_data[i].weather,
			width: Ti.UI.SIZE,
			height: 20,
			top: top,
			showOffset: {x:5, y:5},
		}));
		weathersView.add(weatherLabels[i]);
		
		//wind
		left = firstLabelLeft + 4 * marginLeft;
		windLabels.push(Ti.UI.createLabel({
			color: fontColor,
			left: left,
			text: weather_data[i].wind,
			width: Ti.UI.SIZE,
			height: 20,
			top: top,
			showOffset: {x:5, y:5},
		}));
		weathersView.add(windLabels[i]);
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
	
	welcomeWindow.addEventListener('open', function() {
		var weatherUtil = require('utils/weatherUtil');
		var weathersData = Ti.App.Properties.getString("weathersData");
		if(weathersData == null || weathersData == "") {
			var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, "data/weather/weather.txt");
			var blob = file.read();
			var readText = blob.text;
			file = null;
			blob = null;
			weathersData = JSON.parse(readText);
		} else {
			self.updateData(JSON.parse(weathersData));
		}
		weatherUtil.getWeather(function(weathersData) {
			Ti.App.Properties.setString("weathersData", weathersData);
			weathersData = JSON.parse(weathersData);
			if(weathersData.error == 0) {
				if(weathersData.status == "success") {
					self.updateData(weathersData);
				} else {
					Ti.UI.createAlertDialog({
						title: '提示',
						message: '暂不支持该城市天气预报'
					}).show();
				}
			} else {
				Ti.UI.createAlertDialog({
					title: '提示',
					message: '暂不支持该城市天气预报'
				}).show();
			}
		});
	});
	return welcomeWindow;
};

WelcomeWindow.prototype.createWeathersView = function() {
	
};

WelcomeWindow.prototype.updateData = function(weathersData) {
	var date = new Date();
	var self = this;
	this.temperatureLabel.setText(weathersData.results[0].weather_data[0].temperature);
	this.situationTextLabel.setText(weathersData.results[0].currentCity);
	var weather_data = weathersData.results[0].weather_data;
	var dirName = "day";
	if(date.getHours() >= 6 && date.getHours() <= 18) {
		dirName = "day";
	} else {
		dirName = "night";
	}
	var fileName;
	var url;
	for(var i = 0 ; i < weather_data.length ; i++) {
		if(dirName == "day") {
			url = weather_data[i].dayPictureUrl;
		} else {
			url = weather_data[i].nightPictureUrl;
		}
		fileName = this.getFileName(url);
		
		this.dateLabels[i].setText(weather_data[i].date.substr(0, 2));
		this.weatherLabels[i].setText(weather_data[i].weather);
		this.windLabels[i].setText(weather_data[i].wind);
		this.saveFile(dirName, fileName, i, url, function(i, fileName) {
			self.situationImageLabels[i].setBackgroundImage(fileName);
		});
		this.temperatureLabels[i].setText(weather_data[i].temperature);
	}
};

WelcomeWindow.prototype.readFile = function(fileName) {
	var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, fileName);
	var blob = file.read();
	var readText = blob.text;
	file = null;
	blob = null;
	var weathersData = JSON.parse(readText);
	return weathersData;
};

WelcomeWindow.prototype.saveFile = function(dirName, fileName, index, url, callback) {
	var self = this;
	
	var imageDir = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory,            
	    'downloaded_images/' + dirName);
	if (!imageDir.exists()) {
	    imageDir.createDirectory();
	}
	
	var file = Ti.Filesystem.getFile(imageDir.resolve(), fileName);
	if(!file.exists()) {
		var client = Titanium.Network.createHTTPClient();
		client.setTimeout(10000);
		client.onload = function() {
			var file = Ti.Filesystem.getFile(imageDir.resolve(), fileName);
			file.write(this.responseData);
			callback(index, file.nativePath);
		};
		client.open('GET', url);
		client.send();
	} else {
		callback(index, file.nativePath);
	}
	file = null;
};

WelcomeWindow.prototype.getFileName = function(url) {
	var fileName = "";
	fileName = url.substr(url.lastIndexOf("/") + 1);
	return fileName;
};

module.exports = WelcomeWindow;