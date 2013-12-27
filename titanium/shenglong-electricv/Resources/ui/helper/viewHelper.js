var viewHelper = {};
viewHelper.createSubMenu = function(window) {
	var arrowWidth = 30,
		arrowHeight = 30,
		arrowTop = 5,
		arrowIndex = 101,
		arrowLeft = 0,
		arrowRight = 0,
		opacity = 0.7,
		scrollBgColor = '#13386c',
		scrollBgIndex = 100,
		scrollBgTop = 0,
		contentWidth = 440,
		contentHeight = 40,
		submenuHeight = 30,
		scrollViewWidth = 260,// 320 arrowWidth
		left = 10,
		buttonWidth = 70,
		fontSize = 13;
	
	
	var submenuText = ["公司简介","党建概况","公司战略","发展历程","资质认证","盛隆文化"];
	
	var transform_arrow = Ti.UI.create2DMatrix();
	transform_arrow.scale(0.5, 0.5);
	
	var leftBg = Ti.UI.createView({
		contentWidth: arrowWidth,
		contentHeight: contentHeight,
		top: scrollBgTop,
		left: 0,
		height: contentHeight,
		width: arrowWidth,
		backgroundColor: scrollBgColor,
		zIndex: scrollBgIndex,
		opacity: opacity
	});
	var leftImage = Ti.UI.createView({
		backgroundImage: '/images/icon_arrow_left.png',
		height: arrowHeight,
		width: arrowWidth,
		top: arrowTop,
		left: arrowLeft,
		visible: false,
		zIndex: arrowIndex,
		opacity: opacity,
		transform: transform_arrow
	});
	leftBg.add(leftImage);
	window.add(leftBg);
	var rightBg = Ti.UI.createView({
		contentWidth: arrowWidth,
		contentHeight: contentHeight,
		top: scrollBgTop,
		right: 0,
		height: contentHeight,
		width: arrowWidth,
		backgroundColor: scrollBgColor,
		zIndex: scrollBgIndex,
		opacity: opacity
	});
	var rightImage = Ti.UI.createView({
		backgroundImage: 'images/icon_arrow_right.png',
		height: arrowHeight,
		width: arrowWidth,
		top: arrowTop,
		right: arrowRight,
		zIndex: arrowIndex,
		opacity: opacity
	});
	rightBg.add(rightImage);
	window.add(rightBg);
	
	var scrollView = Titanium.UI.createScrollView({
		contentWidth: contentWidth,
		contentHeight: contentHeight,
		top: scrollBgTop,
		height: contentHeight,
		width: scrollViewWidth,
		//borderRadius: 10,
		backgroundColor: '#13386c',
		zIndex: scrollBgIndex,
		opacity: opacity
	});
	
	scrollView.addEventListener('scroll', function(e) {
		Ti.API.info('x ' + e.x + ' y ' + e.y);
		
		if(e.x > 10) {
			leftImage.show();
		} else {
			leftImage.hide();
		}
		if(e.x < contentWidth - scrollViewWidth - 10) {
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
			height: submenuHeight,
			left: left + i * buttonWidth
		}));
		scrollView.add(submenuView[i]);
		submenuLabel.push(Ti.UI.createLabel({
			text: submenuText[i],
			font: {fontSize: fontSize},
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