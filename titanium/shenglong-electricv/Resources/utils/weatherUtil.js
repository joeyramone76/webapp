var weatherUtil = {};

weatherUtil.getCity = function() {
	
};

weatherUtil.getWeather = function(callback) {
	weatherUtil.getBJLocation(function(location) {
		var args = location.longitude + "," + location.latitude;
		var BaiduService = require('services/baidu/BaiduService');
		var baiduService = new BaiduService();
		baiduService.getWeatherReport(args, callback);
		
		baiduService = null;
	});
};

weatherUtil.getLocation = function(callback) {
	Titanium.Geolocation.getCurrentPosition(function(e) {
		var longitude = 116.38926396691;
		var latitude = 39.923697675933;
		if(!e.success || e.error) {
			longitude = 116.38926396691;
			latitude = 39.923697675933;
		}
		longitude = e.coords.longitude;
		latitude = e.coords.latitude;
		callback({
			longitude: longitude,
			latitude: latitude
		});
	});
};

weatherUtil.getBJLocation = function(callback) {
	var longitude = 116.38926396691;
	var latitude = 39.923697675933;
	callback({
		longitude: longitude,
		latitude: latitude
	});
};
exports.weatherUtil = weatherUtil;
exports.getCity = weatherUtil.getCity;
exports.getLocation = weatherUtil.getLocation;
exports.getWeather = weatherUtil.getWeather;