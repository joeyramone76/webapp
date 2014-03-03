/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: loading提示
 */
function ActivityIndicator() {
	var config = {
		top: Ti.App.height / 2 - 30,
		left: 110,
		style: Ti.UI.iPhone.ActivityIndicatorStyle.DARK,
		zIndex: 102
	};
	if(Ti.Platform.name === 'iPhone OS') {
		config.style = Ti.UI.iPhone.ActivityIndicatorStyle.DARK;
	} else {
		config.style = Ti.UI.ActivityIndicatorStyle.DARK;
	}
	
	var activityIndicator = Ti.UI.createActivityIndicator({
		color: 'black',
		font: {fontFamily:'Helvetica Neue', fontSize:13, fontWeight:'bold'},
		message: L('loading'),
		style: config.style,
		top: config.top,
		left: config.left,
		height: Ti.UI.SIZE,
		width: Ti.UI.SIZE,
		zIndex: config.zIndex
	});
	
	return activityIndicator;
}

module.exports = ActivityIndicator;