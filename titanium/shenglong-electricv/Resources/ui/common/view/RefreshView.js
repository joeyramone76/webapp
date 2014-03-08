/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-08
 * Description: refreshView 使用tableView实现下拉刷新
 * Modification:
 *      甲、乙、丙、丁、戊、己、庚、辛、壬、癸 甲（jiǎ）、乙（yǐ）、丙（bǐng）、丁（dīng）、戊（wù）、己（jǐ）、庚（gēng）、辛（xīn）、壬（rén）、癸（guǐ）
 *      子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥 子（zǐ）、丑（chǒu）、寅（yín）、卯（mǎo）、辰（chén）、巳（sì）、午（wǔ）、未（wèi）、申（shēn）、酉（yǒu）、戌（xū）、亥（hài）
 * 		甲午年（马年）丁卯月戊寅日 农历二月初八
 */
function RefreshView(opts) {
	var config = {
		bgImgWidth: 166,
		bgImgHeight: 40,
		bgImgBottom: 10,
		top: opts.top
	};
	var webview = opts.webview;
	
	var webviewSection = Ti.UI.createTableViewSection({
		
	});
	var webviewRow = Ti.UI.createTableViewRow({
		height: opts.webviewHeight,
		layout: 'vertical'
	});
	webviewRow.add(webview);
	webviewSection.add(webviewRow);
	
	var control = Ti.UI.createRefreshControl({
        tintColor: '#939393'
    });
    control.addEventListener('refreshstart', function(e) {
        Ti.API.info('refreshstart');
        setTimeout(function() {
            Ti.API.debug('Timeout');
            control.endRefreshing();
        }, 2000);
    });
	var tableView = Ti.UI.createTableView({
		top: config.top,
		//refreshControl: control,
        data: [webviewSection]
	});
	
	var border = Ti.UI.createView({
		backgroundColor: "#576c89",
		height: 2,
		bottom: 0
	});
	var bgImg = Ti.UI.createView({
		backgroundImage: '/images/loading.png',
		width: config.bgImgWidth,
		height: config.bgImgHeight,
		bottom: config.bgImgBottom,
		left: (Ti.App.width - config.bgImgWidth) / 2
	});
	var tableHeader = Ti.UI.createView({
		backgroundColor: "#e2e7ed",
		width: Ti.App.width,
		height: 60
	});
	
	//bottom border 2 pixel
	//tableHeader.add(border);
	tableHeader.add(bgImg);
	
	var arrow = Ti.UI.createView({
		backgroundImage: "/images/whiteArrow.png",
		width: 23,
		height: 60,
		bottom: 10,
		left: 20
	});
	var statusLabel = Ti.UI.createLabel({
		text: "下拉刷新页面",
		left: 55,
		width: 200,
		bottom: 30,
		height: "auto",
		color: "#576c89",
		textAlign: "center",
		font: {fontSize:13,fontWeight:"bold"},
		shadowColor: "#999",
		shadowOffset: {x:0,y:1}
	});
	
	var companyNameLabel = Ti.UI.createLabel({
		text: "盛隆电气",
		left: 55,
		width: 200,
		bottom: 15,
		height: "auto",
		color: "#576c89",
		textAlign: "center",
		font: {fontSize: 12},
		shadowColor: "#999",
		shadowOffset: {x:0,y:1}
	});
	
	var actInd = Ti.UI.createActivityIndicator({
		left: 20,
		bottom: 13,
		width: 30,
		height: 30
	});
	tableHeader.add(arrow);
	//tableHeader.add(statusLabel);
	//tableHeader.add(companyNameLabel);
	tableHeader.add(actInd);
	
	tableView.headerPullView = tableHeader;
	var pulling = false;
	var reloading = false;
	
	function beginReloading() {
		// just mock out the reload
		setTimeout(endReloading, 2000);
	}
	
	function endReloading() {
		// simulate loading
		tableView.setContentInsets({top: 0}, {animated: true});
		reloading = false;
		statusLabel.text = "下拉刷新页面";
		actInd.hide();
		arrow.show();
	}
	
	tableView.addEventListener('scroll', function(e) {
	    Ti.API.info(JSON.stringify(e));
		var offset = e.contentOffset.y;
		if(offset <= -65.0 && !pulling && !reloading) {
			var t = Ti.UI.create2DMatrix();
			t = t.rotate(-180);
			pulling = true;
			arrow.animate({transform: t, duration: 180});
			statusLabel.text = "释放即可刷新";
		}
	});
	
	var event_dragEnd = "dragEnd";
	if(Ti.version >= '3.0.0') {
		event_dragEnd = "dragend";
	}
	tableView.addEventListener(event_dragEnd, function(e) {
		if(pulling && !reloading) {
			reloading = true;
			pulling = false;
			arrow.hide();
			actInd.show();
			
			statusLabel.text = "努力加载中...";
			tableView.setContentInsets({top: 60}, {animated: true});
			arrow.transform = Ti.UI.create2DMatrix();
			beginReloading();
		}
	});
	
	var event_dragStart = "dragStart";
    if(Ti.version >= '3.0.0') {
        event_dragStart = "dragstart";
    }
    tableView.addEventListener(event_dragStart, function(e) {
        var scrollY = webview.evalJS("window.scrollY");
        if(scrollY == 0) {
            pulling = false;
            tableView.headerPullView = tableHeader;
        } else {
            pulling = true;
            tableView.headerPullView = null;
        }
    });
	
	this.tableView = tableView;
};

RefreshView.prototype.addEventListener = function(name, callback) {
	
};

/**
 * show
 */
RefreshView.prototype.show = function() {
	this.tableView.show();
};

/**
 * hide
 */
RefreshView.prototype.hide = function() {
	this.tableView.hide();
};

module.exports = RefreshView;