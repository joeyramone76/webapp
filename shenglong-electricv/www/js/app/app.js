var app = {};

app = {
	init: function() {
		var date = new Date();
		app.loadPage("mainPage.html");
		$.ajax({
			type: "get",
			url: "pages/main.html?" + date.getTime(),
			success: function(data, status) {
				$.mobile.changePage("#main", {
					transition: "slideup",
					changeHash: false
				});
				app.trigger("main", data);
				$("#nav a").removeClass("ui-link");

				setTimeout(appiscroll.scrollContent, 200);
				setTimeout(appiscroll.menuScroll, 200);
				setTimeout(function() {
					$.mobile.loading("hide");
				}, 600);
	
				$("a[data-name=shenglong]").bind("click", function() {
					app.visitWeatherPage();
				});
				$("a[data-name=news]").bind("click", function() {
					app.visitMapPage();
				});
			},
			error: function() {
				$.mobile.loading("hide");
			}
		});
		//$("body").append('<div id="weather" data-role="page"></div>');
		//$("body").append('<div id="map" data-role="page"></div>');
	},
	visitMainPage: function() {
		var date = new Date();
		app.loadPage("mainPage.html");
		$.ajax({
			type: "get",
			url: "pages/main.html?" + date.getTime(),
			success: function(data, status) {
				$.mobile.changePage("#main", {
					transition: "slideup",
					changeHash: true
				});
				app.trigger("main", data);
				$("#nav a").removeClass("ui-link");

				setTimeout(appiscroll.scrollContent, 200);
				setTimeout(appiscroll.menuScroll, 200);
				setTimeout(function() {
					$.mobile.loading("hide");
				}, 600);
	
				$("a[data-name=shenglong]").bind("click", function() {
					app.visitWeatherPage();
				});
				$("a[data-name=news]").bind("click", function() {
					app.visitMapPage();
				});
			},
			error: function() {
				$.mobile.loading("hide");
			}
		});
	},
	visitNewsPage: function() {
		
	},
	visitWeatherPage: function() {
		/*$.mobile.changePage("weather.html?" + date.getTime(), {//²»Ö´ÐÐ½Å±¾
			transition: "slideup",
			changeHash: true
		});*/
		var date = new Date();
		/*$.get("pages/weather.html?" + date.getTime()).then(function(data) {
			clearTimeout(appiscroll.timeoutId);
			$("#main").html(data).trigger("pagecreate");
			requirejs(["app/weather"], function(weather) {
				$("#article").attr("style", "height:" + (window.screen.height) + "px");
				weather.initWeather();
			});
		});*/
		$.mobile.loadPage("pages/weatherPage.html");
		$.get("pages/weather.html?" + date.getTime()).then(function(data) {
			app.trigger("weather", data);
			$.mobile.changePage("#weather", {
				transition: "slideup",
				changeHash: true
			});
			
			requirejs(["app/weather"], function(weather) {
				$("#article").attr("style", "height:" + (window.screen.height) + "px");
				weather.initWeather();
			
				app.bindBackBtn();
			});
		});
	},
	visitMapPage: function() {
		/*var date = new Date();
		$.mobile.loadPage("pages/mapPage.html");
		$.get("pages/map.html?" + date.getTime()).then(function(data) {
			app.trigger("map", data);
			$.mobile.changePage("#map", {
				transition: "slideup",
				changeHash: true
			});
			
			requirejs(["BMap", "map/SearchControl", "app/map"], function(BMap, sc, map) {
				map.initMap();
			
				app.bindBackBtn();
			});
		});*/
		/*$.mobile.changePage("./map.html", {
			transition: "slideup",
			changeHash: true
		});*/
		window.location.href = "./map.html";
	},
	bindBackBtn: function() {
		$("a[data-type=back]").click(function() {
			//app.visitMainPage();
			app.changePage("main");
		})
	},
	loadPage: function(pageName) {
		//$.mobile.loadPage("pages/" + pageName + ".html");
	},
	changePage: function(pageName) {
		$.mobile.changePage("#" + pageName, {
			transition: "slideup",
			changeHash: true
		});
	},
	trigger: function(pageName, data) {
		$("#" + pageName).html(data).trigger("pagecreate");
		//$("#" + pageName).html(data).trigger("create");
	}
};

if(typeof define != "undefined") {
	define(["jquery", "app/appiscroll"], function($, appiscroll) {
		return app;
	});
}