/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-13
 * Description: makeHtml
 * Modification:
 *      甲午年（马年）农历二月十三
 *          MakeHtml
 */
Ti.include('NewsListTemplate.js');
Ti.include('NewsTemplate.js');
Ti.include('PageCounselAndFeedback.js');
Ti.include('PageCustomerTemplate.js');
Ti.include('PageHomeTemplate.js');
Ti.include('PageTemplate.js');
Ti.include('SubmenuTemplate.js');

function MakeHtml(opts) {
    this.opts = opts;
};

MakeHtml.prototype.getHtml = function() {
    var opts = this.opts;
    var template = {};
    if(opts.name == 'newsList') {
        template = new T.NewsListTemplate(opts);
        template.makeHtml();
    } else if(opts.name == 'news') {
        template = new T.NewsTemplate(opts);
        template.makeHtml();
    } else if(opts.name == 'pageCounselAndFeedback') {
        template = new T.PageCounselAndFeedback(opts);
        template.makeHtml();
    } else if(opts.name == 'pageCustomer') {
        template = new T.PageCustomerTemplate(opts);
        template.makeHtml();
    } else if(opts.name == 'pageHome') {
        template = new T.PageHomeTemplate(opts);
        template.makeHtml();
    } else if(opts.name == 'page') {
        template = new T.PageTemplate(opts);
        template.makeHtml();
    } else if(opts.name == 'submenu') {
        template = new T.SubmenuTemplate(opts);
        template.makeHtml();
    } else {
        template = new T.Template(opts);
        template.makeHtml();
    }
    return template.html;
};

/**
 * addEventListener
 */
MakeHtml.prototype.addEventListener = function(name, callback) {
    
};

/**
 * show
 */
MakeHtml.prototype.show = function() {
    
};

/**
 * hide
 */
MakeHtml.prototype.hide = function() {
    
};