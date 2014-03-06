-- 2013-12-11
CREATE TABLE weather_citys(
	id INT(10) NOT NULL AUTO_INCREMENT,
	cityCode VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'cityCode',
	cityName VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'cityName',
	spellName VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'spellName',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT '日期',
	bz INT(10) NOT NULL DEFAULT 0 COMMENT '1 - 可用 2 - 不可用',
	PRIMARY KEY(id)
);
SELECT * FROM weather_citys;
TRUNCATE TABLE weather_citys;
SELECT * FROM writers;
UPDATE writers SET NAME='Guy de Maupasant' WHERE id='4';-- Emile Zola
UPDATE writers SET NAME = 'Guy de Maupasant' WHERE id = '4';
UPDATE writers SET NAME='Guy de Maupasant' WHERE id=4;

CREATE TABLE images(
	id INT PRIMARY KEY AUTO_INCREMENT,
	`data` MEDIUMBLOB
);
SELECT * FROM images;

SELECT cityCode,cityName,spellName FROM weather_citys;

-- 2014-01-07
SELECT * FROM weather_citys;
CREATE TABLE app_menus(
	id INT(10) NOT NULL AUTO_INCREMENT,
	menu_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'menu_code',
	menu_name VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'menu_name',
	menu_showName VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'menu_showName',
	`type` INT(1) NOT NULL DEFAULT 0 COMMENT '1 - page 2 - news 3 - other',
	icon VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'icon',
	banner VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'banner',
	url VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'url',
	sl_url VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'sl_url',
	parentId INT(10) NOT NULL DEFAULT 0 COMMENT 'parentId',
	hasSubMenu INT(1) NOT NULL DEFAULT 0 COMMENT '0 - 没有 1 - 有',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT 'date',
	PRIMARY KEY(id)
);
CREATE TABLE app_pages(
	id INT(10) NOT NULL AUTO_INCREMENT,
	sl_page_id INT(10) NOT NULL DEFAULT 0 COMMENT 'sl_page_id',
	title VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'title',
	image VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'image',
	content TEXT,
	post_date VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'post_date',
	post_time INT(10) NOT NULL DEFAULT 0 COMMENT 'post_time',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT 'date',
	PRIMARY KEY(id)
);
CREATE TABLE app_news(
	id INT(10) NOT NULL AUTO_INCREMENT,
	sl_cid INT(10) NOT NULL DEFAULT 0 COMMENT 'sl_cid',
	sl_news_id INT(10) NOT NULL DEFAULT 0 COMMENT 'sl_news_id',
	title VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'title',
	post_date VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'post_date',
	post_time INT(10) NOT NULL DEFAULT 0 COMMENT 'post_time',
	`year` INT(10) NOT NULL DEFAULT 0 COMMENT 'year',
	image VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'image',
	content TEXT,
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT 'date',
	PRIMARY KEY(id)
);

SELECT * FROM app_menus;
SELECT * FROM app_pages;
SELECT * FROM app_news;

-- 2014-01-10
SELECT * FROM app_menus;
SELECT * FROM app_pages;
SELECT * FROM app_news;

