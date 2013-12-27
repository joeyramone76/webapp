function scroll_view_tabs(_args) {
	var win = Ti.UI.createWindow({
		title: _args.title
	});
	win.backgroundColor = '#000';
	
	var leftImage = Ti.UI.createView({
		backgroundImage: '/images/icon_arrow_left.png',
		height: 30,
		width: 30,
		top: 18,
		left: 5,
		visible: false
	});
	win.add(leftImage);
	var rightImage = Ti.UI.createView({
		backgroundImage: 'images/icon_arrow_right.png',
		height: 30,
		width: 30,
		top: 18,
		right: 5
	});
	win.add(rightImage);
	
	var scrollView = Titanium.UI.createScrollView({
		contentWidth: 500,
		contentHeight: 50,
		top: 10,
		height: 50,
		width: 230,
		borderRadius: 10,
		backgroundColor: '#13386c'
	});
	
	scrollView.addEventListener('scroll', function(e) {
		Ti.API.info('x ' + e.x + ' y ' + e.y);
		
		if(e.x > 50) {
			leftImage.show();
		} else {
			leftImage.hide();
		}
		if(e.x < 130) {
			rightImage.show();
		} else {
			rightImage.hide();
		}
	});
	
	win.add(scrollView);
	
	var view1 = Ti.UI.createView({
		backgroundColor: '#336699',
		borderRadius: 20,
		borderWidth: 1,
		borderColor: '#336699',
		width: 40,
		height: 40,
		left: 10
	});
	scrollView.add(view1);
	var l1 = Ti.UI.createLabel({
		text: '公司简介',
		font: {fontSize: 13},
		color: '#fff',
		width: 'auto',
		textAlign: 'center',
		height: 'auto'
	});
	view1.add(l1);
	
	win.add(scrollView);
	return win;
}

module.exports = scroll_view_tabs;
