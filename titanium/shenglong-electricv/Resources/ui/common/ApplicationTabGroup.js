var messageWin;
function ApplicationTabGroup() {
	//create module instance
	var self = Ti.UI.createTabGroup();
	
	var WelcomeWindow = require('ui/common/WelcomeWindow');
	var welcomeWindow = new WelcomeWindow();
	welcomeWindow.menuWindow = null;

	var tabGroupHelper = require("ui/helper/tabGroupHelper");
	tabGroupHelper.createAppTabs(self, welcomeWindow);

	tabGroupHelper.bindEvent(self, welcomeWindow);
	self.setActiveTab(0);
	return self;
};

module.exports = ApplicationTabGroup;
