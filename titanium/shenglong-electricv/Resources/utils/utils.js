var utils = {};

utils.pixelsToDPUnits = function(thePixels) {
	return (thePixels / (Ti.Platform.displayCaps.dpi / 160));
};

utils.dpUnitsToPixels = function(theDPUnits) {
	return (theDPUnits * (Ti.Platform.displayCaps.dpi / 160));
};

utils.getWeekdays = function() {
	this.weekday = new Array(7);
	this.weekday[0] = "星期天";
	this.weekday[1] = "星期一";
	this.weekday[2] = "星期二";
	this.weekday[3] = "星期三";
	this.weekday[4] = "星期四";
	this.weekday[5] = "星期五";
	this.weekday[6] = "星期六";
	return this.weekday;
};

utils.getSpokenWeekday = function() {
	this.weekday = new Array(7);
	this.weekday[0] = "周日";
	this.weekday[1] = "周一";
	this.weekday[2] = "周二";
	this.weekday[3] = "周三";
	this.weekday[4] = "周四";
	this.weekday[5] = "周五";
	this.weekday[6] = "周六";
	return this.weekday;
};

exports.utils = utils;
exports.pixelsToDPUnits = utils.pixelsToDPUnits;
exports.dpUnitsToPixels = utils.dpUnitsToPixels;
exports.getWeekdays = utils.getWeekdays;