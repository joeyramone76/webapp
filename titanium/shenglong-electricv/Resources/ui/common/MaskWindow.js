/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 用于弹出菜单遮罩
 */
function MaskWindow(opts) {
	var self = this;
	
	var maskWindow = Ti.UI.createWindow({
		backgroundColor: '#45454D',
		width: Ti.UI.Fill,
		height: Ti.UI.Fill,
		zIndex: 1000,
		opacity: '0.5'
	});
	
	return maskWindow;
}

module.exports = MaskWindow;