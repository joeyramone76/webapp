# -*- coding: UTF-8 -*-
#安装MYSQL DB for python
import sys
import os
import MySQLdb as mdb
import datetime
import time
import SearchFile
import re
import string;

conn = None;

def sayHello(argv=None):
	print sys.argv;
	print len(sys.argv);
	print sys.argv[:];
	print sys.path;
	
def test():
	try:
		#连接mysql方法: connect('ip','user','password','dbname')
		conn = mdb.connect('localhost', 'root', 'root', 'shenglong-electricv');
		
		#所有的查询，都在连接con的一个模块cursor上面运行的
		cur = conn.cursor();
		
		#执行一个查询
		cur.execute("select version()");
		
		#取得上个查询的结果，是单个结果
		data = cur.fetchone();
		print "Database verson : %s " % data
		
		# execute SQL select statement
		cur.execute("select * from weather_citys");
		# commit your changes
		conn.commit();
		
		# get the number of rows in the resultset
		numrows = int(cur.rowcount)
		
		# get and display one row at a time
		for x in range(0, numrows):
			row = cur.fetchone()
			print row
			
		cur.execute("select cityCode from weather_citys");
		for row in cur.fetchall():
			print row[0]
	finally:
		if conn:
			#无论如何，连接记得关闭
			conn.close();
			
def update():
	print "update";
	files = searchHtmlFile();
	for filePath in files:
		print filePath;
		content = readFile(filePath);
		
		#./css href="./css
		content = replace(filePath, content, r'(href=")\./(css)');
		#./favicon
		content = replace(filePath, content, r'(href=")\./(favicon)');
		#./js
		content = replace(filePath, content, r'(src=")\./(js)');
		#./images
		content = replace(filePath, content, r'(src=")\./(images)');
		#./uploads
		content = replace(filePath, content, r'(src=")\./(uploads)');
		#./imgGallery
		content = replace(filePath, content, r'(src=")\./(imgGallery)');
		
		#href="/"
		prefixPath = getPrefixPath(filePath);
		rgx = re.compile(r'(href=")/(")');
		content = rgx.sub('\\1'+prefixPath+'/index.html\\2', content);
		
		#href="/aboutMe/detail/page_id/13"
		prefixPath = getPrefixPath(filePath);
		rgx = re.compile(r'(href=")(/[\w|/]+)(")');
		content = rgx.sub('\\1'+prefixPath+'\\2.html\\3', content);
		
		writeFile(filePath, content);
	
def searchHtmlFile():
	print "searchHtmlFile";
	searchFile = SearchFile.SearchFile("m.shenglong-electric.com.cn/", ".html");
	files = searchFile.getAllFiles();
	newFiles = [];
	for filePath in files:
		filePath = string.replace(filePath, "/", "\\");
		newFiles.append(filePath);
	return newFiles;

def testUpdate():
	print "testUpdate";
	#filePath = "m.shenglong-electric.com.cn\\aboutMe.html";
	filePath = "m.shenglong-electric.com.cn\\aboutMe\\detail\\page_id\\13.html";
	content = readFile(filePath);
	#正则匹配 路径
	#.    匹配除换行符以外的任意字符
	#^    匹配字符串的开始
	#$    匹配字符串的结束
	#[]   用来匹配一个指定的字符类别
	#？   对于前一个字符字符重复0次到1次
	#*    对于前一个字符重复0次到无穷次
	#{}   对于前一个字符重复m次
	#{m，n} 对前一个字符重复为m到n次
	#\d   匹配数字，相当于[0-9]
	#\D   匹配任何非数字字符，相当于[^0-9]
	#\s   匹配任意的空白符，相当于[ fv]
	#\S   匹配任何非空白字符，相当于[^ fv]
	#\w   匹配任何字母数字字符，相当于[a-zA-Z0-9_]
	#\W   匹配任何非字母数字字符，相当于[^a-zA-Z0-9_]
	#\b   匹配单词的开始或结束
	#href="/"
	#href="/aboutMe/detail/page_id/13"
	#match = re.search(r'href="/"', content);
	#match = re.match(r'href="/"', content);
	
	#src = 'aabcdddd'
	#print re.sub('(ab).*(d)', '\\1e\\2', src)
	#src  = 'aabcdddd'
	#rgx = re.compile('(?<=ab).*?(?=d)')
	#print rgx.sub('e',src)
	src  = 'aabcdddd'
	rgx = re.compile(r'(ab)(.*?)(d)')
	print rgx.sub(r'\1\2\3', src)

	match = re.findall(r'href="/[\w|/]*"', content);
	if(match):
		print match;
	
	#./css href="./css
	content = replace(filePath, content, r'(href=")\./(css)');
	#./favicon
	content = replace(filePath, content, r'(href=")\./(favicon)');
	#./js
	content = replace(filePath, content, r'(src=")\./(js)');
	#./images
	content = replace(filePath, content, r'(src=")\./(images)');
	#./uploads
	content = replace(filePath, content, r'(src=")\./(uploads)');
	#./imgGallery
	content = replace(filePath, content, r'(src=")\./(imgGallery)');
	
	#href="/"
	prefixPath = getPrefixPath(filePath);
	rgx = re.compile(r'(href=")/(")');
	content = rgx.sub('\\1'+prefixPath+'/index.html\\2', content);
	
	#href="/aboutMe/detail/page_id/13"
	prefixPath = getPrefixPath(filePath);
	rgx = re.compile(r'(href=")(/[\w|/]+)(")');
	content = rgx.sub('\\1'+prefixPath+'\\2.html\\3', content);
	#print content;
	
	writeFile(filePath, content);
	
