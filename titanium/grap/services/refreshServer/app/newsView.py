# -*-encoding:utf-8-*-
'''
Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.me
Version: 1.0
Author: zhangchunsheng
Date: 2014-03-20
Description: newsView
Modification:
	甲、乙、丙、丁、戊、己、庚、辛、壬、癸 甲（jiǎ）、乙（yǐ）、丙（bǐng）、丁（dīng）、戊（wù）、己（jǐ）、庚（gēng）、辛（xīn）、壬（rén）、癸（guǐ）
	子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥 子（zǐ）、丑（chǒu）、寅（yín）、卯（mǎo）、辰（chén）、巳（sì）、午（wǔ）、未（wèi）、申（shēn）、酉（yǒu）、戌（xū）、亥（hài）
	甲午年（马年）丁卯月庚寅日 农历二月二十
'''
from django.http import Http404;
from django.shortcuts import render, get_object_or_404;
from django.http import HttpResponseRedirect, HttpResponse;
from django.template import RequestContext, loader;
from django.core.urlresolvers import reverse;
from django.views import generic;
from django.utils import timezone;

from app.models import Menus, News, Pages;

# Create your views here.
def index(request):
	return HttpResponse("news");
	
def getNews(request):
	return HttpResponse("getNews");