/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-03-13
 * Description: pageCounselAndFeedbackTemplate
 * Modification:
 *      甲午年（马年）丁卯月癸未日 农历二月十三
 *          PageCounselAndFeedbackTemplate
 */
Ti.include('Template.js');

T.PageCounselAndFeedback = function(opts) {
    if(opts == null) {
        opts = {
            name: 'pageCounselAndFeedback'
        };
    } else {
        opts.name = 'pageCounselAndFeedback';
    }
    this.banner = opts.banner;
    this.content = opts.content;
    
    this.bannerTemplate = '';
    this.contentTemplate = '';
    
    this.html = '';
    this.head = '<!DOCTYPE html>\
                <html lang="zh-CN">\
                    <head>\
                        <meta charset="UTF-8" />\
                        <link rel="stylesheet" type="text/css" href="website/css/base_mobile.css" />\
                        <link rel="shortcut icon" href="website/favicon.ico" />\
                        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\
                        <link rel="stylesheet" type="text/css" href="website/css/about.css" />\
                        <link rel="stylesheet" type="text/css" href="website/css/contact.css" />\
                        <link rel="stylesheet" type="text/css" href="website/css/email.css" />\
                        <title>盛隆电气集团欢迎您!</title>\
                    </head>';
    this.body = [];
    this.body.push('<body>\
                    <div class="wrapper">\
                        <div class="slider">\
                            <div class="counselAndFeedback">\
                            </div>\
                            <div class="title">\
                            </div>\
                        </div>\
                        <div class="content">\
                            <div class="content_wrap clearfix">\
                                <div class="page_main">\
                                    <div class="page_content">\
                                        <form id="form" onsubmit="return false;" class="comment_box">\
                                            <div class="form_title">\
                                                感谢您的留言,我们会认真参阅您的意见与建议,<br />\
                                                盛隆的明天会因您的关注与支持而更美好！\
                                            </div>\
                                            <div class="comment_form">\
                                                <div class="item clearfix">\
                                                    <label><span>*</span>姓名:</label>\
                                                    <input class="txt" type="text" id="name" name="name" />\
                                                </div>\
                                                <div class="item clearfix">\
                                                    <label><span>*</span>邮箱:</label>\
                                                    <input class="txt" type="text" id="email" name="email"/>\
                                                </div>\
                                                <div class="item clearfix">\
                                                    <label><span>*</span>标题:</label>\
                                                    <input class="txt" type="text" id="title" name="title"/>\
                                                </div>\
                                                <div class="item clearfix">\
                                                    <label><span>*</span>留言:</label>\
                                                    <textarea id="comment" name="comment"></textarea>\
                                                </div>\
                                                <div class="submit_btn">\
                                                    <input type="submit" value="提交" id="submit_btn" name="sub"/>\
                                                </div>\
                                            </div>\
                                        </form>\
                                    </div>\
                                </div>\
                            </div>\
                        </div>\
                    </div>\
                    <script type="text/javascript" src="website/js/zepto.min.js"></script>\
                    <script type="text/javascript">\
                        var url = "http://m.shenglong-electric.com.cn/email/postEmail";\
                        $(document).ready(function() {\
                            $("#form").bind("submit", function(e) {\
                                var form = document.getElementById("form");\
                                form.action = url;\
                                form.method = "post";\
                                if(typeof Ti != "undefined") {\
                                    Ti.App.fireEvent("app:submit", {\
                                        name: $("#name").val(),\
                                        email: $("#email").val(),\
                                        title: $("#title").val(),\
                                        comment: $("#comment").val(),\
                                        sub: $("#sub").val()\
                                    });\
                                } else {\
                                    form.submit();\
                                }\
                                return false;\
                            });\
                            if(typeof Ti != "undefined") {\
                                if(typeof Ti != "undefined") {\
                                    setTimeout(function() {\
                                        Ti.App.fireEvent("app:hideLoading", {\
                                        });\
                                    }, 200);\
                                }\
                            }\
                        });\
                    </script>\
                </body>\
            </html>');
    //继承属性
    T.Template.call(this, opts);
};

//继承方法
T.PageCounselAndFeedback.prototype = new T.Template();