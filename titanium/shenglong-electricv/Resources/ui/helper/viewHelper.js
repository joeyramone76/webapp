var viewHelper = {};
viewHelper.createSubMenu = function(window) {
	var leftImage = Ti.UI.createView({
		backgroundImage: '/images/icon_arrow_left.png',
		height: 30,
		width: 30,
		top: 8,
		left: 5,
		visible: false,
		zIndex: 101,
		opacity: 0.7
	});
	window.add(leftImage);
	var rightImage = Ti.UI.createView({
		backgroundImage: 'images/icon_arrow_right.png',
		height: 30,
		width: 30,
		top: 8,
		right: 5,
		zIndex: 101,
		opacity: 0.7
	});
	window.add(rightImage);
	
	var submenuText = ["公司简介","党建概况","公司战略","发展历程","资质认证","盛隆文化"];
	var left = 10;
	var width = 70;
	var contentWidth = 440;
	var clientWidth = 320;
	var scrollView = Titanium.UI.createScrollView({
		contentWidth: contentWidth,
		contentHeight: 50,
		top: 0,
		height: 50,
		width: clientWidth,
		//borderRadius: 10,
		backgroundColor: '#13386c',
		zIndex: 100,
		opacity: 0.7
	});
	
	scrollView.addEventListener('scroll', function(e) {
		Ti.API.info('x ' + e.x + ' y ' + e.y);
		
		if(e.x > 50) {
			leftImage.show();
		} else {
			leftImage.hide();
		}
		if(e.x < 80) {
			rightImage.show();
		} else {
			rightImage.hide();
		}
	});
	
	window.add(scrollView);
	
	var submenuView = [];
	var submenuLabel = [];
	for(var i = 0 ; i < submenuText.length ; i++) {
		submenuView.push(Ti.UI.createView({
			backgroundColor: '#336699',
			borderRadius: 10,
			borderWidth: 1,
			borderColor: '#336699',
			width: 60,
			height: 40,
			left: left + i * width
		}));
		scrollView.add(submenuView[i]);
		submenuLabel.push(Ti.UI.createLabel({
			text: submenuText[i],
			font: {fontSize: 13},
			color: '#fff',
			width: 'auto',
			textAlign: 'center',
			height: 'auto'
		}));
		submenuView[i].add(submenuLabel[i]);
		submenuView[i].addEventListener('click', function(e) {
			alert(i);
		});
	}
};
exports.viewHelper = viewHelper;
exports.createSubMenu = viewHelper.createSubMenu;