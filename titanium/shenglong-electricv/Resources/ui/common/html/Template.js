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
};