var dbUtil = {};

dbUtil.initDB = function() {
	var db = Ti.Database.open('shenglong-electricv');
	var fileUtil = require('utils/fileUtil');
	var sql = fileUtil.readFile('db/shenglong-electricv.sql');
	db.execute(sql);
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