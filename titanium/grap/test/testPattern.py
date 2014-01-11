# -*- coding:utf-8 -*-
#一个简单的re实例，匹配字符串中的hello字符串

#导入re模块
import re;

#将正则表达式编译成Pattern对象，注意hello前面的r的意思是“原生字符串”
pattern = re.compile(r'hello');

#使用Pattern匹配文本，获得匹配结果，无法匹配时将放回None
match1 = pattern.match('hello world!');
match2 = pattern.match('helloo world!');
match3 = pattern.match('helllo world!');

#如果match1匹配成功
if(match1):
	# 使用Match获得分组信息
	print match1.group();
else:
	print 'match1匹配失败！';
	
#如果match2匹配成功
if(match2):
	# 使用Match获得分组信息
	print match2.group();
else:
	print 'match2匹配失败！';
	
#如果match3匹配成功
if(match3):
	# 使用Match获得分组信息
	print match3.group();
else:
	print 'match3匹配失败！';
	
#两个等价的re匹配，匹配一个小数
a = re.compile(r"""\d +  # the integral part
					\.   # the decimal point
					\d * # some fractional digits""", re.X);
					
b = re.compile(r"\d+\.\d*");

match11 = a.match('3.1415');
match12 = a.match('33');
match21 = b.match('3.1415');
match22 = b.match('33');

if(match11):
	# 使用Match获得分组信息
	print match11.group();
else:
	print u'match11不是小数';
	
if(match12):
	# 使用Match获得分组信息
	print match12.group();
else:
	print u'match12不是小数';
	
if(match21):
	# 使用Match获得分组信息
	print match21.group();
else:
	print u'match21不是小数';

if(match22):
	# 使用Match获得分组信息
	print match22.group();
else:
	print u'match22不是小数';
	
#一个简单的re实例，匹配字符串中的hello字符串
m = re.match(r'(hello)', 'hello world!');
print m.group();
print dir(m);
print m.string;
print m.re;
print m.pos;
print m.endpos;
print m.lastindex;
print m.lastgroup;

print m.groups();
print help(m.groups);
print m.groupdict();
print m.start();
print m.end();
print m.span();
print m.expand('\\1test');

#一个简单的match实例
# 匹配如下内容：单词+空格+单词+任意字符
m = re.match(r'(\w+) (\w+)(?P<sign>).*', 'hello world!');

print "m.string:", m.string;
print "m.re:", m.re;
print "m.pos:", m.pos;
print "m.endpos:", m.endpos;
print "m.lastindex:", m.lastindex;
print "m.lastgroup:", m.lastgroup;

print "m.group():", m.group();
print "m.group(1,2):", m.group(1, 2);
print "m.groups():", m.groups();
print "m.groupdict():", m.groupdict();
print "m.start(2):", m.start(2);
print "m.end(2):", m.end(2);
print "m.span(2):", m.span(2);
print r"m.expand(r'\g<2> \g<1>\g<3>'):", m.expand(r'\2 \1\3');

#一个简单的pattern实例
p = re.compile(r'(\w+) (\w+)(?P<sign>.*)', re.DOTALL);

print "p.pattern:", p.pattern;
print "p.flags:", p.flags;
print "p.groups:", p.groups;
print "p.groupindex:", p.groupindex;

# match(string[, pos[, endpos]])|re.match(pattern, string[, flags])
# 将正则表达式编译成Pattern对象
pattern = re.compile(r'hello');

# 使用Pattern匹配文本，获得匹配结果，无法匹配时将返回None
match = pattern.match('hello world!');

if(match):
	# 使用Match获得分组信息
	print match.group();

# search(string[, pos[, endpos]])|re.search(pattern, string[, flags])
# 一个简单的search实例
# 将正则表达式编译成Pattern对象
pattern = re.compile(r'world');

# 使用search()查找匹配的子串，不存在能匹配的子串时将返回None
# 这个例子中使用match()无法成功匹配
match = pattern.search('hello world!');

if(match):
	# 使用Match获得分组信息
	print match.group();

# split(string[, maxsplit])|re.split(pattern, string[, maxsplit])
p = re.compile(r'\d+');
print p.split('one1two2three3four4');

# findall(string[, pos[, endpos]])|re.findall(pattern, string[, flags])
p = re.compile(r'\d+');
print p.findall('one1two2three3four4');

# finditer(string[, pos[, endpos]])|re.finditer(pattern, string[, flags]);
p = re.compile(r'\d+');
for m in p.finditer('one1two2three3four4'):
	print m.group(),;
	
# sub(repl, string[, count])|re.sub(pattern, repl, string[, count])
p = re.compile(r'(\w+) (\w+)');
s = 'We say, hello world!';
print p.sub(r'\2 \1', s);

def func(m):
	return m.group(1).title() + ' ' + m.group(2).title();

print p.sub(func, s);

# subn(repl, string[, count])|re.subn(pattern, repl, string[, count])
p = re.compile(r'(\w+) (\w+)');
s = 'We say, hello world!';
print p.subn(r'\2 \1', s);

print p.subn(func, s);

pat = re.compile(r'^\s+');
s = '  \t  foo  \t  bar \t   ';
print s;
s = pat.sub('', s);
pat = re.compile(r'\s+$');
print pat.sub('', s);
print s.strip();