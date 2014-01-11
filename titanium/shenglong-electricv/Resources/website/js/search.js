$(function(){
    $('.cur_sort').click(function(e){
        e.preventDefault();
        var sibling = $(this).siblings('ul');
        var style = sibling.css('display');

        if(style!='none'){
            sibling.hide();
        }else{
            sibling.show();
        }
    });

    $('.search_box li').click(function(){
        var val = $(this).text();
        var form = $(this).closest('.s_list').siblings('form');
        var title = $(this).attr('title');

        $('.cur_sort').text(val);
        $(this).closest('ul').hide();
        form.prop('action','/search/index/m/'+title);
    });

    $('.s_sub').click(function(e){
        console.log($(this).closest('form').attr('action'));
    })
})