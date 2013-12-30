Ti.include('titanium_oauth.js');

var oauth = new TitaniumOAuth('Consumer key', 'Consumer secret');

var options = {
	method: 'POST',
	action: 'https://api.twitter.com/1/statuses/update.json',
	parameters: [
		['status', 'Just installed an App for the iPhone.']
	]
};

oauth.requestToken(function() {
	oauth.request(options, function(data) {
		Ti.API.info(data);
	});
});

oauth.addEventListener('login', function() {
	// Do something
});

oauth.addEventListener('logout', function() {
	// Do something
});

if(oauth.loggedIn()) {
	// Do something
}

oauth.logout();
