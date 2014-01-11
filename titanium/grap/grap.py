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
import json;
import time;
import math;
import codecs;

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
	
def getMenus(menus):
	print menus;
	
#将conn设定为全局连接
conn = mdb.connect('localhost', 'root', 'root', 'shenglong-electricv');
def readJson():
	jsonstring = readFile('json/menus.json');
	jsonstring = jsonstring.replace('\t', '').replace('\n', '');
	menus = json.loads(jsonstring);
	#json.loads(jsonstring, object_hook=getMenus);
	
	#['__add__', '__class__', '__contains__', '__delattr__', '__delitem__', '__delslice__',
	#'__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getitem__',
	#'__getslice__', '__gt__', '__hash__', '__iadd__', '__imul__', '__init__',
	#'__iter__', '__le__', '__len__', '__lt__', '__mul__', '__ne__', '__new__', '__reduce__',
	#'__reduce_ex__', '__repr__', '__reversed__', '__rmul__', '__setattr__',
	#'__setitem__', '__setslice__', '__sizeof__', '__str__', '__subclasshook__',
	#'append', 'count', 'extend', 'index', 'insert', 'pop', 'remove', 'reverse', 'sort'
	#]
	print type(menus);
	#f = file("insert_menus.sql", "a+");
	cursor = conn.cursor();
	sql = "truncate table app_menus";
	cursor.execute(sql);
	conn.commit();
	
	f = codecs.open("insert_menus.sql", "w", "utf-8")
	getMenus(f, menus, 1, 0, "");
	
	f.close();
	cursor.close();
	conn.close();
		
def getMenus(file, menus, level, parentId, parentCode):
	sql = "";
	menu_code = 1;
	menu_codestring = "";
	menu_name = "";
	menu_showName = "";
	type = 0; # 1 - page 2 - news
	icon = "";
	url = "";
	sl_url = "";
	hasSubMenu = 1; # 0 - 没有 1 - 有
	date = int(time.time());
	submenus = [];
		
	for menu in menus:
		menu_name = menu["name"];
		menu_showName = menu["showName"];
		icon = menu["icon"];
		url = menu["url"];
		sl_url = menu["url"];
		submenus = menu["submenus"];
		
		hasSubMenu = 1;
		type = 0;
		if(len(submenus) == 0):
			type = 1;
			if(parentCode == "002"):
				type = 2;
			if(level == 1):
				menu_codestring = string.zfill(menu_code, 3);
			else:
				menu_codestring = parentCode + string.zfill(menu_code, 3);
			hasSubMenu = 0;
			#sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES (?,?,?,?,?,?,?,?,?,?)";
			sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,parentCode,hasSubMenu,`date`) VALUES ('%s','%s','%s',%d,'%s','%s','%s',%d,'%s',%d,%d);\n" % (menu_codestring,menu_name,menu_showName,type,icon,url,sl_url,parentId,parentCode,hasSubMenu,date);
			
			print sql;
			file.write(sql);
		else:
			if(level == 1):
				menu_codestring = string.zfill(menu_code, 3);
			else:
				menu_codestring = parentCode + string.zfill(menu_code, 3);
			hasSubMenu = 1;
			url = "";
			sl_url = "";
			#sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES (?,?,?,?,?,?,?,?,?,?)";
			sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,parentCode,hasSubMenu,`date`) VALUES ('%s','%s','%s',%d,'%s','%s','%s',%d,'%s',%d,%d);\n" % (menu_codestring,menu_name,menu_showName,type,icon,url,sl_url,parentId,parentCode,hasSubMenu,date);
			print sql;
			file.write(sql);
			level += 1;
			getMenus(file, submenus, level, parentId, menu_codestring);
		menu_code += 1;
		