SHOW CREATE TABLE app_menus;
SELECT menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date` FROM app_menus;
INSERT INTO app_menus(menu_code,menu_name,menu_showName,`type`,icon,url,sl_url,parentId,hasSubMenu,`date`) VALUES (%s,%s,%s,%d,%s,%s,%s,%d,%d,%d);
TRUNCATE TABLE app_menus;

SELECT * FROM app_menus;
SELECT * FROM app_menus WHERE LENGTH(menu_code)>3;
ALTER TABLE app_menus ADD COLUMN parentCode VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'parentCode';
ALTER TABLE app_menus ADD COLUMN pageId VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'pageId';
ALTER TABLE app_menus ADD COLUMN newsId VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'newsId';
ALTER TABLE app_menus ADD COLUMN sl_cid VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'sl_cid';
SELECT * FROM app_menus WHERE parentCode<>'';
UPDATE app_menus SET parentId=(SELECT id FROM app_menus b WHERE app_menus.parentCode=b.menu_code) WHERE parentCode<>'';
UPDATE app_menus SET parentId=0 WHERE parentCode<>'';

SELECT * FROM app_menus WHERE TYPE=1;
SELECT * FROM app_menus WHERE TYPE=2;
SELECT * FROM app_pages;
SELECT * FROM app_news;
ALTER TABLE app_news ADD COLUMN sl_url VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'sl_url';
ALTER TABLE app_news ADD COLUMN icon VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'icon';
ALTER TABLE app_news ADD COLUMN post_desc VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'post_desc';
ALTER TABLE app_news ADD COLUMN page INT(10) NOT NULL DEFAULT 0 COMMENT 'page';

SELECT id,sl_url FROM app_menus WHERE `type`=1;
SHOW CREATE TABLE app_pages;
SHOW CREATE TABLE app_news;

-- 2014-01-11
SELECT * FROM app_menus;
SELECT * FROM app_news;
SELECT * FROM app_news WHERE content LIKE '%uploads%';

UPDATE app_menus SET url='/website/page_template.html' WHERE TYPE=1;
-- /website/submenu.html
SELECT * FROM app_menus WHERE LENGTH(parentCode)=6;
SELECT * FROM app_menus WHERE menu_code IN (SELECT DISTINCT parentCode FROM app_menus WHERE LENGTH(parentCode)=6);
SELECT * FROM app_menus;
SELECT * FROM app_menus WHERE url='';

SELECT * FROM app_menus WHERE parentCode='';
SELECT id,menu_code,menu_name,menu_showName,`type`,icon,banner,url,sl_url,parentId,parentCode,pageId,newsId,sl_cid FROM app_menus WHERE parentCode='';
SELECT COUNT(1) `count` FROM app_menus WHERE parentCode='001';
SELECT COUNT(1) `count` FROM app_menus WHERE parentCode='001003002';
SELECT COUNT(1) `count` FROM app_menus WHERE parentCode='001004';

-- 2014-01-12
SELECT * FROM app_menus;
SHOW CREATE TABLE app_menus;
SHOW CREATE TABLE app_pages;
SELECT * FROM app_pages;

SELECT * FROM app_menus WHERE parentCode='';

SELECT id,sl_page_id,title,image,content,post_date,post_time,`date` FROM app_pages WHERE sl_page_id=13;
SELECT id,sl_cid,sl_news_id,title,post_date,post_time,`year`,image,content,`date`,sl_url,icon,post_desc,page FROM app_news WHERE sl_cid=7;

SELECT * FROM app_menus WHERE TYPE<>1 && TYPE<>2;
SELECT * FROM app_menus WHERE parentCode='';

SELECT id,sl_page_id,title,image,content,post_date,post_time,`date` FROM app_pages WHERE sl_page_id=29;
SELECT id,sl_page_id,title,image,content,post_date,post_time,`date` FROM app_pages WHERE menu_code='001001';

ALTER TABLE app_pages ADD COLUMN menu_id INT(10) NOT NULL DEFAULT 0 COMMENT 'menu_id';
ALTER TABLE app_pages ADD COLUMN menu_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'menu_code';
ALTER TABLE app_pages ADD COLUMN bz INT(1) NOT NULL DEFAULT 1 COMMENT 'bz';

SELECT id,menu_code,sl_url FROM app_menus WHERE TYPE=1;
SELECT * FROM app_news;
ALTER TABLE app_news ADD COLUMN menu_id INT(10) NOT NULL DEFAULT 0 COMMENT 'menu_id';
ALTER TABLE app_news ADD COLUMN menu_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'menu_code';
ALTER TABLE app_news ADD COLUMN bz INT(1) NOT NULL DEFAULT 1 COMMENT 'bz';

ALTER TABLE app_menus ADD COLUMN page_menu_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'page_menu_code';
ALTER TABLE app_menus ADD COLUMN bz INT(1) NOT NULL DEFAULT 1 COMMENT 'bz';
SELECT * FROM app_menus;
SELECT * FROM app_pages;
SELECT * FROM app_news;

UPDATE app_menus SET page_menu_code=menu_code WHERE TYPE=1;

-- 2014-02-22
SELECT * FROM app_pages;
SELECT * FROM app_menus;
-- <div class="base_t clearfix"><h4><span style="font-size:14px">武汉公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：武汉市关东科技工业园高科大厦14楼</span></div><div><span style="font-size:14px">武汉第一工厂：武汉市关东科技工业园3-2号</span></div><div><span style="font-size:14px">武汉第二工厂：武汉市东湖高新技术开发区南湖大道86号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：027-87592196、87618816</span></div><div><span style="font-size:14px">传真：027-87610976</span></div></div></div>
-- <div class="base_t clearfix"><h4><span style="font-size:14px">北京公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：北京市海淀区上地三街9号嘉华大厦A座8层</span></div><div><span style="font-size:14px">工厂地址：北京密云经济开发区科技路2号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：010-82781864、62965454</span></div><div><span style="font-size:14px">传真：010-62965453</span></div></div></div>
-- <div class="base_t clearfix"><h4><span style="font-size:14px">广州公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：东莞市东城区东升路鸿怡大厦4A</span></div><div><span style="font-size:14px">工厂地址：东莞市万江区上甲工业区<span style="line-height:0px;display:none" id="_baidu_bookmark_start_1">‍</span></span></div></div><div class="base_r"><div><span style="font-size:14px">电话：0769-23052820</span></div><div><span style="font-size:14px">传真：0769-23052820</span></div></div></div>
-- <div class="base_t clearfix"><h4><span style="font-size:14px">上海公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：上海市<span style="line-height:0px;display:none" id="_baidu_bookmark_start_2">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_3">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_4">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_5">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_6">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_7">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_8">‍</span></span>长宁区<span style="line-height:0px;display:none" id="_baidu_bookmark_start_9">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_10">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_11">‍</span></span>中山<span style="line-height:0px;display:none" id="_baidu_bookmark_start_12">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_13">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_14">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_15">‍</span></span>西路<span style="line-height:0px;display:none" id="_baidu_bookmark_start_16">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_17">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_18">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_19">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_20">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_21">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_22">‍</span></span>SOHO<span style="line-height:0px;display:none" id="_baidu_bookmark_start_23">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_24">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_25">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_26">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_27">‍</span></span>中山<span style="line-height:0px;display:none" id="_baidu_bookmark_start_28">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_29">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_30">‍</span></span>广场<span style="line-height:0px;display:none" id="_baidu_bookmark_start_31">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_32">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_33">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_34">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_35">‍</span></span>A<span style="line-height:0px;display:none" id="_baidu_bookmark_start_36">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_37">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_38">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_39">‍</span></span>座<span style="line-height:0px;display:none" id="_baidu_bookmark_start_40">‍</span>6<span style="line-height:0px;display:none" id="_baidu_bookmark_start_41">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_42">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_43">‍</span></span>层<span style="line-height:0px;display:none" id="_baidu_bookmark_start_44">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_45">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_46">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_47">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_48">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_49">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_50">‍</span></span></span></span></span></span></span></div><div><span style="font-size:14px">工厂地址：上海市青浦区宏城经济开发区4501弄80号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：021-33865211、39271600、39271603</span></div><div><span style="font-size:14px">传真：021-33865216</span></div></div></div>
-- <div class="base_t clearfix"><h4><span style="font-size:14px">重庆公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：重庆市渝中区解放碑英利国际金融大厦36层</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：023-68190140</span></div><div><span style="font-size:14px">传真：023-68190140</span></div><span style="font-size:14px"></span></div></div>
-- <div class="base_t clearfix"><h4><span style="font-size:14px">天津公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：天津市河东区津塘路174号C座2层</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：022-84370538</span></div><div><span style="font-size:14px">传真：022-84371308</span></div></div></div>
INSERT INTO app_pages(sl_page_id,content,menu_id,menu_code,bz) VALUES (-1,'<div class="base_t clearfix"><h4><span style="font-size:14px">武汉公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：武汉市关东科技工业园高科大厦14楼</span></div><div><span style="font-size:14px">武汉第一工厂：武汉市关东科技工业园3-2号</span></div><div><span style="font-size:14px">武汉第二工厂：武汉市东湖高新技术开发区南湖大道86号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：027-87592196、87618816</span></div><div><span style="font-size:14px">传真：027-87610976</span></div></div></div>',52,'005001001',1);
INSERT INTO app_pages(sl_page_id,content,menu_id,menu_code,bz) VALUES (-2,'<div class="base_t clearfix"><h4><span style="font-size:14px">北京公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：北京市海淀区上地三街9号嘉华大厦A座8层</span></div><div><span style="font-size:14px">工厂地址：北京密云经济开发区科技路2号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：010-82781864、62965454</span></div><div><span style="font-size:14px">传真：010-62965453</span></div></div></div>',53,'005001002',1);
INSERT INTO app_pages(sl_page_id,content,menu_id,menu_code,bz) VALUES (-3,'<div class="base_t clearfix"><h4><span style="font-size:14px">广州公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：东莞市东城区东升路鸿怡大厦4A</span></div><div><span style="font-size:14px">工厂地址：东莞市万江区上甲工业区<span style="line-height:0px;display:none" id="_baidu_bookmark_start_1">‍</span></span></div></div><div class="base_r"><div><span style="font-size:14px">电话：0769-23052820</span></div><div><span style="font-size:14px">传真：0769-23052820</span></div></div></div>',54,'005001003',1);
INSERT INTO app_pages(sl_page_id,content,menu_id,menu_code,bz) VALUES (-4,'<div class="base_t clearfix"><h4><span style="font-size:14px">上海公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：上海市<span style="line-height:0px;display:none" id="_baidu_bookmark_start_2">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_3">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_4">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_5">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_6">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_7">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_8">‍</span></span>长宁区<span style="line-height:0px;display:none" id="_baidu_bookmark_start_9">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_10">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_11">‍</span></span>中山<span style="line-height:0px;display:none" id="_baidu_bookmark_start_12">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_13">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_14">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_15">‍</span></span>西路<span style="line-height:0px;display:none" id="_baidu_bookmark_start_16">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_17">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_18">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_19">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_20">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_21">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_22">‍</span></span>SOHO<span style="line-height:0px;display:none" id="_baidu_bookmark_start_23">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_24">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_25">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_26">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_27">‍</span></span>中山<span style="line-height:0px;display:none" id="_baidu_bookmark_start_28">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_29">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_30">‍</span></span>广场<span style="line-height:0px;display:none" id="_baidu_bookmark_start_31">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_32">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_33">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_34">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_35">‍</span></span>A<span style="line-height:0px;display:none" id="_baidu_bookmark_start_36">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_37">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_38">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_39">‍</span></span>座<span style="line-height:0px;display:none" id="_baidu_bookmark_start_40">‍</span>6<span style="line-height:0px;display:none" id="_baidu_bookmark_start_41">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_42">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_43">‍</span></span>层<span style="line-height:0px;display:none" id="_baidu_bookmark_start_44">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_45">‍</span><span style="line-height:0px;display:none" id="_baidu_bookmark_start_46">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_47">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_48">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_49">‍<span style="line-height:0px;display:none" id="_baidu_bookmark_start_50">‍</span></span></span></span></span></span></span></div><div><span style="font-size:14px">工厂地址：上海市青浦区宏城经济开发区4501弄80号</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：021-33865211、39271600、39271603</span></div><div><span style="font-size:14px">传真：021-33865216</span></div></div></div>',55,'005001004',1);
INSERT INTO app_pages(sl_page_id,content,menu_id,menu_code,bz) VALUES (-5,'<div class="base_t clearfix"><h4><span style="font-size:14px">重庆公司</span></h4><div class="base_l"><div><span style="font-size:14px">办公地址：重庆市渝中区解放碑英利国际金融大厦36层</span></div></div><div class="base_r"><div><span style="font-size:14px">电话：023-68190140</span></div><div><span style="font-size:14px">传真：023-68190140</span></div><span style="font-size:14px"></span></div></div>',56,'005001005',1);

-- 2014-03-05
SELECT * FROM app_menus;
SELECT * FROM app_pages WHERE sl_page_id=29;

-- 2014-03-06
SELECT * FROM app_menus;
DROP TABLE pm2_5_citys;
DROP TABLE pm2_5_station;
CREATE TABLE pm2_5_citys(
	id INT(10) NOT NULL AUTO_INCREMENT,
	cityCode VARCHAR(60) NOT NULL DEFAULT '' COMMENT '区号',
	cityName VARCHAR(60) NOT NULL DEFAULT '' COMMENT '城市名称',
	spellName VARCHAR(60) NOT NULL DEFAULT '' COMMENT '拼音',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT '日期',
	bz INT(10) NOT NULL DEFAULT 0 COMMENT '1 - 可用 2 - 不可用',
	PRIMARY KEY(id)
);
CREATE TABLE pm2_5_station(
	id INT(10) NOT NULL AUTO_INCREMENT,
	station_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT '监测点编码',
	station_name VARCHAR(60) NOT NULL DEFAULT '' COMMENT '监测点名称',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT '日期',
	bz INT(10) NOT NULL DEFAULT 0 COMMENT '1 - 可用 2 - 不可用',
	PRIMARY KEY(id)
);
-- "aqi":109,"area":"天津","co":1.278,"co_24h":1.264,"no2":94,"no2_24h":55,"o3":3,"o3_24h":70,"o3_8h":31,"o3_8h_24h":59,"pm10":125,"pm10_24h":82,"pm2_5":82,"pm2_5_24h":53,"position_name":"市监测中心","primary_pollutant":"细颗粒物(PM2.5)","quality":"轻度污染","so2":113,"so2_24h":98,"station_code":"1013A","time_point":"2014-03-06T00:00:00Z"
CREATE TABLE pm2_5_data2014(
	id INT(10) NOT NULL AUTO_INCREMENT,
	aqi INT(10) NOT NULL DEFAULT 0 COMMENT '空气质量指数',
	cityCode VARCHAR(60) NOT NULL DEFAULT '' COMMENT '区号',
	`area` VARCHAR(60) NOT NULL DEFAULT '' COMMENT '城市名称',
	cityName VARCHAR(60) NOT NULL DEFAULT '' COMMENT '城市名称',
	spellName VARCHAR(60) NOT NULL DEFAULT '' COMMENT '拼音',
	co DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '一氧化碳1小时平均',
	co_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '一氧化碳24小时滑动平均',
	no2 DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '二氧化氮1小时平均',
	no2_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '二氧化氮24小时滑动平均',
	o3 DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '臭氧1小时平均',
	o3_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '臭氧日最大1小时平均',
	o3_8h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '臭氧8小时滑动平均',
	o3_8h_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '臭氧日最大8小时滑动平均',
	pm10 DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '颗粒物（粒径小于等于10μm）1小时平均',
	pm10_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '颗粒物（粒径小于等于10μm）24小时滑动平均',
	pm2_5 DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '颗粒物（粒径小于等于2.5μm）1小时平均',
	pm2_5_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '颗粒物（粒径小于等于2.5μm）24小时滑动平均',
	so2 DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '二氧化硫1小时平均',
	so2_24h DECIMAL(16,6) NOT NULL DEFAULT 0 COMMENT '二氧化硫24小时滑动平均',
	primary_pollutant VARCHAR(60) NOT NULL DEFAULT 0 COMMENT '首要污染物',
	quality VARCHAR(60) NOT NULL DEFAULT 0 COMMENT '空气质量指数类别，有“优、良、轻度污染、中度污染、重度污染、严重污染”6类',
	station_code VARCHAR(60) NOT NULL DEFAULT '' COMMENT '监测点编码',
	position_name VARCHAR(60) NOT NULL DEFAULT '' COMMENT '监测点名称',
	time_point VARCHAR(60) NOT NULL DEFAULT 0 COMMENT '数据发布的时间',
	publishDate INT(10) NOT NULL DEFAULT 0 COMMENT 'publishDate',
	`date` INT(10) NOT NULL DEFAULT 0 COMMENT '日期',
	bz INT(10) NOT NULL DEFAULT 0 COMMENT '1 - 可用 2 - 不可用',
	PRIMARY KEY(id)
);

SELECT * FROM pm2_5_citys;
SELECT * FROM pm2_5_station;
SELECT * FROM pm2_5_data2014;

SELECT * FROM app_menus;
ALTER TABLE app_menus ADD COLUMN banner_title TEXT COMMENT 'banner_title';
ALTER TABLE app_menus ADD COLUMN bannerTitleClass TEXT COMMENT 'bannerTitleClass';
ALTER TABLE app_menus CHANGE COLUMN bannerTitleClass bannerTitleClass VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'bannerTitleClass';
SELECT banner_title FROM app_menus;
UPDATE app_menus SET banner_title='';
SELECT UNIX_TIMESTAMP(NOW());
-- type 1 - page 2 - newslist 3 - 未定义 4 - news 5 - customers
SELECT SUBSTR(menu_code,1,3) FROM app_menus;
UPDATE app_menus SET banner='banner',banner_title='人民大会堂盛隆电气盛恩答谢年欢会',bannerTitleClass='title' WHERE SUBSTR(menu_code,1,3)='002';
UPDATE app_menus SET banner='aboutus',banner_title='盛隆电气集团三十周年庆典合影钓鱼台国宾馆2009年5月2日',bannerTitleClass='aboutus_title' WHERE SUBSTR(menu_code,1,3)='001';
UPDATE app_menus SET banner='banner',banner_title='让一度电创造更多GDP，<br/>让电使幸福生活更幸福，<br/>让电是美丽中国更美丽！',bannerTitleClass='title' WHERE SUBSTR(menu_code,1,3)='003';
UPDATE app_menus SET banner='map',banner_title='',bannerTitleClass='title' WHERE SUBSTR(menu_code,1,3)='004';
UPDATE app_menus SET banner='counselAndFeedback',banner_title='',bannerTitleClass='title' WHERE SUBSTR(menu_code,1,3)='005';