import urllib2;
import re;
import os;

dir(re);

def search():
	#re.search 函数会在字符串内查找模式匹配，只到找到第一个匹配然后返回，如果字符串没有匹配，则返回None
	help(re.search);
	#search(pattern, string, flags=0);
	#第一个参数：规则
	#第二个参数：表示要匹配的字符串
	#第三个参数：标致位，用于控制正则表达式的匹配方式

	name = "Hello,My name is python,nice to meet you..."
	k = re.search(r'p(yth)on', name);
	if(k):
		print k.group(0),k.group(1);
	else:
		print "Sorry,not search!";
	
def match():
	#re.match 尝试从字符串的开始匹配一个模式，也等于说是匹配第一个单词
	help(re.match)
	#match(pattern, string, flags=0);
	name = "Hello,My name is python,nice to meet you..."
	k = re.match(r'\H....', name);
	if(k):
		print k.group(0),'\n',k.group(1);
	else:
		print "Sorry,not match!";
	#Hello
	#re.match与re.search的区别：re.match只匹配字符串的开始，如果字符串开始不符合正则表达式，则匹配失败，函数返回None；而re.search匹配整个字符串，直到找到一个匹配
	
def findall():
	#re.findall 在目标字符串查找符合规则的字符串
	help(re.findall)
	#findall(pattern, string, flags=0);
	#返回的结果是一个列表，建中存放的是符合规则的字符串，如果没有符合规则的字符串呗找到，就会返回一个空值
	mail = '<user01@mail.com> <user02@mail.com> user04@mail.com';
	re.findall(r'(\w+@m....[z-a]{3})', mail);
	#['user01@mail.com', 'user02@mail.com', 'user04@mail.com']

def sub():
	#re.sub 用于替换字符串的匹配项
	help(re.sub)
	#sub(pattern, repl, string, count=0)
	#第一个参数：规则
	#第二个参数：替换后的字符串
	#第三个参数：字符串
	#第四个参数：替换个数。默认为0，表示每个匹配项都替换
	test = "Hi, nice to meet you where are you from?"
	re.sub(r'\s', '-', test);
	#'Hi,-nice-to-meet-you-where-are-you-from?'
	re.sub(r'\s', '-', test, 5);# 替换至第5个
	#'Hi,-nice-to-meet-you-where are you from?'
	
def split():
	#re.split 用于来分割字符串
	help(re.split)
	#split(pattern, string, maxsplit=0)
	#第一个参数：规则
	#第二个参数：字符串
	#第三个参数：最大分割字符串，默认为0，表示每个匹配项都分割
	test = "Hi, nice to meet you where are you from?";
	re.split(r"\s+", test);
	#['Hi', 'nice', 'to', 'meet', 'you', 'where', 'are', 'you', 'from?']
	re.split(r"\s+", test, 3);# 分割前三个
	#['Hi', 'nice', 'to', 'meet you where are you from?']
	
def compile():
	#re.compile 可以把正则表达式编译成一个正则对象
	help(re.compile);
	#compile(pattern, flags=0);
	#第一个参数：规则
	#第二个参数：标志位
	test = "Hi, nice to meet you where are you from?";
	k = re.compile(r'\w*o\w*');#匹配带o的字符串
	dir(k);
	#['__copy__', '__deepcopy__', 'findall', 'finditer', 'match', 'scanner', 'search', 'split', 'sub', 'subn']
	print k.findall(test);# 显示所有包含o的字符串
	#['to', 'you', 'you', 'from']
	print k.sub(lambda m: '[' + m.group(0) + ']', test);# 将字符串中含有o的单词用[]括起来
	# Hi, nice [to] meet [you] where are [you] [from]?
	
def downloadJs():
	url = 'http://image.baidu.com/channel/wallpaper';
	read = urllib2.urlopen(url).read();
	pat = re.compile(r'src="http://.+?.js">');
	urls = re.findall(pat, read);
	for i in urls:
		url = i.replace('src="', '').replace('">', '');
		try:
			iread = urllib2.urlopen(url).read();
			name = os.path.basename(url);
			with open(name, 'wb') as jsname:
				jsname.write(iread);
		except:
			print url, "url error"