def grap_content(type):
	'''grap_page'''
	sql = "SELECT id,sl_url FROM app_menus WHERE type=%d" % type;
	
	cursor = conn.cursor();
	
	if(type == 1):
		cursor.execute("truncate table app_pages");
	else:
		cursor.execute("truncate table app_news");
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	cursor.execute(sql);
	
	fileName = "";
	if(type == 1):
		fileName = "insert_pages.sql";
	else:
		fileName = "insert_news.sql";
	file = codecs.open(fileName, "w", 'utf-8');
	
	id = 0;
	sl_url = "";
	columnName = "";
	if(type == 1):
		columnName = "pageId";
	else:
		columnName = "sl_cid";
	sl_content_id = 0;
	title = "";
	imagePrefix = "http://m.shenglong-electric.com.cn";
	image = "";
	content = "";
	post_date = "";
	post_time = 0;
	date = int(time.time());
	
	postDate = "";
	
	tableName = "";
	for row in cursor.fetchall():
		id = row[0];
		sl_url = row[1];
		
		# http://m.shenglong-electric.com.cn/aboutMe/detail/page_id/13
		sl_content_id = int(sl_url[string.rfind(sl_url, "/") + 1:]);
		sql = "update app_menus set %s='%d' where id=%d" % (columnName, sl_content_id, id);
		print sql;
		cursor.execute(sql);
		conn.commit();
		
		if(type == 1):
			page = get_page(sl_url);
			title = page["title"];
			content = page["content"];
			post_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S');
			post_time = date;
			sql = "insert into app_pages(sl_page_id,title,image,content,post_date,post_time,date) values (%d,'%s','%s','%s','%s',%d,%d)" % (sl_content_id,title,image,content,post_date,post_time,date);
			sqlstring = "insert into app_pages(sl_page_id,title,image,content,post_date,post_time,date) values (%d,'%s','%s','%s','%s',%d,%d);\n" % (sl_content_id,title,image,content,post_date,post_time,date);
			file.write(sqlstring.decode('utf-8'));
			cursor.execute(sql);
			conn.commit();
		else:
			newslist = get_newslist(sl_url);
			sl_cid = sl_content_id;
			for news in newslist:
				sl_url = news["sl_url"];
				title = news["title"];
				image = news["image"];
				content = news["content"];
				sl_news_id = news["sl_news_id"];
				post_date = news["post_date"];
				post_desc = news["post_desc"];
				page = news["page"];
				date_time = getDatetime(post_date);
				post_time = time.mktime(date_time.timetuple());
				date = int(time.time());
				sql = "insert into app_news(sl_cid,sl_news_id,sl_url,title,image,content,post_desc,page,post_date,post_time,date) values (%d,%d,'%s','%s','%s','%s','%s',%d,'%s',%d,%d)" % (sl_cid,sl_news_id,sl_url,title,image,content,post_desc,page,post_date,post_time,date);
				sqlstring = "insert into app_news(sl_cid,sl_news_id,sl_url,title,image,content,post_desc,page,post_date,post_time,date) values (%d,%d,'%s','%s','%s','%s','%s',%d,'%s',%d,%d);\n" % (sl_cid,sl_news_id,sl_url,title,image,content,post_desc,page,post_date,post_time,date);
				#file.write(sqlstring.decode('utf-8'));
				cursor.execute(sql);
				conn.commit();
		
	file.close;
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
	
def get_page(url):
	html = urllib2.urlopen(url).read();
	page = {
		'title': '',
		'content': '',
		'post_date': ''
	};
	
	#title
	
	#content
	#<div class="page_content clearfix">
	content = "";
	pattern = re.compile(r'<div class="page_content.*?">(.*?)</div>', re.S);
	match = pattern.search(html);
	
	if(match):
		content = match.group(1);
		content = content.replace("\n", "").replace("\t", "").replace("    ", "");
		#src="/uploads/20130226/13618602745625.jpg"
		imagePrefix = "http://m.shenglong-electric.com.cn";
		pattern = re.compile(r'(src=")/(uploads)');
		content = pattern.sub('\\1' + imagePrefix + '/\\2', content);
		page["content"] = content;
		
	#post_date
	
	return page;
	
def get_newslist(url):
	#http://m.shenglong-electric.com.cn/news/dirlist/cid/7
	html = urllib2.urlopen(url).read();
	newslist = [];
	
	page = get_newspage(html);
	for i in range(0, page):
		#http://m.shenglong-electric.com.cn/news/dirlist/cid/7/page/1
		newslist_url = url + "/page/" + str(i + 1);
		print newslist_url;
		html = urllib2.urlopen(newslist_url).read();
		news_urls = get_newsurls(html);
		for news_url in news_urls:
			news_urlstring = news_url["url"];
			print news_urlstring;
			image = news_url["image"];
			post_desc = news_url["post_desc"];
			news = get_news(news_urlstring);
			sl_news_id = int(news_urlstring[string.rfind(news_urlstring, "/") + 1:]);
			newslist.append({
				'title': news['title'],
				'image': image,
				'content':  news['content'],
				'post_date':  news['post_date'],
				'sl_url':  news['sl_url'],
				'sl_news_id': sl_news_id,
				'post_desc': post_desc,
				'page': int(i + 1)
			});
	
	return newslist;
	
