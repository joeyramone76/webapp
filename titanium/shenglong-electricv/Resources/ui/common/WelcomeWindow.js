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
	this.dateLabel = Ti.UI.createLabel({
		color: fontColor,
		font: {fontSize: 26},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: date.getFullYear() + "年" + (date.getMonth() + 1) + "月" + date.getDate() + "日",
		top: 20,
		left: 10,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	dateView.add(this.dateLabel);
	
	this.weekday = new Array(7);
	this.weekday[0] = "星期天";
	this.weekday[1] = "星期一";
	this.weekday[2] = "星期二";
	this.weekday[3] = "星期三";
	this.weekday[4] = "星期四";
	this.weekday[5] = "星期五";
	this.weekday[6] = "星期六";
	this.weekLabel = Ti.UI.createLabel({
		color: fontColor,
		font: {fontSize: 16},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: this.weekday[date.getDay()],
		bottom: 3,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	dateView.add(this.weekLabel);
	
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
	
	trafficControls = this.readFile("data/services/trafficControls.txt");
	
	this.todayLimitCarLabel = Ti.UI.createLabel({
		color: '#fff',
		font: {fontSize: 20},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: trafficControls.todayLimitCar,
		top: 10,
		left: 20,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	welcomeWindow.add(this.todayLimitCarLabel);
	
	this.tomorrowLimitCarLabel = Ti.UI.createLabel({
		color: '#fff',
		font: {fontSize: 20},
		showColor: '#aaa',
		showOffset: {x:5, y:5},
		shadowRadius: 3,
		text: trafficControls.tomorrowLimitCar,
		top: 10,
		left: 20,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	welcomeWindow.add(this.tomorrowLimitCarLabel);
	
	enterBtn = Ti.UI.createButton({
		title: '进入应用',
		top: 20
	});
	welcomeWindow.add(enterBtn);
	enterBtn.addEventListener('click', function() {
		welcomeWindow.close();
	});
	
	welcomeWindow.addEventListener('open', function() {
		self.updateDateLabel();
		var weatherUtil = require('utils/weatherUtil');
		var serviceUtil = require('utils/serviceUtil');
		var weathersData = Ti.App.Properties.getString("weathersData");
		if(weathersData == null || weathersData == "") {
			var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, "data/weather/weather.txt");
			var blob = file.read();
			var readText = blob.text;
			file = null;
			blob = null;
			weathersData = JSON.parse(readText);
		} else {
			self.updateWeatherData(JSON.parse(weathersData));
		}
		
		var trafficControls = Ti.App.Properties.getString("trafficControlsData");
		if(trafficControls == null || trafficControls == "") {
			
		} else {
			self.updateTrafficControlsData(JSON.parse(trafficControls));
		}
		
		weatherUtil.getWeather(function(err, weathersData) {
			serviceUtil.getTrafficControls(function(err, trafficControls) {
				if(weathersData != null) {
					weathersData = JSON.parse(weathersData);
					if(weathersData.error == 0) {
						Ti.App.Properties.setString("weathersData", JSON.stringify(weathersData));
						if(weathersData.status == "success") {
							self.updateWeatherData(weathersData);
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
				}
				if(trafficControls != null) {
					Ti.App.Properties.setString("trafficControlsData", trafficControls);
					self.updateTrafficControlsData(JSON.parse(trafficControls));
				}
			});
		});
	});
	return welcomeWindow;
};

WelcomeWindow.prototype.createWeathersView = function() {
	
};

WelcomeWindow.prototype.updateDateLabel = function() {
	var date = new Date();
	var self = this;
	this.dateLabel.setText(date.getFullYear() + "年" + (date.getMonth() + 1) + "月" + date.getDate() + "日");
	this.weekLabel.setText(this.weekday[date.getDay()]);
};

WelcomeWindow.prototype.updateWeatherData = function(weathersData) {
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

WelcomeWindow.prototype.updateTrafficControlsData = function(trafficControls) {
	var date = new Date();
	var self = this;
	this.todayLimitCarLabel.setText(trafficControls.todayLimitCar);
	this.tomorrowLimitCarLabel.setText(trafficControls.tomorrowLimitCar);
};

WelcomeWindow.prototype.readFile = function(fileName) {
	var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, fileName);
	var blob = file.read();
	var readText = blob.text;
	file = null;
	blob = null;
	var data = JSON.parse(readText);
	return data;
};

WelcomeWindow.prototype.saveFile = function(dirName, fileName, index, url, callback) {
	var self = this;
	
	var imageDir = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory,            
	    'downloaded_images/');
	if (!imageDir.exists()) {
	    imageDir.createDirectory();
	}
	
	imageDir = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory,            
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
		client.onerror = function() {
			var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, self.weatherImagePath + fileName);
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
