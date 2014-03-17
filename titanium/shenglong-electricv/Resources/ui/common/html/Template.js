/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-13
 * Description: template
 * Modification:
 *      甲午年（马年）丁卯月癸未日 农历二月十三
 *          Template
 */
var T;
if(T == null) {
    T = {};
}
T.Template = function(opts) {
    if(opts == null) {
        opts = {
            name: 'template'
        };
    }
    this.name = opts.name;
    if(this.name != 'template') {
        this.html = '';
    }
};

T.Template.prototype.makeHtml = function() {
    this.html = this.head;
    var content = "";
    for(var i = 0 ; i < this.body.length ; i++) {
        if(this.body[i] == '{$banner}') {
            //this.bannerTemplate = '<div class="{banner.banner}"></div><div class="{banner.bannerTitleClass}">{banner.banner_title}</div>';
            var banner = JSON.parse(this.banner);
            var html = this.bannerTemplate.replace('{banner.banner}', banner.banner);
            html = html.replace('{banner.bannerTitleClass}', banner.bannerTitleClass);
            html = html.replace('{banner.banner_title}', banner.banner_title);
            content = this.body[i].replace('{$banner}', html);
        } else if(this.body[i] == '{$content}') {
            if(this.name == 'newsList') {
                var templateContent = JSON.parse(this.content);
                var html = '';
                var templateHtml = '';
                for(var j = 0 ; j < templateContent.length ; j++) {
                    templateHtml = '';
                    templateHtml = this.contentTemplate.replace('{news.sl_news_id}', templateContent[j].sl_news_id);
                    templateHtml = templateHtml.replace('{news.image}', templateContent[j].image);
                    templateHtml = templateHtml.replace('{news.title}', templateContent[j].title);
                    templateHtml = templateHtml.replace('{news.post_date}', templateContent[j].post_date);
                    templateHtml = templateHtml.replace('{news.post_desc}', templateContent[j].post_desc);
                    html += templateHtml;
                }
                content = this.body[i].replace('{$content}', html);
            } else if(this.name == 'news') {
                var templateContent = JSON.parse(this.content);
                var html = this.contentTemplate.replace('{news.title}', templateContent.title);
                html = html.replace('{news.post_date}', templateContent.post_date);
                html = html.replace('{news.content}', templateContent.content);
                
                content = this.body[i].replace('{$content}', html);
            } else if(this.name == 'pageCounselAndFeedback') {
                content = this.body[i].replace('{$content}', this.content);
            } else if(this.name == 'pageCustomer') {
                var tr = this.content.split("<tr ");
                var td;
                var reContent;
                var match;
                var data;
                var datas = [];

                for(var j = 0 ; j < tr.length ; j++) {
                    td = tr[j].split("<td ");
                    for(var k = 0 ; k < td.length ; k++) {
                        reContent = /<span .+>.+<\/span>/gi;
                        match = td[k].match(reContent);
                        if(match) {
                            reContent = />.+</gi;
                            data = match[0].match(reContent);
                            data = data[0].substring(1, data[0].indexOf("<"));
                            datas.push(data);
                        }
                    }
                }
                var html = '';
                var templateHtml = '';
                for(var j = 0 ; j < datas.length ; j++) {
                    templateHtml = '';
                    templateHtml = this.contentTemplate.replace('{item}', datas[j]);
                    html += templateHtml;
                }
                content = this.body[i].replace('{$content}', html);
            } else if(this.name == 'page') {
                content = this.body[i].replace('{$content}', this.content);
            } else if(this.name == 'submenu') {
                var templateContent = JSON.parse(this.content);
                var html = '';
                var templateHtml = '';
                for(var j = 0 ; j < templateContent.length ; j++) {
                    templateHtml = '';
                    templateHtml = this.contentTemplate.replace('{submenu.id}', templateContent[j].id);
                    templateHtml = templateHtml.replace('{submenu.showName}', templateContent[j].showName);
                    html += templateHtml;
                }
                content = this.body[i].replace('{$content}', html);
            } else {
                content = this.body[i].replace('{$content}', this.content);
            }
        } else if(this.body[i].indexOf('{$submenus}') > 0) {
            var html = this.submenus;
            content = this.body[i].replace('{$submenus}', html);
        } else if(this.body[i].indexOf('{$parentMenu}') > 0) {
            var html = this.parentMenu;
            content = this.body[i].replace('{$parentMenu}', html);
        } else {
            content = this.body[i];
        }
        this.html += content;
    }
};
