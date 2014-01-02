requirejs.config({
    //By default load any module IDs from js/lib
    baseUrl: 'js/lib',
    //except, if the module ID starts with "app",
    //load it from the js/app directory. paths
    //config is relative to the baseUrl, and
    //never includes a ".js" extension since
    //the paths config could be for a directory.
    paths: {
        app: '../app',
		jquery: 'jquery-1.9.1',
		util: '../helper/util',
		jquery-mobile: 'jquery.mobile-1.3.2'
    }
});

requirejs(["app/app", "util"], function(app, util) {
	
})