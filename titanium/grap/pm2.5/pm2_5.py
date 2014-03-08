# -*- coding: UTF-8 -*-
#安装MYSQL DB for python
import sys;
import os;
import MySQLdb as mdb;
import datetime;
import time;
import re;
import string;
import urllib;
import urllib2;
import httplib;
import json;
import math;
import codecs;
from xpinyin import Pinyin;
from types import *;

conn = None;
#reload(sys)
#sys.setdefaultencoding('utf-8');

def sayHello(argv=None):
	print sys.argv;
	print len(sys.argv);
	print sys.argv[:];
	print sys.path;
	
def test():
	try:
		#连接mysql方法: connect('ip','user','password','dbname')
		conn = mdb.connect('localhost', 'root', 'root', 'pm2_5');
		
		#所有的查询，都在连接con的一个模块cursor上面运行的
		cur = conn.cursor();
		
		#执行一个查询
		cur.execute("select version()");
		
		#取得上个查询的结果，是单个结果
		data = cur.fetchone();
		print "Database verson : %s " % data
		
		# execute SQL select statement
		cur.execute("select * from weather_cities");
		# commit your changes
		conn.commit();
		
		# get the number of rows in the resultset
		numrows = int(cur.rowcount)
		
		# get and display one row at a time
		for x in range(0, numrows):
			row = cur.fetchone()
			print row
			
		cur.execute("select cityCode from weather_cities");
		#cur.execute("insert into t(test) values (?)", ('test'));
		for row in cur.fetchall():
			print row[0]
	finally:
		if conn:
			#无论如何，连接记得关闭
			conn.close();

def testUrl():
	response = urllib2.urlopen('http://www.baidu.com');
	html = response.read();
	print html;
	
#将conn设定为全局连接
conn = mdb.connect('localhost', 'root', 'root', 'pm2_5');
token = "5j1znBVAsnSf5xQyNQyq";

def readJson(fileName):
	type = 1;# file
	if(fileName.find("http") == 0):
		type = 2;# http
		
	if(type == 1):
		print "file";
		jsonstring = readFile(fileName);
		jsonstring = jsonstring.replace('\t', '').replace('\n', '');
		jsons = json.loads(jsonstring);
	else:
		print "http";
		#html = urllib2.urlopen(fileName).read();
		#jsons = json.loads(html);
		
		header = {
			'Host':'www.pm25.in',
			'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
			'Accept-Encoding':'gzip,deflate,sdch'
			'Accept-Language':'zh-CN,zh;q=0.8,en;q=0.6'
			'Cache-Control':'max-age=0'
			'Connection':'keep-alive'
			'Cookie':'_aqi_query_session=BAh7CUkiD3Nlc3Npb25faWQGOgZFRkkiJTYzOTJhODhmMzE4ZGEyNGEwNDA5NTNkN2NmMDk4OWM2BjsAVEkiDGNhcHRjaGEGOwBGIi0xYTYzYjE4ODFhNTVlNjkzYzg0NjZlNTUyMTU0MzUwMDM5MmY2MGIwSSIQX2NzcmZfdG9rZW4GOwBGSSIxalZKSVNEVktpMkQzYTJwaU41Z2ZqQml6dGhHSnJkTjJzdzVQLzdLR2prOD0GOwBGSSIdd2FyZGVuLnVzZXIuYXBpX3VzZXIua2V5BjsAVFsHWwZpAkIDSSIiJDJhJDEwJFhGQzRsazhwOFdOOFZUWHVQaXl3R08GOwBU--85ea51d98e7f5d26be86e0873d0c54d244acfaba; __utma=162682429.2026272355.1394015987.1394036995.1394089170.3; __utmc=162682429; __utmz=162682429.1394015987.1.1.utmcsr=malagis.com|utmccn=(referral)|utmcmd=referral|utmcct=/recommended-air-quality-data-pm10-pm2-5.html'
			'If-None-Match':'"ab09f8d133334c65fafc2ae8925c9414"'
			'User-Agent':'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36'
		};
		httpConnection = httplib.HTTPConnection("www.pm25.in");
		httpConnection.request(method='GET',url='/api/querys/all_cities.json',headers=header);
		res = httpConnection.getresponse();
		res.read();
		httpConnection.close();
	return jsons;
		
