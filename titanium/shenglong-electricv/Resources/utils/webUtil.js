var webUtil = {};

webUtil.getContent = function(webview) {
	var content = "";
	var dbUtil = require('utils/dbUtil');
	var datas = [];
	var template_url = webview.template_url;
	var code = "";
	if(webview.type == 1) {// pages
		//use db
		datas = dbUtil.getPageByMenuCode(webview.code);
		content = datas[0].content;
	} else if(webview.type == 2) {//newslist
		
	} else {
		if(template_url.indexOf("page_template") > 0) {
			code = webview.code + "001";
			datas = dbUtil.getPageByMenuCode(code);
			content = datas[0].content;
		} else if(template_url.indexOf("newslist_template") > 0) {
			
		} else if(template_url.indexOf("submenu") > 0) {
			
		}
	}
	return content;
};

webUtil.setWebviewAttribute = function(webview, menu) {
	webview.menu = menu;
	webview.code = menu.code;
	webview.type = menu.type;
	webview.pageId = menu.pageId;
	webview.newsId = menu.newsId;
	webview.parentCode = menu.parentCode;
	webview.sl_cid = menu.sl_cid;
	webview.template_url = menu.url;
};

exports.webUtil = webUtil;
exports.getContent = webUtil.getContent;
exports.setWebviewAttribute = webUtil.setWebviewAttribute;