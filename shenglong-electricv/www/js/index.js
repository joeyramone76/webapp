requirejs.config({
    //By default load any module IDs from js/lib
    baseUrl: 'js/lib',
    //except, if the module ID starts with "app",
    //load it from the js/app directory. paths
    //config is relative to the baseUrl, and
    //never includes a ".js" extension since
    //the paths config could be for a directory.
    paths: {
		jquery: 'jquery-1.9.1',
		jquerymobile: 'jquery.mobile-1.3.2',
		underscore: "underscore",
		iScroll: "iscroll",
		helper: '../helper',
        app: '../app',
		pages: "../../pages",
		//BMap: "http://api.map.baidu.com/api?v=2.0&ak=lQdsfRa5RghKht0IbnYQ4Mom"
		BMap: "http://api.map.baidu.com/getscript?v=2.0&ak=lQdsfRa5RghKht0IbnYQ4Mom&services=&t=20131213035516"
    },
	shim: {
        'jquery': {
            exports: '$'
        },
		'jquerymobile': {
            exports: 'jq'
        },
        'underscore': {
            exports: '_'
        },
        'backbone': {
            deps: ['underscore', 'jquery'],
            exports: 'Backbone'
        },
		"iScroll": {
			exports: "iScroll"
		},
		"BMap": {
			exports: "BMap"
		}
    }
});

requirejs(["jquerymobile", "underscore", "helper/util", "app/appiscroll", "app/app"], function(jq, _, util, appiscroll, app) {
	//$("a").attr('data-ajax', false);
	$(document).bind( 'mobileinit', function() {
		util.init_loading();
		$.mobile.ignoreContentEnabled = true;
	});
	$(document).ready(function() {
		util.showloading();
		app.init();
	});
})