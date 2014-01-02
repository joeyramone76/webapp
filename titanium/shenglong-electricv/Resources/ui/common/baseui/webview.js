function Webview(opts) {
	var webview = Ti.UI.createWebView({
		url: opts.url
	});
	return webview;
}

module.exports = Webview;