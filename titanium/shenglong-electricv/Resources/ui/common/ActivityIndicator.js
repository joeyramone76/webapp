/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: loading提示
 */
function ActivityIndicator() {
	var style;
	if(Ti.Platform.name === 'iPhone OS') {
		style = Ti.UI.iPhone.ActivityIndicatorStyle.DARK;
	} else {
		style = Ti.UI.ActivityIndicatorStyle.DARK;
	}
	
	var activityIndicator = Ti.UI.createActivityIndicator({
		color: 'black',
		font: {fontFamily:'Helvetica Neue', fontSize:13, fontWeight:'bold'},
		message: L('loading'),
		style: style,
		top: 180,
		left: 110,
		height: Ti.UI.SIZE,
		width: Ti.UI.SIZE
	});
	
	return activityIndicator;
}

module.exports = ActivityIndicator;