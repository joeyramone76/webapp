exports.info = function(str) {
    Titanium.API.info(new Date() + ': ' + str);
};
 
exports.debug = function(str) {
    Titanium.API.debug(new Date() + ': ' + str);
};

exports.log = function(level, str) {
	Titanium.API.log(level, new Date() + ': ' + str);
};

exports.timestamp = function(str) {
	Titanium.API.timestamp(str);
};
