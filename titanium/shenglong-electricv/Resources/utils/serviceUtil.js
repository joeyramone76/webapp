/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 服务相关
 */
var serviceUtil = {};

serviceUtil.getTrafficControls = function(callback) {
	var TrafficControlsService = require('services/TrafficControlsService');
	var trafficControlsService = new TrafficControlsService();
	trafficControlsService.getData(callback);
	
	trafficControlsService = null;
};

exports.serviceUtil = serviceUtil;
exports.getTrafficControls = serviceUtil.getTrafficControls;