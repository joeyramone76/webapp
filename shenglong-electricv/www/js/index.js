requirejs.config({
    //By default load any module IDs from js/lib
    baseUrl: 'js/lib',
    //except, if the module ID starts with "app",
    //load it from the js/app directory. paths
    //config is relative to the baseUrl, and
    //never includes a ".js" extension since
    //the paths config could be for a directory.
    paths: {
        app: '../app',
		jquery: 'jquery-1.9.1',
		helper: '../helper',
		jquerymobile: 'jquery.mobile-1.3.2',
		iScroll: "iscroll",
		underscore: "underscore",
		pages: "../../pages"
    },
	shim: {
        'jquery': {
            exports: '$'
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
		}
    }
});

requirejs(["app/iscroll", "jquery", "jquerymobile", "underscore", "app/app", "helper/util"], function(appiscroll, $, jq, _, app, util) {
	//$("a").attr('data-ajax', false);
	$(document).bind( 'mobileinit', function() {
		util.init_loading();
		$.mobile.ignoreContentEnabled = true;
	});
	$(document).ready(function() {
		util.showloading();
		var date = new Date();
		$.ajax({
			type: "get",
			url: "pages/main.html?" + date.getTime(),
			success: function(data, status) {
				$("#main").html(data).trigger("pagecreate");
				$("#nav a").removeClass("ui-link");

				setTimeout(appiscroll.scrollContent, 200);
				setTimeout(appiscroll.menuScroll, 200);
				setTimeout(function() {
					$.mobile.loading("hide");
				}, 600);
	
				$("a[data-name=shenglong]").bind("click", function() {
					/*$.mobile.changePage("weather.html?" + date.getTime(), {
						transition: "slideup",
						changeHash: true
					});*/
					date = new Date();
					$.get("pages/weather.html?" + date.getTime()).then(function(data) {
						clearTimeout(appiscroll.timeoutId);
						$("#main").html(data).trigger("pagecreate");
						requirejs(["app/weather"], function(weather) {
							$("#article").attr("style", "height:" + (window.screen.height) + "px");
							weather.initWeather();
						});
					});
				});
			},
			error: function() {
				$.mobile.loading("hide");
			}
		});
	});
})