def replace(filePath, content, strPattern):
	prefixPath = getPrefixPath(filePath);
	rgx = re.compile(strPattern);
	content = rgx.sub('\\1'+prefixPath+'/\\2', content);
	return content;
	
def getPrefixPath(filePath):
	'''获得url前缀'''
	count = string.count(filePath, "\\");
	prefixPath = "";
	if(count == 1):
		prefixPath = "./";
	else:
		for i in range(1, count):
			prefixPath += "../";
	prefixPath = prefixPath[:len(prefixPath) - 1];
	return prefixPath;
	
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

def writeFile(filePath, content):
	f = file(filePath, "w");
	f.write(content);
	f.close();
	
#将conn设定为全局连接
conn = mdb.connect('localhost', 'root', 'root', 'shenglong-electricv');
def insertData():
	print "insertData";
	try:
		file = open("citys.txt", "r");# w a wb二进制
		
		cursor = conn.cursor();
		
		sql = "truncate table weather_citys";
		cursor.execute(sql);
		cursor.execute("SET NAMES utf8");
		cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
		cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
		conn.commit();
		
		fileList = file.readlines();
		p = Pinyin();
		date = int(time.mktime(datetime.datetime.now().timetuple()));
		bz = 1;
		for fileLine in fileList:
			cityInfo = fileLine.split("=");
			cityCode = cityInfo[0];
			cityName = cityInfo[1];
			spellName = p.get_pinyin(cityName.decode("utf-8"), '');
			sql = "insert into weather_citys(cityCode,cityName,spellName,date,bz) values ('%s','%s','%s','%s','%s')" % (cityCode,cityName,spellName.encode("utf-8"),date,bz);
			cursor.execute(sql);
			conn.commit();

		file.close();
		cursor.close();
		conn.close();
	except (mdb.Error, IOError), e:
		print "Error %d: %s" % (e.args[0], e.args[1]);
		sys.exit(1);
		
def export():
	print "export";
	try:
		file = open("citys.json", "w");# w a wb二进制
		
		cursor = conn.cursor();
			
		cursor.execute("SET NAMES utf8");
		cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
		cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
		sql = "SELECT cityCode,cityName,spellName FROM weather_citys";
		cursor.execute(sql);
		file.write("[{\n");
		i = 1;
		numrows = int(cursor.rowcount);
		info = "";
		for row in cursor.fetchall():
			cityCode = row[0];
			cityName = row[1];
			spellName = row[2];
			info = "\tcityCode:" + cityCode + ",\n";
			info += "\tcityName:" + cityName + ",\n";
			info += "\tspellName:" + spellName + "\n";
			if i < numrows:
				info += "}, {\n";
			i = i + 1;
			file.write(info);
			
		file.write("}]");
		file.close();	
		cursor.close();
		conn.close();
	except (mdb.Error, IOError), e:
		print "Error %d: %s" % (e.args[0], e.args[1]);
		sys.exit(1);

if __name__ == "__main__":
	methodName = sys.argv[1];
	if(methodName == "sayHello"):
		sayHello();
	elif(methodName == "test"):
		test();
	elif(methodName == "update"):
		update();
	elif(methodName == "searchHtmlFile"):
		searchHtmlFile();
	elif(methodName == "testUpdate"):
		testUpdate();
	elif(methodName == "getPrefixPath"):
		print getPrefixPath("\\\\");