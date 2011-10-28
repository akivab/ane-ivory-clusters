// global variables
// num_points -- the number of clusters
var num_points = 2;
// objects contains an array of (pic, position, and index)
var objects = [];
var obj_map = {};
var radius;
var radii = [];
var imgsize;
var pos = [];
var descriptions = {};
var liftedObj;
var closestCluster = 0;

/**
Resets the positions given another set of k values.
*/
void reset(np){
    num_points = np;
    jQuery.get("data/posterior_factorized_k"+num_points+".json", function(data){ position(jQuery.parseJSON(data)); });
}

/**
Starts up the animation by loading the data and then setting the descriptions, finally changing the #go innerHTML to "Let's go"
*/
void startup(np){
    num_points = np;
    jQuery.get("/data/posterior_factorized_k"+num_points+".json", function(data){ load(jQuery.parseJSON(data)); });
    jQuery.get("/data/description.json", function(data){ descriptions = jQuery.parseJSON(data); $("#go").html("Let's go!");});
}

/**
Loads data for the first time
*/
void load(data){
    // sets position using data loaded
    setPos(data);
    for(var i in data){
	    var tmp = new Array(0,0,0,0);
	    var str = "/images/"+i+".jpg";
	    obj_map[i] = tmp;
	
	    objects.push([loadImage(str) ,tmp, i]);
    }
    console.log("finished loading images");
    position(data);
}

/**
Positions the data, without loading the images 
*/
void position(data){
    radius = Math.min(width,height) / 3;
    setPos(data);
    others = [0];
    var idx = 0;
    for(var i in data){
    	var this_pos = new Array(0,0);
	    for(var j=0;j<num_points;j++){
	        var k = j+1;
	        var p = parseFloat(data[i]["Probability"+k]);
	        this_pos[0]+=pos[j][0]*p;
	        this_pos[1]+=pos[j][1]*p;
	    }
	    obj_map[i][0] = this_pos[0];
	    obj_map[i][1] = this_pos[1];
	    obj_map[i][2] = this_pos[0];
	    obj_map[i][3] = this_pos[1];
    }
    console.log("added images");
}
   
/**
Sets the position of a bunch of clusters
*/
void setPos(data){
    pos = [];
    radii = [];
    // we store the number of datapoints in tpoints
    var tpoints = 0;
    for(var tmp in data) tpoints++;

    for(var k=1;k<=num_points;k++){
	    var tmpsum = 0;
	    for(var i in data){
            // tmpsum holds the contribution of this cluster
	        var p = parseFloat(data[i]["Probability"+k]);
	        tmpsum += p;
	    }
        // the radius of this cluster is equal to the contribution of one cluster / all clusters
	    radii.push(tmpsum / tpoints * 4 * radius);
    }
    for(var i=0; i<num_points; i++){
	    var tmp = i/num_points * 2 * Math.PI;
        // position clusters around center, with radius determined by radii[i]
	    pos.push(new Array(radii[i]*Math.cos(tmp), radii[i]*Math.sin(tmp)));
    }
    // make sure to drop any lifted objects (not needed when setting position of clusters)
    dropLifted();
    console.log("set positions of circles");
}

/**
Setup -- the first method called in the animation
*/
void setup() {
    // sets size of canvas
    size(900,500);
    startup(num_points);
    // sets radius
    // adds slider
    $( "#slider" ).slider({min:2, max:5, step:1, slide: function( event, ui ) {
		reset(ui.value);
		$("#clusters").val(ui.value + " clusters");
	    }});
}

/**
Gets color of i'th cluster
*/
void getColor(i){
    var tmp = i/num_points * 2 * Math.PI;
    return color(256*sin(tmp+Math.PI*1/15), 256*sin(tmp+Math.PI*7/15), 256*sin(tmp+Math.PI*5/15),100);
}


/**
Resizes width of canvas if animation is occuring
*/
void checkWidth(){
    if(width != parseInt($("#demo").css("width"))) size(parseInt($("#demo").css("width")), 500);
}

/**
Checks if we are performing a search
*/

