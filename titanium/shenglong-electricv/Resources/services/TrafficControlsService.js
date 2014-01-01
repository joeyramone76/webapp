function TrafficControlsService() {
	this.url = "http://html5share.duapp.com/services/trafficControls.php";
}

var netUtil = Ti.include('/utils/netUtil');
TrafficControlsService.prototype.getData = function(callback) {
	var url = this.url;
	netUtil.request(url, callback);
};

module.exports = TrafficControlsService;