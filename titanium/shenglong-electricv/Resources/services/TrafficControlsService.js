/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 调用限行服务
 */
function TrafficControlsService() {
	this.url = "http://iMarket.duapp.com/services/trafficControls.php";
}

Ti.include('utils/netUtil.js');
TrafficControlsService.prototype.getData = function(callback) {
	var url = this.url;
	//var netUtil = require('utils/netUtil');
	netUtil.request(url, callback);
};

module.exports = TrafficControlsService;