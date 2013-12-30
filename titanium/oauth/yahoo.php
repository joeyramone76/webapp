<?php
	require("php/OAuth.php");

	$url = "http://yboss.yahooapis.com/geo/placefinder";
	$cc_key  = "dj0yJmk9TWFpV3VENDNIWGFiJmQ9WVdrOVNGWmhOWGRTTldFbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xYg--";
	$cc_secret = "ddab6eff9a2675046fc1c4496510c8e2697da513";

	$args = array();
	$args["location"] = "37.787082+-122.400929";
	$args["gflags"] = "R";

	$consumer = new OAuthConsumer($cc_key, $cc_secret);
	$request = OAuthRequest::from_consumer_and_token($consumer, NULL,"GET", $url, $args);
	$request -> sign_request(new OAuthSignatureMethod_HMAC_SHA1(), $consumer, NULL);

	$url = sprintf("%s?%s", $url, OAuthUtil::build_http_query($args));
	$ch = curl_init();
	$headers = array($request -> to_header());
	curl_setopt($ch, CURLOPT_ENCODING , "gzip"); 
	curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

	//print_r("Request Headers\n");
	//print_r($headers);

	$rsp = curl_exec($ch);

	//print_r("\nHere is the XML response for Placefinder\n");//woeid
	print_r($rsp);
?>