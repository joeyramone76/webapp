/**
 * 国际化模块
 * @dependencies: none
 */
define(function(require, exports, module) {
	var Cn = {
		error : "无法播放该资源",
		playpauseText : "播放/暂停(空格键)",
		notSupportedMessage : "不支持该文件格式播放",
		fullscreenText : "全屏/还原(回车键)",
		muteText : "音量调节",
		/**广告参数*/
		timeout : "广告还有  ",
		second : " 秒结束",
		mute_text : "静音",// 广告用
		qualitySelect: "清晰度选择",
		pd: "超清",
		hd: "高清",
		sd: "标清",
		soft: "流畅"
	};
	module.exports = Cn;
});