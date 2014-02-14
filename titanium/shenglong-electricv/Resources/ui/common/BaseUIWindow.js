/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 基础UI
 */
function BaseUIWindow(title) {
	var self = Ti.UI.createWindow({
		title: title,
		backgroundColor: 'white'
	});
	
	return self;
}

module.exports = BaseUIWindow;