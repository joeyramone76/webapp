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
SELECT * FROM app_news;
SELECT * FROM app_news WHERE content LIKE '%uploads%';