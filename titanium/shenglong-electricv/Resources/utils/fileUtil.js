/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 文件相关
 */
var fileUtil = {};

fileUtil.readFile = function(fileName) {
	var file = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, fileName);
	var blob = file.read();
	var readText = blob.text;
	file = null;
	blob = null;
	return readText;
};

fileUtil.readData = function(dirName, fileName) {
	if(dirName == '') {
		dirName = 'download';
	}
	dir = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory,            
	    dirName + '/');
	if (!dir.exists()) {
	    dir.createDirectory();
	}
	
	var file = Ti.Filesystem.getFile(dir.resolve(), fileName);
	
	var blob = file.read();
	var readText = blob.text;
	file = null;
	blob = null;
	return readText;
};

fileUtil.writeFile = function(dirName, fileName, url, callback) {
	if(dirName == '') {
		dirName = 'download';
	}
	dir = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory,            
	    dirName + '/');
	if (!dir.exists()) {
	    dir.createDirectory();
	}
	
	var file = Ti.Filesystem.getFile(dir.resolve(), fileName);
	if(!file.exists()) {
		var client = Titanium.Network.createHTTPClient();
		client.setTimeout(10000);
		client.onload = function() {
			var file = Ti.Filesystem.getFile(dir.resolve(), fileName);
			file.write(this.responseData);
			callback(null, file.nativePath);
		};
		client.onerror = function() {
			callback({}, null);
			Ti.UI.createAlertDialog({
				title: '提示',
				message: '网络连接不给力哦'
			}).show();
		};
		client.open('GET', url);
		client.send();
	} else {
		callback(null, file.nativePath);
	}
	file = null;
};

fileUtil.getFileName = function(url) {
	var fileName = "";
	fileName = url.substr(url.lastIndexOf("/") + 1);
	return fileName;
};

exports.fileUtil = fileUtil;
exports.readFile = fileUtil.readFile;
exports.writeFile = fileUtil.writeFile;// only for applicationDataDirectory
exports.getFileName = fileUtil.getFileName;