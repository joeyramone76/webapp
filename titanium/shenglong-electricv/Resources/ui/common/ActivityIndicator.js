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