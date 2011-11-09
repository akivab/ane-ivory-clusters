var TIMEOUT = 500;

function setupIndexHover() {
    $("#index").hover(
	function(){ $("#index").attr("class", "popped out"); },
	function(){ $("#index").attr("class", "popped in") }
    );
}

function setupIndexClick(){
    $("#index").click(function(){ 
	$("#index").unbind("mouseenter mouseleave click"); 
	$("#demo").animate({"width": "700"});  
	$("#index").switchClass("popped","unpopped",TIMEOUT).toggleClass("out",  TIMEOUT).toggleClass("search", TIMEOUT);
	setupIndexClose();
	setTimeout(function(){setupIndexSearch()}, TIMEOUT*3);
    });
}

function setupIndexClose(){
    $("#close").click(function(){ 
	$("#searchopt").remove();
	$("#close").html("");
	$("#index").toggleClass("search",TIMEOUT).toggleClass("in", TIMEOUT).switchClass("unpopped","popped", TIMEOUT);
	$("#demo").animate({"width": "900"});
	$("#index").bind("mouseenter mouseleave click");
	
    });
}

function setupGo(){
    $( "#go" ).click(function(){ 
	$("#cover").remove(); 
	$("#about").animate({'height':0, 'margin-bottom':0}, 
			    TIMEOUT, 
			    function(){ 
				$("#about").remove(); 
				$("#about_link").html("?").attr("href","javascript:location=location;").attr("font-size", "15px"); 
			    });
    });
}

function setupIndexSearch(){
    $("#close").css("width","1");
    // dealt with by processingjs
}


function setupSlider(){
    $( "#slider" ).slider({min:2, max:5, step:1});
}


$(function(){
    setupIndexHover();
    setupIndexClick();
    setupGo();
    setupSlider();
});