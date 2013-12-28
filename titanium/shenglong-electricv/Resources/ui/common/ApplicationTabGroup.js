var messageWin;
function ApplicationTabGroup() {
	//create module instance
	var self = Ti.UI.createTabGroup();

	var tabGroupHelper = require("ui/helper/tabGroupHelper");
	tabGroupHelper.createAppTabs(self);

	tabGroupHelper.bindEvent(self);
	return self;
};

module.exports = ApplicationTabGroup;
