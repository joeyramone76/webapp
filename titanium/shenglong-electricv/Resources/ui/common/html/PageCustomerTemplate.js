/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-13
 * Description: pageCustomerTemplate
 * Modification:
 *      甲午年（马年）丁卯月癸未日 农历二月十三
 *          PageCustomerTemplate
 */
Ti.include('Template.js');

T.PageCustomerTemplate = function(opts) {
    if(opts == null) {
        opts = {
            name: 'pageCustomer'
        };
    } else {
        opts.name = 'pageCustomer';
    }
    //继承属性
    T.Template.call(this, opts);
};

//继承方法
T.PageCustomerTemplate.prototype = new T.Template();