/**
 * Titanium OAuth Client
 * 
 * Copyright 2013, Peter Zhang
 * Licensed under the MIT
 * Copyright (c) 2013 Peter Zhang
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPERESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

Ti.include('sha1.js');
Ti.include('oauth.js');

var TitaniumOAuth = function(consumerKey, consumerSecret) {
	var self = this;
	
	var consumer = {
		consumerKey: consumerKey,
		consumerSecret: consumerSecret,
		serviceProvider: {
			signatureMethod: 'HMAC-SHA1',
			oauthVersion: '1.0'
		}
	};
	
	// Request
	this.request = function(options, callback) {
		var message = {
			method: options.method,
			url: options.url,
			parameters: [
				['oauth_version', consumer.serviceProvider.oauthVersion],
				['oauth_signature_method', consumer.serviceProvider.signatureMethod],
				['oauth_consumer_key', consumer.consumerKey]
			]
		};
		
		for(param in options.parameters) {
			message.parameters.push(options.parameters[param]);
		};
		
		OAuth.setTimestampAndNonce(message);
		OAuth.SignatureMethod.sign(message);
		
		var finalUrl = OAuth.addToURL(message.url, message.parameters);
		
		var xhr = Titanium.Network.createHTTPClient({
			timeout: 200000
		});
		xhr.onload = function() {
			callback(this.responseText);
		};
		xhr.onerror = function(e) {
			Ti.UI.createAlertDialog({
				title: 'Service Unavailable',
				message: 'An error ocurred while making a request.'
			}).show();
		};
		xhr.open(options.method, finalUrl, false);
		xhr.send();
	};
};

// Dispatcher
function Dispatcher() {
	this.events = [];
}

Dispatcher.prototype.addEventListener = function(event, callback) {
	this.events[event] = this.events[event] || [];
	if(this.events[event]) {
		this.events[event].push(callback);
	}
};

Dispatcher.prototype.removeEventListener = function(event, callback) {
	if(this.events[event]) {
		var listeners = this.events[event];
		for(var i = listeners.length - 1 ; i >= 0 ; --i) {
			if(listeners[i] === callback) {
				listeners.splice(i, 1);
				return true;
			}
		}
	}
	return false;
};

Dispatcher.prototype.dispatch = function(event) {
	if(this.events[event]) {
		var listeners = this.events[event], len = listeners.length;
		while(len--) {
			listeners[len](this);
		}
	}
};

TitaniumOAuth.prototype = new Dispatcher();
