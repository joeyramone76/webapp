var utils = {};

utils.pixelsToDPUnits = function(thePixels) {
	return (thePixels / (Ti.Platform.displayCaps.dpi / 160));
};

utils.dpUnitsToPixels = function(theDPUnits) {
	return (theDPUnits * (Ti.Platform.displayCaps.dpi / 160));
};

exports.utils = utils;
exports.pixelsToDPUnits = utils.pixelsToDPUnits;
exports.dpUnitsToPixels = utils.dpUnitsToPixels;