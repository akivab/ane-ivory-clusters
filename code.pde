var num_points = 2;
var objects = [];
var obj_map = {};
var bigData = {};
var radius;
var radii = [];
var imgsize;
var pos = [];
var liftedObj;
var lifted = false;
var closestCluster = 0;

void reset(np){
    num_points = np;
    jQuery.get("data/posterior_factorized_k"+num_points+".json", function(data){ position(jQuery.parseJSON(data)); });
}

void startup(np){
    num_points = np;
    jQuery.get("data/posterior_factorized_k"+num_points+".json", function(data){ load(jQuery.parseJSON(data)); });
}

void load(data){
    setPos(data);
    for(var i in data){
	var tmp = new Array(0,0,0,0);
	var str = "images/"+i+".jpg";
	obj_map[i] = tmp;
	
	objects.push([loadImage(str) ,tmp, i]);
    }
    console.log("finished loading images");
    position(data);
}

void position(data){
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

String pos2str(arr){
    return "(" + arr[0] + "," + arr[1] + ")";
}
		   
void setPos(data){
    bigData = data;
    pos = [];
    radii = [];
    var tpoints = 0;
    for(var tmp in data) tpoints++;

    for(var k=1;k<=num_points;k++){
	var tmpsum = 0;
	for(var i in data){
	    var p = parseFloat(data[i]["Probability"+k]);
	    tmpsum += p;
	}
	radii.push(tmpsum / tpoints * radius * 4);
    }
    for(var i=0; i<num_points; i++){
	var tmp = i/num_points * 2 * Math.PI;
	pos.push(new Array(radii[i]*Math.cos(tmp), radii[i]*Math.sin(tmp)));
    }
    dropLifted(true);
    console.log("set positions of circles");
}

void setup() {
    size(800,500);
    startup(num_points);
    radius = Math.min(width,height) * num_points / (num_points+5);
    $( "#slider" ).slider({min:2, max:5, step:1, slide: function( event, ui ) {
		reset(ui.value);
		$("#clusters").val(ui.value + " clusters");
	    }});
}

void getColor(i){
    var tmp = i/num_points * 2 * Math.PI;
    return color(256*sin(tmp+Math.PI*1/15), 256*sin(tmp+Math.PI*7/15), 256*sin(tmp+Math.PI*5/15),100);
}


var frame;
var blow = false;
var TIME_DELAY = 1000;
var others=[0];
var THRESHOLD = 10;
var drawLater = [];

void draw() {
	
    frame++;
    background(256,256,256);
    noStroke();

    colorClosest();

    drawLater = [];

    for(var i in pos){
	fill(getColor(i));
	ellipse(pos[i][0]+width/2, pos[i][1]+height/2, radii[i]*2, radii[i]*2);
    }
    

    imgsize = radius/4;
    var num_close = 0;

    for(var i in objects) 
	if(close(objects[i][1][0]+width/2,objects[i][1][1]+height/2)) 
	    num_close++;
    
    if(num_close < 2)
	blow = false;

    if(blow) 
	others=[frame];

    for(var i=0; i < objects.length; i++){
	if(objects[i]==liftedObj) continue;
	var img = objects[i][0];
	var imgpos = objects[i][1];
	var x = imgpos[0] + width/2;
	var y = imgpos[1] + height/2;
	var imgsize = radius/4;
	
	if(close(x,y)){
	    if(blow){
		others.push(objects[i]);
		drawImg(objects[i],imgsize);
	    }
	    else{
		drawLater.push(objects[i]);
	    }
	}
	else{
	    drawImg(objects[i],imgsize);
	}
    }

    blow = false;

    drawOthers();

    for(var j in drawLater){
	drawImg(drawLater[j], radius/1.5);
    }

    if(liftedObj){
	var img = liftedObj[0];
	var imgpos = liftedObj[1];
	var x = imgpos[0] + width/2;
	var y = imgpos[1] + height/2;
	var imgsize = radius/2;
	fill(256,256,256,100);
	ellipse(x,y,radius/1.4,radius/1.4);
	
	drawImg(liftedObj, imgsize);
    }

}

void drawOthers(){
    var lf = others[0];
    var r;
    var lr;
    if(frame-lf < TIME_DELAY){
	r = 2/Math.sqrt(frame-lf+1);
	lr = 2/Math.sqrt(frame-lf+2);
    }
    else{
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

void drawImg(obj, sz){
    var bsz = radius/4;
    
    for(var o in others) 
	if (o[1]==obj[1]) 
	    return;
    
    var tx = obj[1][0] + width/2;
    var ty = obj[1][1] + height/2;
    var img = obj[0];
    var x = Math.min(Math.max(tx, bsz/2), width-bsz/2);
    var y = Math.min(Math.max(ty, bsz/2), height-bsz/2);
    
    obj[1][0] = x - width/2;
    obj[1][1] = y - height/2;
    
    stroke(100);
    image(img, x-sz/2, y-sz/2, sz, sz);
    line(x, y, obj[1][2]+width/2, obj[1][3]+height/2);
}

boolean close(var x, var y, var d){
    if(!d){
	d = radius*radius/16;
    }
    var a = x - mouseX;
    var b = y - mouseY;
    return a*a+b*b< d
}


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

void setInfo(var c){
    if($("#info")){
	var innerHtml = "";
	if(liftedObj){
	    innerHtml = "<div id='color'><img width='100' height='100' src='images/"+ liftedObj[2]+".jpg' /></div>";
	    
	    innerHtml += "<div id='description'>" +
		"Image " + liftedObj[2] + " is characterized as follows: <br /> " + describe(bigData[liftedObj[2]]) +
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

boolean isNearby(obj){
    var imgpos = obj[1];
    var x = imgpos[0] + width/2;
    var y = imgpos[1] + height/2;
    return close(x,y,radius*radius/16);
}


var lastClick = 0;
void mousePressed(){

    if(frame - lastClick < 20){ 
	dropLifted(true); 
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

    dropLifted(true);
}

void mouseDragged(){

    if(liftedObj){
	var imgpos = liftedObj[1];
	imgpos[0] = mouseX - width/2;
	imgpos[1] = mouseY - height/2;
    }
}

void dropLifted(var setNull){
    console.log("dropping liftedobj");
    if(liftedObj){
	if(setNull) liftedObj = null;
    }
}

void mouseReleased(){
    dropLifted();
}

String describe(var arr){
    var toReturn = "";
    for(var i in arr){
	if(i.match(/Probability/))
	    toReturn += i + ": " + arr[i] + ", ";
    }
    return toReturn;
}
	