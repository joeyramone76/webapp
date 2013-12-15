var mapApp = {};

mapApp.initMap = function() {
	$("#map_container").attr("style", "height:" + (window.screen.height - 230) + "px");
	// 创建地图对象并初始化
	var mp = new BMap.Map("map_container");
	var point = new BMap.Point(116.404, 39.915);
	mp.centerAndZoom(point, 14);
	mp.enableInertialDragging();

	var type = "";
	type = TRANSIT_ROUTE; //公交检索
	type = DRIVING_ROUTE; //驾车检索
	type = LOCAL_SEARCH ; //本地检索

	//创建检索控件
	var searchControl = new BMapLib.SearchControl({
		container : "searchBox" //存放控件的容器
		, map     : mp  //关联地图对象
		, type    : type  //检索类型
	});
}

if(typeof define != "undefined") {
	define([], function() {
		return mapApp;
	});
} else {
	$(document).ready(function() {
		mapApp.initMap();
	});
	$("a[data-type=back]").click(function() {
		history.back();
	});
}