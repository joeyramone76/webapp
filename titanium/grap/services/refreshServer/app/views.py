# -*-encoding:utf-8-*-
'''
Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.me
Version: 1.0
Author: zhangchunsheng
Date: 2014-03-20
Description: views
Modification:
	�ס��ҡ����������졢�������������ɡ��� �ף�ji�������ң�y����������b��ng��������d��ng�����죨w����������j����������g��ng��������x��n�����ɣ�r��n�����gu����
	�ӡ�������î�������ȡ��硢δ���ꡢ�ϡ��硢�� �ӣ�z��������ch��u��������y��n����î��m��o��������ch��n�����ȣ�s�������磨w������δ��w��i�����꣨sh��n�����ϣ�y��u�����磨x����������h��i��
	�����꣨���꣩��î�¸����� ũ�����¶�ʮ
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
	return HttpResponse("index");