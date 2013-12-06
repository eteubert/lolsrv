var images = $.makeArray(document.querySelectorAll('.lolimage'));
var pos = -301;
var lazy = function() {
    var indexes = [],
        h = window.innerHeight + 100,
        y = window.scrollY;

    if(y - pos < 300 && !images.length) {
        return;
    }
    pos = y;

    images.forEach(function(image, i) {
        var top = image.getBoundingClientRect().top;
        if(top<h) {
            indexes.push(i);
        }
    });

    indexes.sort(function(a, b){
        return b > a;
    }).forEach(function(n){
        images[n].src = images[n].getAttribute('data-src');
        console.log(n);
        images.splice(n,1);
    });
};
$(function(){
    lazy();
    $(window).scroll(lazy);
});
