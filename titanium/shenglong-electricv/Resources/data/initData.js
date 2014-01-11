var initData = {};

initData.initDB = function() {
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
