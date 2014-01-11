# -*- coding: UTF-8 -*-
import urllib;
import urllib2;
from urllib2 import Request, urlopen, URLError, HTTPError;
import socket;
import cookielib

socket.setdefaulttimeout(10);# 10秒后超时
urllib2.socket.setdefaulttimeout(10);

#request
req = urllib2.Request('http://www.baidu.com');
response = urllib2.urlopen(req);
the_page = response.read();
print the_page;

#post
url = 'http://www.baidu.com';
values = {
	'name': 'WHY',
	'location': 'SDU',
	'language': 'Python'
};
data = urllib.urlencode(values);
req = urllib2.Request(url, data);
response = urllib2.urlopen(req);
the_page = response.read();
print the_page;

#get
data = {};
data['name'] = 'WHY';
data['location'] = 'SDU';
data['language'] = 'Python';

url_values = urllib.urlencode(data);
print url_values;

url = 'http://www.baidu.com';
full_url = url + "?" + url_values;
data = urllib2.urlopen(full_url);
print data.read();

#e.reason
req = urllib2.Request('http://www.test1.com');
try:
	urllib2.urlopen(req);
except urllib2.URLError, e:
	print e.reason;
	
#e.code
req = urllib2.Request('http://www.google.com/test');
try:
	urllib2.urlopen(req);
except urllib2.URLError, e:
	print e.code;
	
#exception
req = urllib2.Request('http://www.google.com/test');
try:
	response = urllib2.urlopen(req);
except urllib2.HTTPError, e:
	print 'The server couldn\'t fulfill the request';
	print 'Error code: ', e.code
except urllib2.URLError, e:
	print 'We failed to reach a server';
	print 'Reason: ', e.reaon
else:
	print 'No exception was raised.'
	
#exception
req = urllib2.Request('http://www.google.com/test');
try:
	response = urllib2.urlopen(req);
except urllib2.URLError, e:
	if(hasattr(e, 'reason')):
		print 'We failed to reach a server';
		print 'Reason: ', e.reason;
	elif(hasattr(e, 'code')):
		print 'The server couldn\'t fulfill the request';
		print 'Error code: ', e.code;
else:
	print 'No exception was raised.';
	
#geturl
old_url = 'http://rrurl.cn/b1UZuP';
req = Request(old_url);
response = urlopen(req);
print 'Old url: ' + old_url;
print 'Real url: ' + response.geturl();
#getinfo
url = 'http://www.baidu.com';
req = Request(old_url);
response = urlopen(req, timeout=10);
print 'Info():'
print response.info();

def opener():
	#Openers Handlers
	#创建一个密码管理者
	password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm();

	#添加用户名和密码
	top_level_url = "http://example.com/foo/"

	password_mgr.add_password(None, top_level_url, '123', '1223');

	#创建一个新的handler
	handler = urllib2.HTTPBasicAuthHandler(password_mgr);
	#创建Opener(OpenerDirector实例)
	opener = urllib2.build_opener(handler);

	a_url = 'http://www.baidu.com';

	#使用opener获取一个URL
	opener.open(a_url);

	#安装opener
	#现在所有调用urllib2.urlopen将用我们的opener
	urllib2.install_opener(opener);
	
def proxy():
	enable_proxy = True;
	proxy_handler = urllib2.ProxyHandler({"https": 'https://192.168.1.20:808'});
	null_proxy_handler = urllib2.ProxyHandler({});
	if(enable_proxy):
		opener = urllib2.build_opener(proxy_handler);
	else:
		opener = urllib2.build_opener(null_proxy_handler);
	urllib2.install_opener(opener);

	response = urllib2.urlopen('https://www.facebook.com');
	html = response.read();
	print html;
	
#header
request = urllib2.Request('http://www.baidu.com');
request.add_header('User-Agent', 'peter-client');
response = urllib2.urlopen(request);
print response.read();
#Content-Type:application/xml application/json application/x-www-form-urlencoded

#Redirect
url = 'http://www.google.cn';
response = urllib2.urlopen(url);
redirected = response.geturl() == url;
print redirected;

class RedirectHandler(urllib2.HTTPRedirectHandler):
	def http_error_301(self, req, fp, code, msg, headers):
		print "301";
		pass;
	def http_error_302(self, req, fp, code, msg, headers):
		print "303";
		pass;

#opener = urllib2.build_opener(RedirectHandler);
#opener.open('http://rrurl.cn/b1UZuP');

cookie = cookielib.CookieJar();
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookie));
response = opener.open('http://www.baidu.com');
for item in cookie:
	print 'Name = ' + item.name;
	print 'Value = ' + item.value;
	
def put():
	# PUT DELETE
	request = urllib2.Request(uri, data=data);
	request.get_method = lambda: 'PUT' # or 'DELETE'
	response = urllib2.urlopen(request);

# code
try:
	response = urllib2.urlopen('http://www.google.com/test');
except urllib2.HTTPError, e:
	print e.code;
	
httpHandler = urllib2.HTTPHandler(debuglevel=1);
httpsHandler = urllib2.HTTPSHandler(debuglevel=1);
opener = urllib2.build_opener(httpHandler, httpsHandler);
urllib2.install_opener(opener);
response = urllib2.urlopen('http://www.google.com');

# 表单处理
postData = urllib.urlencode({
	'username': 'test',
	'password': 'test',
	'continueURI': 'http://www.verycd.com',
	'fk': '',
	'login_submit': 'login'
});
headers = {
	'User-Agent': 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6'
};
req = urllib2.Request(
	url = 'http://secure.verycd.com/signin',
	data = postData,
	headers = headers
);
result = urllib2.urlopen(req);
print result.read();

#'Referer':'http://www.baidu.com'
#'X-Forwarded-For':''