def get_newspage(content):
	page = 0;
	pattern = re.compile(r'<ul id="yw0" class="yiiPager">.*?<li class="last">.*?page/(\d)">.*?</li></ul>', re.S);
	match = pattern.search(content);
	if(match):
		page = match.group(1);
	return int(page);
	
def get_newsurls(content):
	urls = [];
	
	url = "";
	imagePrefix = "http://m.shenglong-electric.com.cn";
	image = "";
	post_desc = "";
	
	pattern = re.compile(r'<div class="post_item.*?">(.*?)</div>', re.S);
	post_items = pattern.findall(content);
	for post_item in post_items:
		#url
		pattern = re.compile(r'<a href="(.*?)"', re.S);
		match = pattern.search(post_item);
		if(match):
			url = imagePrefix + match.group(1);
		
		#image
		pattern = re.compile(r'<img src="(.*?)"', re.S);
		match = pattern.search(post_item);
		if(match):
			image = imagePrefix + match.group(1);
		
		#post_desc
		pattern = re.compile(r'<p class="post_desc">(.*?)</p>', re.S);
		match = pattern.search(post_item);
		if(match):
			post_desc = match.group(1);
		#index = None;
		#if(post_desc.rfind("。") >= 0):
		#	index = post_desc.rfind("。");
		#post_desc = post_desc[0:index];
		
		urls.append({
			'url': url,
			'image': image,
			'post_desc': post_desc
		});
	return urls;
	
def get_news(url):
	html = urllib2.urlopen(url).read();
	news = {
		'title': '',
		'content': '',
		'post_date': '',
		'sl_url': url,
		'post_desc': ''
	};
	
	#title
	#<h1>合作共赢——施耐德全球财务总裁访问盛隆电气</h1>
	title = "";
	post_title = "";
	pattern = re.compile(r'<div class="post_title">(.*?)</div>', re.S);
	match = pattern.search(html);
	if(match):
		post_title = match.group(1);
		
	match = re.search(r'<h1>(.*?)</h1>', post_title, re.S);
	if(match):
		title = match.group(1);
	news["title"] = title;
	
	#post_date
	#<p class="post_date">( 2013-10-15 )</p>
	post_date = "";
	match = re.search(r'<p class="post_date">\( (\d+-\d+-\d+) \)</p>', post_title, re.S);
	if(match):
		post_date = match.group(1);
	news["post_date"] = post_date;
	
	#content
	#<div class="post_content"></div>
	content = "";
	pattern = re.compile(r'<div class="post_content.*?">(.*?)</div>', re.S);
	match = pattern.search(html);
	
	if(match):
		content = match.group(1);
		content = content.replace("\n", "").replace("\t", "").replace("    ", "").replace("\r", "");
		content = content.strip();
		imagePrefix = "http://m.shenglong-electric.com.cn";
		pattern = re.compile(r'(src=")/(uploads)');
		content = pattern.sub('\\1' + imagePrefix + '/\\2', content);
		news["content"] = content;
	
	return news;
	
def getPostDesc(content):
	'''
	获取第一个p标签的内容
	<p><span></span></p>span最多三层
	'''
	post_desc = "";
	pattern = re.compile(r'<p>(.*?)</p>');
	match = pattern.search(content);
	_content = "";
	if(match):
		_content = match.group(1);
	return post_desc;
	
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
	
def addMenus():
	cursor = conn.cursor();
	sql = "truncate table app_menus";
	cursor.execute(sql);
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	sql = "";
	cursor.execute(sql.encode('utf-8'));
	conn.commit();
	
	cursor.close();
	conn.close();
			
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
	
