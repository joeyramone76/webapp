$('article').bind("swipeleft", function() {
	var cityName = "上海";
	var cityCode = "101010100";
	loadWeather(cityName, cityCode);
});

$('article').bind("swiperight", function() {
	var cityName = "徐州";
	var cityCode = "101010100";
	loadWeather(cityName, cityCode);
});

var Weather = function(cityCode) {
	this.cityCode = cityCode;
};

Weather.prototype.getWeather = function(cb) {
	var url = "http://html5share.duapp.com/weather/weather.php";
	var data = {
		cityCode: this.cityCode
	}
	var params = "";
	for(var o in data) {
		params += o + "=" + data[o] + "&"
	}
	params = params.substr(0, params.length - 1);
	$.ajax({
		type: "get",
		dataType: "jsonp",
		jsonp: "jsoncallback",
		url: url + "?" + params,
		success: function(data, status) {
			cb(null, data);
		},
		error: function() {
			cb({}, null);
		}
	});
}

Weather.prototype.formateData = function(data) {
	var weathers = [];
	var weather = {}
	/**
	 * fl 风力
	 * st 舒适指数
	 * temp 温度
	 * weather
	 * wind
	 * http://m.weather.com.cn/img/c0.gif
	 */
	var keys = ["fl","st","temp","weather","wind","img"];
	for(var i = 1 ; i <= 6 ; i++) {
		weather = {};
		for(var j = 0 ; j < keys.length ; j++) {
			if(keys[j] == "img") {
				weather[keys[j]] = "http://m.weather.com.cn/img/c" + data.weatherinfo[keys[j] + ((i * 2) - 1)] + ".gif";
			} else {
				weather[keys[j]] = data.weatherinfo[keys[j] + i];
			}
		}
		weathers.push(weather);
	}
	return weathers;
}

function loadWeather(cityName, cityCode) {
	$.mobile.loading("show");
	var weather = new Weather(cityCode);
	weather.getWeather(function(err, data) {
		$.mobile.loading("hide");
		var weather = new Weather();
		var weathers = [];
		if(err) {
			weathers = [];
		} else {
			weathers = weather.formateData(data);
		}
		var weather = {
			cityName: cityName,
			weathers: weathers
		};
		console.log(weather);
		var template = $("#weatherTemplate").html();
		$("#article").html(_.template(template, {
			weather: weather
		}));
		$("#article").trigger("create");
	});	
}

function initWeather() {
	var cityName = "北京";
	var cityCode = "101010100";
	loadWeather(cityName, cityCode);
}

$(document).ready(function() {
	initWeather();
	$("setting").bind("click", function() {
		console.log("test");
	});
});

$(document).bind( 'mobileinit', function(){
	$.mobile.loader.prototype.options.text = "努力加载中...";
	$.mobile.loader.prototype.options.textVisible = true;
	$.mobile.loader.prototype.options.theme = "a";
	$.mobile.loader.prototype.options.html = "";
	$.mobile.ignoreContentEnabled = true;
});

/**
 * trigger('create');
 * .listview('refresh');
 * city: "北京"
city_en: "beijing"
cityid: "101010100"
date: ""
date_y: "2013年12月13日"
fchh: "18"
fl1: "小于3级"
fl2: "小于3级"
fl3: "小于3级"
fl4: "小于3级"
fl5: "小于3级"
fl6: "小于3级"
fx1: "微风"
fx2: "微风"
img1: "0"
img2: "99"
img3: "0"
img4: "99"
img5: "1"
img6: "99"
img7: "0"
img8: "99"
img9: "0"
img10: "99"
img11: "0"
img12: "99"
img_single: "0"
img_title1: "晴"
img_title2: "晴"
img_title3: "晴"
img_title4: "晴"
img_title5: "多云"
img_title6: "多云"
img_title7: "晴"
img_title8: "晴"
img_title9: "晴"
img_title10: "晴"
img_title11: "晴"
img_title12: "晴"
img_title_single: "晴"
index: "冷"
index48: "较冷"
index48_d: "建议着厚外套加毛衣等服装。年老体弱者宜着大衣、呢外套加羊毛衫。"
index48_uv: "弱"
index_ag: "极不易发"
index_cl: "适宜"
index_co: "较舒适"
index_d: "天气冷，建议着棉服、羽绒服、皮夹克加羊毛衫等冬季服装。年老体弱者宜着厚棉衣、冬大衣或厚羽绒服。"
index_ls: "基本适宜"
index_tr: "适宜"
index_uv: "中等"
index_xc: "适宜"
st1: "6"
st2: "-3"
st3: "5"
st4: "-4"
st5: "4"
st6: "-3"
temp1: "-5℃~6℃"
temp2: "-6℃~5℃"
temp3: "-4℃~3℃"
temp4: "-5℃~4℃"
temp5: "-6℃~4℃"
temp6: "-5℃~4℃"
tempF1: "23℉~42.8℉"
tempF2: "21.2℉~41℉"
tempF3: "24.8℉~37.4℉"
tempF4: "23℉~39.2℉"
tempF5: "21.2℉~39.2℉"
tempF6: "23℉~39.2℉"
weather1: "晴"
weather2: "晴"
weather3: "多云"
weather4: "晴"
weather5: "晴"
weather6: "晴"
week: "星期五"
wind1: "微风"
wind2: "微风"
wind3: "微风"
wind4: "微风"
wind5: "微风"
wind6: "微风"
 */