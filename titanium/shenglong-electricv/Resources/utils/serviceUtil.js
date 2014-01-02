var serviceUtil = {};

serviceUtil.getTrafficControls = function(callback) {
	var TrafficControlsService = require('services/TrafficControlsService');
	var trafficControlsService = new TrafficControlsService();
	trafficControlsService.getData(callback);
	
	trafficControlsService = null;
};

exports.serviceUtil = serviceUtil;
exports.getTrafficControls = serviceUtil.getTrafficControls;