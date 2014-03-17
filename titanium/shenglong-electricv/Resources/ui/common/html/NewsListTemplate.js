/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-13
 * Description: newsListTemplate
 * Modification:
 *      甲午年（马年）丁卯月癸未日 农历二月十三
 *          NewsListemplate
 */
Ti.include('Template.js');

T.NewsListTemplate = function(opts) {
    if(opts == null) {
        opts = {
            name: 'newsList'
        };
    } else {
        opts.name = 'newsList';
    }
    this.banner = opts.banner;
    this.content = opts.content;
    this.parentMenu = opts.menu;
    
    this.bannerTemplate = '<div class="{banner.banner}"></div>\
                        <div class="{banner.bannerTitleClass}">{banner.banner_title}</div>';
    this.contentTemplate = '<div class="post_item clearfix" onclick="visitNews({news.sl_news_id})">\
                                <a href="#" class="post_cover"><img src="{news.image}" alt="" /></a>\
                                <div class="post_msg">\
                                    <h2><a href="#">{news.title}</a></h2>\
                                    <p class="post_time">{news.post_date}</p>\
                                    <p class="post_desc">{news.post_desc}</p>\
                                </div>\
                            </div>';
    
    this.html = '';
    this.head = '<!DOCTYPE html>\
        <html lang="zh-CN">\
            <head>\
                <meta charset="UTF-8" />\
                <link rel="stylesheet" type="text/css" href="website/css/base_mobile.css" />\
                <link rel="shortcut icon" href="website/favicon.ico" />\
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\
                <!--<meta http-equiv="cache-control" content="max-age=0" />\
                <meta http-equiv="cache-control" content="no-cache" />\
                <meta http-equiv="expires" content="0" />\
                <meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />\
                <meta http-equiv="pragma" content="no-cache" />-->\
                <link rel="stylesheet" type="text/css" href="website/css/news.css" />\
                <link rel="stylesheet" type="text/css" href="website/css/pager.css" />\
                <title>盛隆电气集团欢迎您!</title>\
            </head>';
    this.body = [];
    this.body.push('<body>\
                <div class="wrapper">\
                    <!--<header class="clearfix">\
                        <div class="logo">\
                            <a href="./index.html"><img src="website/images/logo.png" alt=""/></a>\
                        </div>\
                    </header>-->');
                    
    this.body.push('<div id="banner" class="slider">');
    this.body.push('{$banner}');
    this.body.push('</div>\
                    <div class="page_main">\
                        <div id="newslist" class="post_list">');
    this.body.push('{$content}');
    this.body.push('</div>\
                    </div>\
                </div>\
                <script type="text/javascript" src="website/js/zepto.min.js"></script>\
                <script type="text/javascript" src="website/js/underscore.js"></script>\
                <script type="text/javascript">\
                    var menu = {};\
                    var newslist = [];');
    this.body.push('var parentMenu = {$parentMenu};');
    this.body.push('function visitNews(sl_news_id) {\
                        var timestamp = (new Date()).getTime();\
                        Ti.App.fireEvent("app:visitNews", {\
                            sl_news_id: sl_news_id,\
                            parentMenu: JSON.stringify(parentMenu),\
                            timestamp: timestamp\
                        });\
                        return false;\
                    }\
                </script>\
            </body>\
        </html>');
    //继承属性
    T.Template.call(this, opts);
};

//继承方法
T.NewsListTemplate.prototype = new T.Template();
