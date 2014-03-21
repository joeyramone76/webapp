# -*-encoding:utf-8-*-
'''
Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.me
Version: 1.0
Author: zhangchunsheng
Date: 2014-03-20
Description: models
Modification:
	甲、乙、丙、丁、戊、己、庚、辛、壬、癸 甲（jiǎ）、乙（yǐ）、丙（bǐng）、丁（dīng）、戊（wù）、己（jǐ）、庚（gēng）、辛（xīn）、壬（rén）、癸（guǐ）
	子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥 子（zǐ）、丑（chǒu）、寅（yín）、卯（mǎo）、辰（chén）、巳（sì）、午（wǔ）、未（wèi）、申（shēn）、酉（yǒu）、戌（xū）、亥（hài）
	甲午年（马年）丁卯月庚寅日 农历二月二十
'''
import datetime;
from django.db import models;
from django.utils import timezone; 
# Create your models here.

class Menus(models.Model):
	menu_code = models.CharField(max_length=60);
	menu_name = models.CharField(max_length=60);
	menu_showName = models.CharField(max_length=60);
	type = models.IntegerField(default=0);
	icon = models.CharField(max_length=60);
	banner = models.CharField(max_length=255);
	url = models.CharField(max_length=255);
	sl_url = models.CharField(max_length=255);
	website_url = models.CharField(max_length=255);
	parentId = models.IntegerField(default=0);
	hasSubMenu = models.IntegerField(default=0);
	date = models.IntegerField(default=0);
	parentCode = models.CharField(max_length=60);
	pageId = models.CharField(max_length=60);
	newsId = models.CharField(max_length=60);
	sl_cid = models.CharField(max_length=60);
	page_menu_code = models.CharField(max_length=60);
	bz = models.IntegerField(default=0);
	banner_title = models.TextField();
	bannerTitleClass = models.CharField(max_length=60);
	
	def __unicode__(self):
		return self.menu_name;
	
class News(models.Model):
	sl_cid = models.IntegerField(default=0);
	sl_news_id = models.IntegerField(default=0);
	title = models.CharField(max_length=255);
	post_date = models.CharField(max_length=60);
	post_time = models.IntegerField();
	year = models.IntegerField();
	image = models.CharField(max_length=255);
	content = models.TextField();
	date = models.IntegerField();
	sl_url = models.CharField(max_length=255);
	icon = models.CharField(max_length=255);
	post_desc = models.CharField(max_length=255);
	page = models.IntegerField();
	menu_id = models.IntegerField();
	menu_code = models.CharField(max_length=60);
	bz = models.IntegerField();
	
	def __unicode__(self):
		return self.title;
	
class Pages(models.Model):
	sl_page_id = models.IntegerField(default=0);
	title = models.CharField(max_length=255);
	image = models.CharField(max_length=255);
	content = models.TextField();
	post_date = models.CharField(max_length=60);
	post_time = models.IntegerField();
	date = models.IntegerField();
	menu_id = models.IntegerField();
	menu_code = models.CharField(max_length=60);
	bz = models.IntegerField();
	
	def __unicode__(self):
		return self.title;