def exportMenus():
	'''导出菜单'''
	fileName = "menus.txt";
	f = file(fileName, "w");
	#f = codecs.open(fileName, "w", 'utf-8');
	
	cursor = conn.cursor();
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	sql = "SELECT id,menu_code,menu_name,menu_showName,`type`,icon,banner,url,sl_url,parentId,parentCode,pageId,newsId,sl_cid FROM app_menus WHERE parentCode=''";
	
	cursor.execute(sql);
	id = 0;
	menu_code = "";
	menu_name = "";
	menu_showName = "";
	type = 0;
	icon = "";
	banner = "";
	url = "";
	sl_url = "";
	parentId = 0;
	parentCode = "";
	pageId = 0;
	newsId = 0;
	sl_cid = 0;
	
	menus = [];
	menu = {
		'id': id,
		'menu_code': menu_code,
		'menu_name': menu_name,
		'menu_showName': menu_showName,
		'type': type,
		'icon': icon,
		'banner': banner,
		'url': url,
		'sl_url': sl_url,
		'parentId': parentId,
		'parentCode': parentCode,
		'pageId': pageId,
		'newsId': newsId,
		'sl_cid': sl_cid,
		'submenus': []
	};
	for row in cursor.fetchall():
		menu = {
			'id': row[0],
			'menu_code': row[1],
			'menu_name': row[2],
			'menu_showName': row[3],
			'type': row[4],
			'icon': row[5],
			'banner': row[6],
			'url': row[7],
			'sl_url': row[8],
			'parentId': row[9],
			'parentCode': row[10],
			'pageId': row[11],
			'newsId': row[12],
			'sl_cid': row[13],
			'submenus': []
		};
		
		addSubmenu(menu);
		menus.append(menu);
		
	f.write(json.dumps(menus, sort_keys=True, indent=4, separators=(',', ': ')));
	
	f.close();
	cursor.close();
	conn.close();
	
def addSubmenu(menu):
	cursor = conn.cursor();
	cursor.execute("SET NAMES utf8");
	cursor.execute("SET CHARACTER_SET_CLIENT=utf8");
	cursor.execute("SET CHARACTER_SET_RESULTS=utf8");
	conn.commit();
	
	sql = "SELECT id,menu_code,menu_name,menu_showName,`type`,icon,banner,url,sl_url,parentId,parentCode,pageId,newsId,sl_cid FROM app_menus WHERE parentCode='%s'" % menu["menu_code"];
	
	cursor.execute(sql);
	
	id = 0;
	menu_code = "";
	menu_name = "";
	menu_showName = "";
	type = 0;
	icon = "";
	banner = "";
	url = "";
	sl_url = "";
	parentId = 0;
	parentCode = "";
	pageId = 0;
	newsId = 0;
	sl_cid = 0;
	
	submenus = [];
	submenu = {
		'id': id,
		'menu_code': menu_code,
		'menu_name': menu_name,
		'menu_showName': menu_showName,
		'type': type,
		'icon': icon,
		'banner': banner,
		'url': url,
		'sl_url': sl_url,
		'parentId': parentId,
		'parentCode': parentCode,
		'pageId': pageId,
		'newsId': newsId,
		'sl_cid': sl_cid,
		'submenus': []
	};
	for row in cursor.fetchall():
		submenu = {
			'id': row[0],
			'menu_code': row[1],
			'menu_name': row[2],
			'menu_showName': row[3],
			'type': row[4],
			'icon': row[5],
			'banner': row[6],
			'url': row[7],
			'sl_url': row[8],
			'parentId': row[9],
			'parentCode': row[10],
			'pageId': row[11],
			'newsId': row[12],
			'sl_cid': row[13],
			'submenus': []
		};
		
		sql = "SELECT COUNT(1) `count` FROM app_menus WHERE parentCode='%s'" % submenu["menu_code"];
		cur = conn.cursor()
		cur.execute(sql);
		row = cur.fetchone();
		count = row[0];
		cur.close();
		if(count > 0):
			addSubmenu(submenu);
		submenus.append(submenu);
		
	menu["submenus"] = submenus;
		
	cursor.close();
	
if __name__ == "__main__":
	methodName = sys.argv[1];
	if(methodName == "sayHello"):
		sayHello();
	elif(methodName == "test"):
		test();
	elif(methodName == "testUrl"):
		testUrl();
	elif(methodName == "readJson"):
		readJson();
	elif(methodName == "grap_content"):
		if(len(sys.argv) > 2):
			type = sys.argv[2];
		else:
			type = 2;
		grap_content(type);
	elif(methodName == "exportMenus"):
		exportMenus();