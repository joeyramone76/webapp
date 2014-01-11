var initData = {};

initData.initDB = function() {
	var db = Ti.Database.open('shenglong-electricv');
	var fileUtil = require('utils/fileUtil');
	var sql = fileUtil.readFile('db/shenglong-electricv.sql');
	db.execute(sql);
};