def getAllData(fileName):
	'''getAllData'''
	
	cursor = conn.cursor();
	
	year = time.strftime("%Y", time.localtime(time.time()));
	tableName = "pm2_5_data%s" % year;
	
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	saveFileName = "insert_data.sql";
	file = codecs.open(saveFileName, "w", 'utf-8');
	
	jsons = readJson(fileName);
	if(type(jsons) == DictionaryType and jsons["error"]):
		print "no data";
		return;
	
	p = Pinyin();
	
	for data in jsons:
		aqi = data['aqi'];
		cityCode = '';
		area = data['area'];
		cityName = data['area'];
		spellName = p.get_pinyin(cityName, '');
		co = data['co'];
		co_24h = data['co_24h'];
		no2 = data['no2'];
		no2_24h = data['no2_24h'];
		o3 = data['o3'];
		o3_24h = data['o3_24h'];
		o3_8h = data['o3_8h'];
		o3_8h_24h = data['o3_8h_24h'];
		pm10 = data['pm10'];
		pm10_24h = data['pm10_24h'];
		pm2_5 = data['pm2_5'];
		pm2_5_24h = data['pm2_5_24h'];
		so2 = data['so2'];
		so2_24h = data['so2_24h'];
		primary_pollutant = data['primary_pollutant'];
		quality = data['quality'];
		station_code = data['station_code'];
		position_name = data['position_name'];
		time_point = data['time_point'];
		publishDate = time.mktime(datetime.datetime.strptime(time_point, '%Y-%m-%dT%H:%M:%SZ').timetuple());
		date = int(time.time());
		bz = 1;
		
		sql = "SELECT COUNT(1) `count` FROM pm2_5_data2014 WHERE time_point='%s'" % time_point;
		cursor.execute(sql);
		conn.commit();
		count = cursor.fetchone()[0];
		if(count >= 1):
			break;
		
		columns = "aqi,cityCode,`area`,cityName,spellName,co,co_24h,no2,no2_24h,o3,o3_24h,o3_8h,o3_8h_24h,pm10,pm10_24h,pm2_5,pm2_5_24h,so2,so2_24h,primary_pollutant,quality,station_code,position_name,time_point,publishDate,`date`,bz";
		values = "%d,'%s','%s','%s','%s',%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s','%s','%s','%s',%d,%d,%d" % (aqi,cityCode,area,cityName,spellName,co,co_24h,no2,no2_24h,o3,o3_24h,o3_8h,o3_8h_24h,pm10,pm10_24h,pm2_5,pm2_5_24h,so2,so2_24h,primary_pollutant,quality,station_code,position_name,time_point,publishDate,date,bz);
		sql = "insert into %s(%s) values (%s)" % (tableName,columns,values);
		sqlstring = "insert into %s(%s) values (%s);\n" % (tableName,columns,values);
		#file.write(sqlstring);
		#saveStation(station_code, position_name, cityName, spellName);
		cursor.execute(sql.encode("utf-8"));
		conn.commit();
		
	file.close();
	cursor.close();
	conn.close();
	
def saveStation(station_code, station_name, cityName, spellName):
	'''saveStation'''
	
	cursor = conn.cursor();
	
	tableName = "pm2_5_station";
	
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	saveFileName = "insert_station.sql";
	file = codecs.open(saveFileName, "w", 'utf-8');
	
	cityCode = "";
	date = int(time.time());
	bz = 1;
	
	columns = "station_code,station_name,cityCode,cityName,spellName,`date`,bz";
	values = "'%s','%s','%s','%s','%s',%d,%d" % (station_code,station_name,cityCode,cityName,spellName,date,bz);
	sql = "insert into %s(%s) values (%s)" % (tableName,columns,values);
	sqlstring = "insert into %s(%s) values (%s);\n" % (tableName,columns,values);
	file.write(sqlstring);
	cursor.execute(sql.encode("utf-8"));
	conn.commit();
		
	file.close();
	
def getCities():
	'''getCities'''
	
	cursor = conn.cursor();
	
	tableName = "pm2_5_cities";
	
	cursor.execute("truncate table %s" % tableName);
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	saveFileName = "insert_cities.sql";
	file = codecs.open(saveFileName, "w", 'utf-8');
	
	fileName = "cities.json";
	jsons = readJson(fileName);
	if(type(jsons) == DictionaryType and jsons.has_key("error")):
		print "no data";
		return;
	cities = jsons["cities"];
	
	p = Pinyin();
	
	for city in cities:
		cityCode = "";
		cityName = city;
		spellName = p.get_pinyin(cityName, '');
		date = int(time.time());
		bz = 1;
		
		columns = "cityCode,cityName,spellName,`date`,bz";
		values = "'%s','%s','%s',%d,%d" % (cityCode,cityName,spellName,date,bz);
		sql = "insert into %s(%s) values (%s)" % (tableName,columns,values);
		sqlstring = "insert into %s(%s) values (%s);\n" % (tableName,columns,values);
		file.write(sqlstring);
		cursor.execute(sql.encode("utf-8"));
		conn.commit();
		
	file.close();
	cursor.close();
	conn.close();
	
def getDatetime(post_date):
	year = 0;
	month = 0;
	day = 0;
	
	date = string.split(post_date, "-");
	year = int(date[0]);
	month = int(date[1]);
	day = int(date[2]);
	
	if(string.find(str(month), "0") == 0):
		month = int(month[1:]);
	if(string.find(str(day), "0") == 0):
		day = int(day[1:]);
	
	date_time = datetime.datetime(year, month, day);
	return date_time;
	
def getDate(post_date):
	year = 0;
	month = 0;
	day = 0;
	
	date = string.split(post_date, "-");
	year = int(date[0]);
	month = int(date[1]);
	day = int(date[2]);
	
	if(string.find(str(month), "0") == 0):
		month = int(month[1:]);
	if(string.find(str(day), "0") == 0):
		day = int(day[1:]);
	
	return {
		'year': year,
		'month': month,
		'day': day
	};
			
def readFile(filePath):
	f = file(filePath, "r");
	content = "";
	while True:
		line = f.readline();
		if(len(line) == 0):
			break;
		content += line;
	f.close();
	return content;
	
if __name__ == "__main__":
	methodName = sys.argv[1];
	if(methodName == "sayHello"):
		sayHello();
	elif(methodName == "test"):
		test();
	elif(methodName == "testUrl"):
		testUrl();
	elif(methodName == "readJson"):
		sourceType = 1;
		if(len(sys.argv) > 2):
			sourceType = int(sys.argv[2]);
		if(sourceType == 1):
			fileName = "all_cities.json";
		else:
			fileName = "http://www.pm25.in/api/querys/all_cities.json?token=5j1znBVAsnSf5xQyNQyq";
		readJson(fileName)# if http url else file
	elif(methodName == "getAllData"):
		sourceType = 1;
		if(len(sys.argv) > 2):
			sourceType = int(sys.argv[2]);
		if(sourceType == 1):
			fileName = "all_cities.json";
		else:
			fileName = "http://www.pm25.in/api/querys/all_cities.json";
		getAllData(fileName);
	elif(methodName == "getCities"):
		getCities();