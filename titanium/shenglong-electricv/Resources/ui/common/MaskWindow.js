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