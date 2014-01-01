<?php
	/**
	 * 交通线性
	 */
	/**
	 * a - "am" 或是 "pm"
	A - "AM" 或是 "PM"
	d - 几日，二位数字，若不足二位则前面补零; 如: "01" 至 "31"
	D - 星期几，三个英文字母; 如: "Fri"
	F - 月份，英文全名; 如: "January"
	h - 12 小时制的小时; 如: "01" 至 "12"
	H - 24 小时制的小时; 如: "00" 至 "23"
	g - 12 小时制的小时，不足二位不补零; 如: "1" 至 12"
	G - 24 小时制的小时，不足二位不补零; 如: "0" 至 "23"
	i - 分钟; 如: "00" 至 "59"
	j - 几日，二位数字，若不足二位不补零; 如: "1" 至 "31"
	l - 星期几，英文全名; 如: "Friday"
	m - 月份，二位数字，若不足二位则在前面补零; 如: "01" 至 "12"
	n - 月份，二位数字，若不足二位则不补零; 如: "1" 至 "12"
	M - 月份，三个英文字母; 如: "Jan"
	s - 秒; 如: "00" 至 "59"
	S - 字尾加英文序数，二个英文字母; 如: "th"，"nd"
	t - 指定月份的天数; 如: "28" 至 "31"
	U - 总秒数
	w - 数字型的星期几，如: "0" (星期日) 至 "6" (星期六)
	Y - 年，四位数字; 如: "1999"
	y - 年，二位数字; 如: "99"
	z - 一年中的第几天; 如: "0" 至 "365"
	 */
	$todayweek = date("w");
	$array = array("星期天","星期一","星期二","星期三","星期四","星期五","星期六");//0 1 2 3 4 5 6 => 1 2 3 4 5 6 7
	$tomorrowweek = date("w", strtotime("+1 day"));

	$url = "http://210.75.211.252/xianxing/xianhao.shtml";
	$content = file($url);
	//todayweek todaynum tomorrowweek tomorrownum

	$startDate = strtotime('2012-10-08');//开始星期，周一的日期
	$trafficControls = array('1和6','2和7','3和8','4和9','5和0','不限行','不限行');
	if($content) {
		$trafficControls = array();
		$trafficControl;
		$count = 7;
		foreach($content as $key => $value) {
			if(stripos($value, "var x") >= 0) {
				for($i = 0 ; $i < $count ; $i++) {
					if(stripos($value, "x" . ($i + 1)) > 0) {
						$trafficControl = substr($value, stripos($value, "'") + 1, strripos($value, "'") - stripos($value, "'") - 1);
						$trafficControls[$i] = $trafficControl;
					}
				}
			}
		}
	}
	$date = time();
	$todayTrafficControlNumber = getTrafficControlNumber($date, $startDate);
	$todayLimitCar = $trafficControls[$todayTrafficControlNumber - 1];
	$date = strtotime("+1 day");
	$tomorrowTrafficControlNumber = getTrafficControlNumber($date, $startDate);
	$tomorrowLimitCar = $trafficControls[$tomorrowTrafficControlNumber - 1];
	$json = new StdClass();
	$json -> todayLimitCar = $array[$todayweek] . " 限行的尾号是：" . $todayLimitCar;
	$json -> tomorrowLimitCar = $array[$tomorrowweek] . " 限行的尾号是：" . $tomorrowLimitCar;
	echo json_encode($json);

	function getTrafficControlNumber($date, $startDate) {// 2014-01-01 2012-10-08
		$nDayNum = date("w", $date) == 0 ? 7 : date("w", $date);//星期 0 1 2 3 4 5 6
		if($nDayNum > 5)
			return $nDayNum;
		$nDiff = ($date - $startDate) / 3600 / 24 / 7 / 13;//秒 分钟 小时 天 周 13周轮换一次

		$nDiff = floor($nDiff) % 5;
		$nDayNum = 5 - $nDiff + $nDayNum ;

		if($nDayNum > 5)
			$nDayNum -= 5;
		return $nDayNum;
	}
?>