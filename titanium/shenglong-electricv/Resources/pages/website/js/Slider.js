/**
 * Slider图片轮播
 * @elem    轮播DOM对象
 * @options 初始化配置选项
 */
function Slider(elem,options){
    //检测是否传入轮播的对象
    if(!elem) return;

    var config = options || {}; //如果未自定义配置，则使用默认参数
    config.speed = options.speed || 300; //动画完成速度，默认300ms
    config.autoPlay = options.autoPlay || false; //是否自动轮播
    config.autoTime = options.autoTime || 3000; //自动轮播间隔秒数,默认3'
    config.thumbs = options.thumbs || true; //设置thumbnails
    config.swipe = options.swipe || false; //是否支持touch扫屏

    var slider = elem, //获取当前轮播对象
        sliderBox = slider.querySelector('.slider_box'); //获取slider内包裹容器

    //克隆一组元素,用于轮播初始化占位
    var firstNew = slider.querySelector('a:first-child').cloneNode(true),
        lastNew = slider.querySelector('a:last-child').cloneNode(true);

    var fragment = document.createDocumentFragment();
    fragment.appendChild(firstNew);
    fragment.appendChild(lastNew);
    sliderBox.appendChild(fragment); //插入页面

    var slides = slider.querySelectorAll('a'), //获取所有的轮播item
        index = 0, //初始化索引
        movePos = 0, //初始化当前transform的移动位置
        num = slides.length, //获取轮播图片数量
        startData = {}, //touchstart事件触发时坐标对象
        offset = {}, //动画偏移量
        flag = false; //动画补位是否成功

    //检测是否需要thumbnanils
    if(config.thumbs){
        addThumbnaill();
    }

    setUp(); //初始化动画

    //自动加载
    if(options.autoPlay){
        autoAnim();
    }

    //初始化动画函数
    function setUp(){
        sliderW = slider.offsetWidth; //获取容器宽度
        last = slider.querySelector('a:last-child'); //获取最后一个元素

        setStyle(sliderBox,'width',sliderW*num + 'px'); //设置整个容器宽度
        setStyle(last,'left',-sliderW * num+'px'); //设置最后一张图片位置

        var pos = num;
        while(pos--){
            slides[pos].style.width = sliderW + 'px'; //设置每个元素的宽度
        }

        //检测是否开启扫屏
        if(config.swipe){
            slider.addEventListener('touchstart',start,false);
            slider.addEventListener('touchmove',move,false);
            slider.addEventListener('touchend',end,false);
        }

        slider.addEventListener('webkitTransitionEnd', transEnd, false);
        slider.addEventListener('transitionend', transEnd, false);

    }

    //touchstart
    function start(e){
        var event = e.touches[0];
        if(event.target)
            startData.x = event.pageX;
        startData.y = event.pageY;
        startTime = new Date(); //获取动画开始时间戳
    }

    //touchmove
    function move(event){

        // 确保当前touch事件操作动作手指为1
        if ( event.touches.length > 1 || event.scale && event.scale !== 1) return;

        //如果动画初始化为自动轮播，在touchmove的时候，清楚自动轮播动画
        if(config.autoPlay){
            stop();
        }

        offset.x = event.touches[0].pageX - startData.x;
        offset.y = event.touches[0].pageY - startData.y;

        //检测用户手指左右滑动和上下移动的距离，如果上下滑动的距离大于左右移动的距离，则判定为滚动页面，那么取消滑动
        if(Math.abs(offset.x) < Math.abs(offset.y)){
            return ;
        }
        event.preventDefault();

        if((index<0 || index >= num-2) && !flag ){
            offset.x = 15 * -index / Math.abs(index);
            translate(sliderBox,offset.x+movePos,0);
        }else{
            translate(sliderBox,offset.x+movePos,0);
        }

    }

    //touchend
    function end(event){
        //时间必须大于100毫秒，并且手指移动距离为15px
        var animTime = Number(new Date() - startTime) > 100 && Math.abs(offset.x) > 15;

        //检测动画是否成立
        if(animTime){
            if(offset.x<0){//右移
                if(index>=num-2){ //检测是否是最后一张
                    if(flag){
                        index++;
                        translate(sliderBox,-sliderW*(index),config.speed); //当前一张移动上次记录的值减去当前移动宽度
                        movePos = -sliderW*(index);
                        //并且移动指针到下一位，确保下次动画顺利进行补位
                    }else{
                        translate(sliderBox,movePos,config.speed);
                    }
                }else{
                    index++;
                    translate(sliderBox,-sliderW*(index),config.speed); //当前一张移动上次记录的值减去当前移动宽度
                    movePos = -sliderW*(index);
                    //并且移动指针到下一位，确保下次动画顺利进行补位
                }
            }else{//左移
                if(index<0){ //检测是否抵达第一张
                    if(flag){
                        index--;
                        translate(sliderBox,-sliderW * (index),config.speed);
                        movePos = -sliderW*(index); //记住当前位置
                    }else{
                        translate(sliderBox,movePos,config.speed);
                    }
                }else{
                    index--;
                    translate(sliderBox,-sliderW * (index),config.speed);
                    movePos = -sliderW*(index); //记住当前位置
                }
            }

        }else{
            translate(sliderBox,movePos,config.speed);
        }

        slider.removeEventListener('move');
        slider.removeEventListener('end');

    }

    //移动元素
    function translate(slide, dist, speed) {
        flag = 0;
        var style = slide && slide.style;
        if (!style) return;

        style.webkitTransitionDuration =
            style.OTransitionDuration =
                style.transitionDuration = speed + 'ms';

        style.webkitTransform = 'translate(' + dist + 'px,0)' + 'translateZ(0)';
        style.OTransform =
            style.transform = 'translateX(' + dist + 'px)';
    }

    //transtion done
    function transEnd(){
        if(index >= num-2){
            translate(sliderBox,0,0);
            movePos = 0;
            index = 0;
            flag = 1;
        }else if(index<0){
            index = index + num-2;
            movePos = -sliderW * index;
            translate(sliderBox,movePos,0);
            flag = 1; //补位成功
        }

        if(config.thumbs){
            setThumbs();
        }

        //检测是否自动轮播
        if(config.autoPlay){
            autoAnim();
        }
    }

    //切换当前thumbs状态
    function setThumbs(){
        var thums = document.querySelectorAll('.thumbs span');
        for(var i=0;i<thums.length;i++){
            if(index==i){
                thums[i].className = 'cur';
            }else{
                thums[i].setAttribute('class','');
            }
        }
    }

    function stop(){
        clearTimeout(interval);
    }

    function autoAnim(){
        //自动执行下一张
        interval = setTimeout(animate,config.autoTime);
    }

    function animate(){
        index++;
        translate(sliderBox,-sliderW * index,config.speed);
        movePos = -sliderW * index;
    }


    //添加缩略图
    function addThumbnaill(){
        var div = document.createElement('div');
        div.setAttribute('class','thumbs');

        var thumbs = '<div class="thumbs_inner">';
        for(var i=0;i<num-2;i++){
            if(i==0){
                thumbs += '<span class="cur">';
            }else{
                thumbs += '<span>';
            }
            thumbs += i;
            thumbs += '</span>';
        }
        thumbs += '</div>';
        div.innerHTML = thumbs;
        slider.appendChild(div);//插入DOM
    }

    //调整窗口时重新渲染动画
    window.addEventListener('resize',function(){
        slider.removeEventListener('webkitTransitionEnd', transEnd, false);
        slider.removeEventListener('transitionend', transEnd, false);
        setUp();
    });

    /*
     * 获取DOM元素样式
     * elem DOM节点
     * val css样式值
     */
    function getStyle(elem,val){
        return document.defaultView.getComputedStyle(elem, "").getPropertyValue(val);
    }

    /*
     * 设置DOM元素样式
     * elem DOM节点
     * prop css属性
     * val 样式值
     */
    function setStyle(elem,prop,val){
        if(elem.length && elem.length>1){
            for(var i=0;i<elem.length;i++){
                elem[i].setAttribute('style',prop+':'+val+';');
            }
        }else{
            elem.style[prop] = val;
        }
    }

}
