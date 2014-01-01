var netUtil = {};

netUtil.request = function(url, callback) {
	var client = Ti.Network.createHTTPClient({
		onload: function(e) {
			callback(null, this.responseText);
		},
		onerror: function(e) {
			callback({}, null);
			Ti.UI.createAlertDialog({
				title: '提示',
				message: '网络连接不给力哦'
			}).show();
		},
		timeout: 5000 // in milliseconds
	});
	// Prepare the connection.
	client.open("GET", url);
	// Send the request.
	client.send();
};

exports.netUtil = netUtil;