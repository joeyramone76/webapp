
-- Table: app_menus

CREATE TABLE IF NOT EXISTS app_menus ( 
    id            INT( 10 )       NOT NULL,
    menu_code     VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    menu_name     VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    menu_showName VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    type          INT( 1 )        NOT NULL
                                  DEFAULT '0',
    icon          VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    banner        VARCHAR( 255 )  NOT NULL
                                  DEFAULT '',
    url           VARCHAR( 255 )  NOT NULL
                                  DEFAULT '',
    sl_url        VARCHAR( 255 )  NOT NULL
                                  DEFAULT '',
    parentId      INT( 10 )       NOT NULL
                                  DEFAULT '0',
    hasSubMenu    INT( 1 )        NOT NULL
                                  DEFAULT '0',
    date          INT( 10 )       NOT NULL
                                  DEFAULT '0',
    parentCode    VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    pageId        VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    newsId        VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    sl_cid        VARCHAR( 60 )   NOT NULL
                                  DEFAULT '',
    PRIMARY KEY ( id ) 
);

INSERT INTO [app_menus] ([id], [menu_code], [menu_name], [menu_showName], [type], [icon], [banner], [url], [sl_url], [parentId], [hasSubMenu], [date], [parentCode], [pageId], [newsId], [sl_cid]) VALUES (1, 001, 'home', '关于盛隆', 0, '/images/tabs/home.png', '', '/website/page_template.html', '', 0, 1, 1389335674, '', '', '', '');