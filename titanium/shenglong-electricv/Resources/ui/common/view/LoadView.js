/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-28
 * Description: loadView
 * Modification:
 * 		甲午年（马年）丙寅月癸酉日 农历二月初三
 * 			配置loadView
 */
function LoadView(opts) {
	this.isShow = true;
	
	var config = {
		top: opts.top,
		bgColor: '#F0F0F0',
		width: Ti.UI.FILL,
		height: opts.height,
		zIndex: 101,
		image: 'images/icon.png',
		imageWidth: 100,
		imageHeight: 100,
		imageTop: Ti.App.height / 2 - 50 - 30
	};
	
	config.imageWidth = config.imageWidth / 2;
	config.imageHeight = config.imageHeight / 2;
	//config.imageTop = config.imageTop / 2;
	
	this.loadView = Ti.UI.createView({
		backgroundColor: config.bgColor,
		top: config.top,
		width: config.width,
		height: config.height,
		zIndex: config.zIndex
	});
	
	//image
	this.image = Ti.UI.createView({
		backgroundImage: config.image,
		width: config.imageWidth,
		height: config.imageHeight,
		top: config.imageTop
	});
	this.loadView.add(this.image);
	this.hide();
};

LoadView.prototype.addEventListener = function(name, callback) {
	
};

/**
 * show
 */
LoadView.prototype.show = function() {
	this.loadView.show();
};

/**
 * hide
 */
LoadView.prototype.hide = function() {
	this.loadView.hide();
};

module.exports = LoadView;