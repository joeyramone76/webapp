/*
 * A tabbed application, consisting of multiple stacks of windows associated with tabs in a tab group.
 * A starting point for tab-based application with multiple top-level windows.
 * Requires Titanium Mobile SDK 1.8.0+.
 *
 * In app.js, we generally take care of a few things:
 * - Bootstrap the application with any data we need
 * - Check for dependencies like device type, platform version or network connection
 * - Require and open our top-level UI component
 *
 */

//bootstrap and check dependencies
if (Ti.version < 1.8) {
  alert('Sorry - this application template requires Titanium Mobile SDK 1.8 or later');
}

// This is a single context application with mutliple windows in a stack
(function() {
	//determine platform and form factor and render approproate components
  	var osname = Ti.Platform.osname,
    	version = Ti.Platform.version,
    	height = Ti.Platform.displayCaps.platformHeight,
    	width = Ti.Platform.displayCaps.platformWidth;
	
	var Window;
	
	if(osname === 'iphone' || osname === 'ipad') {
		Window = require('ui/handheld/ios/ApplicationWindow');
	} else if(osname === 'mobileweb') {
		Window = require('ui/mobileweb/ApplicationWindow');
	} else {
		Window = require('ui/handheld/android/ApplicationWindow');
	}
	
	var ApplicationTabGroup = require('ui/common/ApplicationTabGroup');
	var theTabGroup = new ApplicationTabGroup();
	if(osname === 'iphone' || osname === 'ipad') {
		theTabGroup.open({transition: Titanium.UI.iPhone.AnimationStyle.FLIP_FROM_LEFT});
	} else {
		theTabGroup.open();
	}
	
	var MessageWindow = require('ui/common/MessageWindow'),
		messageWin = new MessageWindow();
		
	Titanium.App.addEventListener('event_one', function(e) {
		messageWin.setLabel('盛隆电气');
		messageWin.open();
		setTimeout(function() {
			messageWin.close({opactity: 0, duration: 500});
		}, 1000);
	});
	
	Titanium.App.addEventListener('event_two', function(e) {
		messageWin.setLable('欢迎您');
		messageWin.open();
		setTimeout(function() {
			messageWin.close({opacity:0, duration:500});
		}, 1000);
	});
	
	Ti.API.info("hello world!");
})();
