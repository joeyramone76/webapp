/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 网络相关
 */
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
		timeout: 10000 // in milliseconds
	});
	// Prepare the connection.
	client.open("GET", url);
	// Send the request.
	client.send();
};

//exports.netUtil = netUtil;
//exports.request = netUtil.request;