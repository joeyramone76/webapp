var	carousel,
	el,
	i,
	page,
	slides = [
		'<h1>北京</h1>\
			<ul data-role="listview" data-inset="true">\
				<li>星期一</li>\
				<li>星期二</li>\
				<li>星期三</li>\
				<li>星期四</li>\
				<li>星期五</li>\
				<li>星期六</li>\
			</ul>',
		'<h1>上海</h1>\
			<ul data-role="listview" data-inset="true">\
				<li>星期一</li>\
				<li>星期二</li>\
				<li>星期三</li>\
				<li>星期四</li>\
				<li>星期五</li>\
				<li>星期六</li>\
			</ul>',
		'<h1>徐州</h1>\
			<ul data-role="listview" data-inset="true">\
				<li>星期一</li>\
				<li>星期二</li>\
				<li>星期三</li>\
				<li>星期四</li>\
				<li>星期五</li>\
				<li>星期六</li>\
			</ul>',
		'<h1>南京</h1>\
			<ul data-role="listview" data-inset="true">\
				<li>星期一</li>\
				<li>星期二</li>\
				<li>星期三</li>\
				<li>星期四</li>\
				<li>星期五</li>\
				<li>星期六</li>\
			</ul>'
	];

carousel = new SwipeView('#wrapper', {
	numberOfPages: slides.length,
	hastyPageFlip: true
});

// Load initial data
for(var i = 0 ; i < 3 ; i++) {
	page = i == 0 ? slides.length - 1 : i - 1;

	el = document.createElement('span');
	el.innerHTML = slides[page];
	carousel.masterPages[i].appendChild(el);
}

carousel.onFlip(function () {
	var el,
		upcoming,
		i;

	for(var i = 0 ; i < 3 ; i++) {
		upcoming = carousel.masterPages[i].dataset.upcomingPageIndex;

		if (upcoming != carousel.masterPages[i].dataset.pageIndex) {
			el = carousel.masterPages[i].querySelector('span');
			el.innerHTML = slides[upcoming];
		}
		$("#wrapper").trigger("create");
	}
});