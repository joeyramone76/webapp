(function( window, undefined ) {
	var myScroll,
	pullDownEl, pullDownOffset,
	pullUpEl, pullUpOffset,
	generatedCount = 0;
	
	appiscroll = function() {
		return new appiscroll.fn.init();
	};
	
	appiscroll.fn = appiscroll.prototype = {
		init: function() {
			return this;
		}
	};
	
	appiscroll.fn.init.prototype = appiscroll.fn;

	function pullDownAction() {
		setTimeout(function () {
			myScroll.refresh();
		}, 1000);
	}

	function pullUpAction() {
		setTimeout(function () {
			myScroll.refresh();
		}, 1000);
	}
	
	appiscroll.scrollContent = function() {
		pullDownEl = document.getElementById('pullDown');
		pullDownOffset = pullDownEl.offsetHeight;
		pullUpEl = document.getElementById('pullUp');
		pullUpOffset = pullUpEl.offsetHeight;

		appiscroll.myScroll = myScroll = new iScroll('wrapper', {
			useTransition: true,
			topOffset : pullDownOffset,
			onRefresh : function () {
				if (pullDownEl.className.match('loading')) {
					pullDownEl.className = '';
					pullDownEl.querySelector('.pullDownLabel').innerHTML = '下拉以刷新...';
				} else if (pullUpEl.className.match('loading')) {
					pullUpEl.className = '';
					pullUpEl.querySelector('.pullUpLabel').innerHTML = '加载更多...';
				}
			},
			onScrollMove : function () {
				if (this.y > 5 && !pullDownEl.className.match('flip')) {
					pullDownEl.className = 'flip';
					pullDownEl.querySelector('.pullDownLabel').innerHTML = '加载完成...';
					this.minScrollY = 0;
				} else if (this.y < 5 && pullDownEl.className.match('flip')) {
					pullDownEl.className = '';
					pullDownEl.querySelector('.pullDownLabel').innerHTML = '下拉以刷新...';
					this.minScrollY = -pullDownOffset;
				} else if (this.y < (this.maxScrollY - 5) && !pullUpEl.className.match('flip')) {
					pullUpEl.className = 'flip';
					pullUpEl.querySelector('.pullUpLabel').innerHTML = '加载完成...';
					this.maxScrollY = this.maxScrollY;
				} else if (this.y > (this.maxScrollY + 5) && pullUpEl.className.match('flip')) {
					pullUpEl.className = '';
					pullUpEl.querySelector('.pullUpLabel').innerHTML = '加载更多...';
					this.maxScrollY = pullUpOffset;
				}
			},
			onScrollEnd : function () {
				if (pullDownEl.className.match('flip')) {
					pullDownEl.className = 'loading';
					pullDownEl.querySelector('.pullDownLabel').innerHTML = '努力加载中...';
					pullDownAction(); // Execute custom function (ajax call?)
				} else if (pullUpEl.className.match('flip')) {
					pullUpEl.className = 'loading';
					pullUpEl.querySelector('.pullUpLabel').innerHTML = '努力加载中...';
					pullUpAction(); // Execute custom function (ajax call?)
				}
			}
		});

		appiscroll.timeoutId = setTimeout(function () {
			document.getElementById('wrapper').style.left = '0';
		}, 800);
	};
		
	appiscroll.menuScroll = function() {
		hScroll = new iScroll('nav', {
			hScrollbar: false
		});
	};

	document.addEventListener('touchmove', function (e) {
		e.preventDefault();
	}, false);
	
	window.appiscroll = appiscroll;
	define(["iScroll"], function(iScroll) {
		return appiscroll;
	});
})(window);