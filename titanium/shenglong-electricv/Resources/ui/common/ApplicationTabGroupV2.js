/**
 * Copyright(c)2013,zhangchunsheng,www.zhangchunsheng.com.cn
 * Version: 1.0
 * Author: zhangchunsheng
 * Date: 2014-02-15
 * Description: 创建tabGroup，window等，应用程序由此开始执行
 */
var messageWin;
function ApplicationTabGroup() {
	//构建tabGroup
	var TabGroupView = require('ui/common/view/TabGroupView');
	var self = new TabGroupView({});
	
	//welcomeWindow
	var WelcomeWindow = require('ui/common/WelcomeWindow');
	var welcomeWindow = new WelcomeWindow();
	welcomeWindow.menuWindow = null;

	//构建tab
	var tabGroupHelper = require("ui/helper/tabGroupHelperV2");
	tabGroupHelper.createAppTabs(self, welcomeWindow);
	tabGroupHelper.bindEvent(self, welcomeWindow);
	
	var visitInfo = Ti.App.Properties.getObject('Ti.App.visitInfo');
	self.setActiveTab(visitInfo.activeTabIndex);
	return self;
};

module.exports = ApplicationTabGroup;
