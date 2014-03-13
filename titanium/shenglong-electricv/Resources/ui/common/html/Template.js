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
            content = this.body[i].replace('{$banner}', this.banner);
        } else if(this.body[i] == '{$content}') {
            content = this.body[i].replace('{$content}', this.content);
        } else {
            content = this.body[i];
        }
        this.html += content;
    }
};
