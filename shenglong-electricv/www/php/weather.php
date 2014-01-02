<?php
	error_reporting(~E_ALL);
	
	$cityCode = $_GET["cityCode"];
	if(array_key_exists("jsoncallback", $_GET)) {
		$jsoncallback = $_GET["jsoncallback"];
	}
	$data = new stdClass();
	if(empty($cityCode)) {
		$data -> code = 101;
	} else {
		$url = "http://m.weather.com.cn/data/$cityCode.html";
		$data = file_get_contents($url);
		$data = json_decode($data);	
	}
	
	if($jsoncallback) {
		echo $jsoncallback . "(" . json_encode($data) . ")";
	} else {
		echo json_encode($data);
	}
?>