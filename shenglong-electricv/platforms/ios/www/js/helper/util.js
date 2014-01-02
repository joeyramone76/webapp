var util = {};
util.test = function() {
	console.log("test");
}

util.showloading = function() {
	$.mobile.loading("show", {
		text: "努力加载中...",
		//textVisible: true,
		theme: "b",
		html: '<span class="ui-icon ui-icon-loading"><img style="position: relative;left: 14px;top: 14px;" src="./favicon.ico" /></span><h1 style="display:block">努力加载中...</h1>',
		textonly: false
	});
}

util.init_loading = function() {
	$.mobile.loader.prototype.options.text = "努力加载中...";
	//$.mobile.loader.prototype.options.textVisible = true;
	$.mobile.loader.prototype.options.theme = "b";
	$.mobile.loader.prototype.options.html = '<span class="ui-icon ui-icon-loading"><img style="position: relative;left: 14px;top: 14px;" src="./favicon.ico" /></span><h1 style="display:block">努力加载中...</h1>';
}

if(typeof define != "undefined") {
	define(["jquery","jquerymobile"], function($, jq) {
		return util;
	});
}