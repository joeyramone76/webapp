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
	f = codecs.open("insert_menus.sql", "w", "utf-8")
	getMenus(f, menus, 1, "");
	f.close();
		
def getMenus(file, menus, level, parentCode):
	sql = "";
	menu_code = 1;
	menu_codestring = "";
	menu_name = "";
	menu_showName = "";
	type = 1; # 1 - page 2 - news
	icon = "";
	url = "";
	sl_url = "";
	parentId = 0;
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
		type = 1;
		if(menu_name == "news"):
			type = 2;
		if(len(submenus) == 0):
			if(level == 1):
				menu_codestring = string.zfill(menu_code, 3);
			else:
				menu_codestring = parentCode + string.zfill(menu_code, 3);
			parentId = 0;
			hasSubMenu = 0;
			#sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES (?,?,?,?,?,?,?,?,?,?)";
			sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES ('%s','%s','%s',%d,'%s','%s','%s',%d,%d,%d);\n" % (menu_codestring,menu_name,menu_showName,type,icon,url,sl_url,parentId,hasSubMenu,date);
			print sql;
			file.write(sql);
		else:
			if(level == 1):
				menu_codestring = string.zfill(menu_code, 3);
			else:
				menu_codestring = parentCode + string.zfill(menu_code, 3);
			parentId = 0;
			hasSubMenu = 1;
			url = "";
			sl_url = "";
			#sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES (?,?,?,?,?,?,?,?,?,?)";
			sql = "INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES ('%s','%s','%s',%d,'%s','%s','%s',%d,%d,%d);\n" % (menu_codestring,menu_name,menu_showName,type,icon,url,sl_url,parentId,hasSubMenu,date);
			print sql;
			file.write(sql);
			level += 1;
			getMenus(file, submenus, level, menu_codestring);
		menu_code += 1;
			
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
		readJson();