void checkSearch(){
    if(parseInt($("#close").css("width"))==1){
	    $("#close").css("width","2");
	    $("#close").html("close");
	    $("#index").append("<div id='search'></div><ul id='searchopt'></ul>");
	    for(var i in descriptions){
	        var word = descriptions[i];
	        var key = i;
	        var museum = word['Museum'];
	        var site = word['Site'];
	        $("#searchopt").append("<li class='searchitem' id='"+key+"'><img width='50' height='50' style='float: left;' src='/images/"+key+ ".jpg' /> <span style='width:160px; float: right'>"+key+"<br /> "+museum+"</span></li>");
	    }
    }
}

var frame;
// blow lets us now if we should be moving images away in "blown away" style
var blow = false;
// TIME_DELAY is time before animation stops
var TIME_DELAY = 1000;
// others carries "blown away" images. first value in array = last frame blown away
var others=[0];
// drawLater gives us mouseOvered images
var drawLater = [];

var drawnSince = 0;
/**
Main method, draw. Called every time something is drawn
*/
void draw() {
    frame++;

    checkWidth();
    checkSearch();
    var num_close = 0;

    // find out how many images are close to us right now
    for(var i in objects) 
	    if(close(objects[i][1][0]+width/2,objects[i][1][1]+height/2)) 
	        num_close++;

    if(num_close == 0)
	if(frame - drawnSince > TIME_DELAY/2){ return; }
	else drawnSince = frame;

    background(256,256,256);
    noStroke();
    
    // get nearest cluster (for info tab)
    colorClosest();

    drawLater = [];

    // draw the clusters
    for(var i in pos){
	    fill(getColor(i));
	    ellipse(pos[i][0]+width/2, pos[i][1]+height/2, radii[i]*2, radii[i]*2);
    }
    
    // get img sizes for the images
    imgsize = radius/4;

    
    // if fewer than 2, don't bother blowing out
    if(num_close < 2)
    	blow = false;

    if(blow) 
	    others=[frame];

    for(var i=0; i < objects.length; i++){
        // for each image object, ignore if lifed
	    if(objects[i]==liftedObj) continue;
	    var img = objects[i][0];
	    var imgpos = objects[i][1];
        // figure out its position
	    var x = imgpos[0] + width/2;
	    var y = imgpos[1] + height/2;
	    var imgsize = radius/4;
	
	    if(close(x,y)){
            // if the image is close, either blow it away OR
            // magnify it
	        if(blow){
		        others.push(objects[i]);
		        drawImg(objects[i],imgsize);
	        }
	        else{
    		    drawLater.push(objects[i]);
	        }
	    }
	    else{
            // otherwise, just draw it.
	        drawImg(objects[i],imgsize);
	    }
    }

    blow = false;
    
    // draws the "blown away" images
    drawOthers();

    for(var j in drawLater){
        // draws the later images
    	drawImg(drawLater[j], radius/1.5);
    }

    if(liftedObj){
        // if an objects has been lifted, draws it last.
	    var imgsize = radius/2;
	    fill(256,256,256,100);
	
	    drawImg(liftedObj, imgsize, true);
    }

}

/**
Draws the blown away images
*/
void drawOthers(){
    var lf = others[0];
    var r;
    var lr;
    // calculate spreading
    if(frame-lf < TIME_DELAY){
	    r = 2/Math.sqrt(frame-lf+1);
	    lr = 2/Math.sqrt(frame-lf+2);
    }
    else{
        // if we're past the TIME_DELAY, don't move!
	    lr = 0;
	    r = 0;
    }
    
    imgsize = radius/4;
    for(var i in others){
	    if(i == 0) continue;
	    var xoff, yoff;
	    var dx = imgsize*Math.cos(i/others.length * Math.PI * 2);
	    var dy = imgsize*Math.sin(i/others.length * Math.PI * 2);
	    xoff = r*dx;
	    yoff = r*dy;
	    others[i][1][0] += xoff-lr*dx;
	    others[i][1][1] += yoff-lr*dy;
    }
}

