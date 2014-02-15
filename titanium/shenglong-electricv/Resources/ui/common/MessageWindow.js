/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-01-27
 * Description: 消息提示窗口
 */
function MessageWindow() {
	var win = Ti.UI.createWindow({
		height: 30,
		width: 250,
		bottom: 70,
		borderRadius: 10,
		touchEnabled: false
	});
	var messageView = Ti.UI.createView({
		id: 'messageview',
		height: 30,
		width: 250,
		borderRadius: 10,
		backgroundColor: '#000',
		opacity: 0.7,
		touchEnabled: false
	});
	var messageLabel = Ti.UI.createLabel({
		id: 'messagelabel',
		text: '',
		color: '#fff',
		width: 250,
		height: 'auto',
		font: {
			fontFamily: 'Helvetica Neus',
			fontSize: 13
		},
		textAlign: 'center'
	});
	
	win.add(messageView);
	win.add(messageLabel);
	
	this.setLabel = function(_text) {
		messageLabel.text = _text;
	};
	
	this.open = function(_args) {
		win.open(_args);
	};
	
	this.close = function(_args) {
		win.close(_args);
	};
}

module.exports = MessageWindow;
