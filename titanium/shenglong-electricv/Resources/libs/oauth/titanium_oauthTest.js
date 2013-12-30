Ti.include('titanium_oauth.js');

var oauth = new TitaniumOAuth('dj0yJmk9TWFpV3VENDNIWGFiJmQ9WVdrOVNGWmhOWGRTTldFbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xYg--', 'ddab6eff9a2675046fc1c4496510c8e2697da513');

var options = {
	method: 'GET',
	url: 'http://yboss.yahooapis.com/geo/placefinder',
	parameters: [
		['location','40.21777,-74.759361']
	]
};


oauth.request(options, function(data) {
	Ti.API.info(data);
});