/**
Draws an image
*/
void drawImg(var obj, var sz, var d){
    var bsz = radius/4;
    
    for(var o in others)
        // don't draw if image is seen in others
	    if (o[1]==obj[1]) 
	        return;
        
    var tx = obj[1][0] + width/2;
    var ty = obj[1][1] + height/2;
    var img = obj[0];
    var x = Math.min(Math.max(tx, bsz/2), width-bsz/2);
    var y = Math.min(Math.max(ty, bsz/2), height-bsz/2);
    
    if(d){
    	ellipse(x,y,sz*2.6,sz*2.6);
    }
    obj[1][0] = x - width/2;
    obj[1][1] = y - height/2;
    
    stroke(100);
    sz = sz * width / 500;
    image(img, x-sz/2, y-sz/2, sz, sz);
    line(x, y, obj[1][2]+width/2, obj[1][3]+height/2);
}

/**
Tells us if a point is close or not
*/
boolean close(var x, var y, var d){
    
    if(!d){
    	d = radius*radius/16;
    }
    var a = x - mouseX;
    var b = y - mouseY;
    return a*a+b*b< d
}


/**
Colors the info panel with cluster info
*/
void colorClosest(){
    var d = 99999;
    var mi = '';
    for(var i in pos){
	var x = pos[i][0] + width/2;
	var y = pos[i][1] + height/2;
	if(close(x,y,d)){
	    var a = x - mouseX;
	    var b = y - mouseY;
	    d = a*a + b*b;
	    mi = i;
	}
    }
    var c = getColor(mi);
    closestCluster = mi;

    setInfo(c);
}

/**
Sets info panel
*/
void setInfo(var c){
    if($("#info")){
	var innerHtml = "";
	if(liftedObj){
	    innerHtml = "<div id='color'><img width='100' height='100' src='/images/"+ liftedObj[2]+".jpg' /></div>";
	    innerHtml += "<div id='description'>" +
		"Image " + liftedObj[2] + " is characterized as follows: <br /> " + describe(descriptions[liftedObj[2]]) +
		"</div>";

	}
	else{
	    innerHtml = "<div id='color' style='opacity: 0.5; background-color: #" + hex(c,6) + "'></div>";
	    
	    var str = radii[closestCluster]/(radius*4)*100;
	    k = str.toString().indexOf(".");
	    str = str.toString().substring(0,k+2);
	    innerHtml += "<div id='description'>" +
		"Cluster " + closestCluster + " contains %" + str + " of points." +
		"</div>";
	}
	
	$("#info").html(innerHtml);
    }
    
}

/**
Tells us if an object is nearby
*/
boolean isNearby(obj){
    var imgpos = obj[1];
    var x = imgpos[0] + width/2;
    var y = imgpos[1] + height/2;
    return close(x,y,radius*radius/16);
}


var lastClick = 0;
/**
Called when mouse is pressed
*/
void mousePressed(){
    // tells us if we triggered blow out
    if(frame - lastClick < 20){ 
	    dropLifted(); 
	    blow = true; 
	    lastClick = frame; 
	    return;
    }
    
    lastClick = frame;
    
    if(liftedObj && isNearby(liftedObj))
    	return;

    if(drawLater){
	    drawLater.reverse();
	    liftedObj = drawLater[0];
	    return;
    }
    
    for(var i=objects.length-1;  i>=0; i--){
	    if(isNearby(objects[i])){
	        liftedObj = objects[i];
	        return;
	    }
    }

    dropLifted();
}

/**
Called when mouse is dragged
*/
void mouseDragged(){
    if(liftedObj){
	    var imgpos = liftedObj[1];
	    imgpos[0] = mouseX - width/2;
	    imgpos[1] = mouseY - height/2;
    }
}

/**
Drops the object that was lifted (if such an object exists)
*/
void dropLifted(){
    console.log("dropping liftedobj");
    liftedObj = null;
}

/**    radius = Math.min(width,height) * num_points / (num_points+5);
Describes a cluster
*/
String describe(var arr){
    var toReturn = "";
    for(var i in arr){
	    toReturn += i + ": " + arr[i] + ", ";
    }
    return toReturn;
}
	