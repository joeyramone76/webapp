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