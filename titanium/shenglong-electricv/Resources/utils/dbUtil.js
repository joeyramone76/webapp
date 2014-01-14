var dbUtil = {};

dbUtil.initDB = function() {
	var db = Ti.Database.open('shenglong-electricv');
	var fileUtil = require('utils/fileUtil');
	
	var rows = db.execute("SELECT count(1) count FROM sqlite_master WHERE type='table' AND name='app_menus'");
	var count = 0;
	while(rows.isValidRow()) {
		count = rows.field(0);
		rows.next();
	}
	if(count == 1) {
		db.close();
		return;
	}
	
	db.execute("drop table if exists app_menus");
	db.execute("drop table if exists app_news");
	db.execute("drop table if exists app_pages");
	db.execute("drop table if exists weather_citys");
	db.execute("drop table if exists writers");
	
	var sql = fileUtil.readFile('db/shenglong-electricv-sqlite1.sql');
	//var sql = fileUtil.readFile('db/testsql.sql');
	var sql_array = sql.split(");");
	for(var i = 0 ; i < sql_array.length ; i++) {
		if(sql_array[i] == "")
			continue;
		Titanium.API.info(sql_array[i] + ")");
		db.execute(sql_array[i] + ")");
	}
	
	db.close();
};

dbUtil.getData = function(sql, columns) {
	var db = Ti.Database.open('shenglong-electricv');
	var rows = db.execute(sql);
	
	var count = rows.rowCount;
	var datas = [];
	while(rows.isValidRow()) {
		var data = {};
		for(var i = 0 ; i < columns.length ; i++) {
			data[columns[i]] = rows.fieldByName(columns[i]);
		}
		datas.push(data);
		rows.next();
	}
	
	rows.close();
	db.close();
	
	return datas;
};

dbUtil.getPageByMenuCode = function(menu_code) {
	var db = Ti.Database.open('shenglong-electricv');
	var sql = "SELECT id,sl_page_id,title,image,content,post_date,post_time,date FROM app_pages WHERE menu_code='" + menu_code + "'";
	var rows = db.execute(sql);
	
	var count = rows.rowCount;
	var columns = ["id","sl_page_id","title","image","content","post_date","post_time","date"];
	var datas = [];
	var data = {};
	while(rows.isValidRow()) {
		for(var i = 0 ; i < columns.length ; i++) {
			data[columns[i]] = rows.fieldByName(columns[i]);
		}
		datas.push(data);
		rows.next();
	}
	
	rows.close();
	db.close();
	
	return datas;
};

dbUtil.getPage = function(pageId) {
	var db = Ti.Database.open('shenglong-electricv');
	var sql = "SELECT id,sl_page_id,title,image,content,post_date,post_time,date FROM app_pages WHERE sl_page_id=?";
	var rows = db.execute(sql, pageId);
	
	var count = rows.rowCount;
	var columns = ["id","sl_page_id","title","image","content","post_date","post_time","date"];
	var datas = [];
	var data = {};
	while(rows.isValidRow()) {
		for(var i = 0 ; i < columns.length ; i++) {
			data[columns[i]] = rows.fieldByName(columns[i]);
		}
		datas.push(data);
		rows.next();
	}
	
	rows.close();
	db.close();
	
	return datas;
};

dbUtil.getNewsList = function(sl_cid) {
	var sql = "SELECT id,sl_cid,sl_news_id,title,image,post_desc,post_date,post_time,date FROM app_news WHERE sl_cid=" + sl_cid + "";
	var columns = ["id","sl_cid","sl_news_id","title","image","post_desc","post_date","post_time","date"];
	return dbUtil.getData(sql, columns);
};

dbUtil.getNews = function(sl_news_id) {
	var sql = "SELECT id,sl_cid,sl_news_id,title,image,post_desc,content,post_date,post_time,date FROM app_news WHERE sl_news_id=" + sl_news_id + "";
	var columns = ["id","sl_cid","sl_news_id","title","image","post_desc","content","post_date","post_time","date"];
	return dbUtil.getData(sql, columns);
};

dbUtil.test = function() {
	var db = Ti.Database.open('mydb1Installed');
	db.execute('CREATE TABLE IF NOT EXISTS people (name TEXT, phone_number TEXT, city TEXT)');
	db.execute('DELETE FROM people');
	
	var thisName = 'Arthur';
	var thisPhoneNo = '1-617-000-0000';
	var thisCity = 'Mountain View';
	db.execute('INSERT INTO people (name, phone_number, city) VALUES (?, ?, ?)', thisName, thisPhoneNo, thisCity);
	
	var personArray = ['Paul','020 7000 0000', 'London'];
	db.execute('INSERT INTO people (name, phone_number, city) VALUES (?, ?, ?)', personArray);
	
	var rows = db.execute('SELECT rowid,name,phone_number,city FROM people');
	
	Ti.API.info('Row count: ' + rows.rowCount);
	var fieldCount;
	// fieldCount is a property on Android.
	if (Ti.Platform.name === 'android') {
	    fieldCount = rows.fieldCount;
	} else {
	    fieldCount = rows.fieldCount();
	}
	Ti.API.info('Field count: ' + fieldCount);
	var fieldCount;
	// fieldCount is a property on Android.
	if (Ti.Platform.name === 'android') {
	    fieldCount = rows.fieldCount;
	} else {
	    fieldCount = rows.fieldCount();
	}
	Ti.API.info('Field count: ' + fieldCount);
	
	while (rows.isValidRow()){
	  Ti.API.info('Person ---> ROWID: ' + rows.fieldByName('rowid') + ', name:' + rows.field(1) + ', phone_number: ' + rows.fieldByName('phone_number') + ', city: ' + rows.field(3));
	  rows.next();
	}
	rows.close();
	db.close();
};

exports.dbUtil = dbUtil;
exports.initDB = dbUtil.initDB;
exports.getData = dbUtil.getData;
exports.getPage = dbUtil.getPage;
exports.getPageByMenuCode = dbUtil.getPageByMenuCode;
exports.getNewsList = dbUtil.getNewsList;
exports.getNews = dbUtil.getNews;