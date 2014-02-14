/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 日志相关
 */
exports.info = function(str) {
    Titanium.API.info(new Date() + ': ' + str);
};
 
exports.debug = function(str) {
    Titanium.API.debug(new Date() + ': ' + str);
};

exports.log = function(level, str) {
	Titanium.API.log(level, new Date() + ': ' + str);
};

exports.timestamp = function(str) {
	Titanium.API.timestamp(str);
};
