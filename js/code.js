var SMALL = 70;
var MEDIUM = 100;
var BIG = 140;
var WIDTH = 900;
var HEIGHT = 400;
var SELECTED = null;

/* Returns the size of a map */
function GET_SIZE(obj){
    count = 0;
    for(var i in obj)
	count++;
    return count;
}

function TO_STRING(obj){
    var str = "";
    str += "<a class='link-to-larger' target='_blank' href='/images/"+obj["Key"]+".jpg'>"+obj["Key"]+"</a>. "
    str += "from "+obj["Site"]+", now at the " + obj["Museum"] +" (type: "+obj["Type"]+")";
    return str;
}

function range(i,j){
    if(!j) return range(0,i);
    var arr = [];
    for(var k = i; k < j; k++)
	arr.push(k);
    return arr;
}

function distance(x1, y1, x2, y2){
    var a = (x1-x2);
    var b = (y1-y2);
    return a*a+b*b;
}
    

var Modification = {
    blown: false,
    magnified: false,
    selected: false,
    searched: false
}

var ArtObject = {
    x: 0,
    y: 0,
    circles: null,
    data: null,
    img: null,
    mod: null,
    id: 0,
    mouse: null,
    origin: null,
    blown: null,
    getSize: function(){
	if(this.isModified() && !this.mod.blown)
	    return MEDIUM;
	return SMALL;
    },
    isClose: function(x,y){
	return Math.abs(this.x - this.mouse.x) < this.getSize()/2
	    && Math.abs(this.y - this.mouse.y) < this.getSize()/2;
    },
    setBlown: function(idx, count){
	this.blown.x = 20*Math.cos(idx/count * 2 * Math.PI);
	this.blown.y = 20*Math.sin(idx/count * 2 * Math.PI);
    },
    blow: function(time){
	this.x += this.blown.x * 1/time;
	this.y += this.blown.y * 1/time;
    },

    setMouse: function(x, y){
	this.mouse.x = x;
	this.mouse.y = y;
    },
    drag: function(){
	this.x = this.mouse.x;
	this.y = this.mouse.y;
    },
    dist: function(){
	return distance(this.mouse.x, this.mouse.y, this.x, this.y);
    },
    isModified: function(){
	var toReturn = false;
	for(var i in this.mod)
	    toReturn |= this.mod[i];
	return toReturn;
    },
    clear: function(){
	for(var i in this.mod)
	    this.mod[i] = false;
    },
    setLocation: function(){
	var x = 0;
	var y = 0;
	for(var i in this.circles){
	    var probability = parseFloat(this.data["Probability" + i]);
	    x += probability * this.circles[i].x;
	    y += probability * this.circles[i].y;
	}
	this.x = this.origin.x = x;
	this.y = this.origin.y = y;
    },
    drawOval: function(processing){
	var color = null;
	if(this.isModified()){
	    if(this.mod.searched)
		color = processing.color("#FFCC00");
	    if (this.mod.selected)
		color = processing.color(40,40,40);
	    if(color){
		processing.stroke(color);
		processing.fill(color, 100);
		processing.ellipse(this.x, this.y, BIG, BIG)
	    }
	}
    },
    draw: function(processing){
	this.drawOval(processing);
	this.x = Math.max(Math.min(WIDTH, this.x), 0);
	this.y = Math.max(Math.min(HEIGHT, this.y),0);
	if(!this.img.width){
	    var m = this.getSize() / 2;
	    processing.image(processing.util.getLoading(), this.x, this.y);
	}
	else{
	    processing.image(this.img, this.x, this.y, this.getSize(), this.getSize());
	    processing.stroke(0);
	    processing.line(this.x, this.y, this.origin.x, this.origin.y);
	}
    },
    get_image_name: function(){
	return "/images/" + this.id + ".jpg";
    },
    getImage: function(processing){
	this.img = processing.loadImage(this.get_image_name());
    },
    init: function(id, data, circles, description, processing){
	this.id = id;
	this.data = data;
	this.mouse = {x: 0, y: 0};
	this.origin = {x: 0, y: 0};
	this.blown = {x: 0, y:0};
	this.mod = Object.create(Modification);
	this.circles = circles;
	this.description = description;
	this.setLocation();
	this.getImage(processing);
    },
    update: function(data, circles){
	this.data = data;
	this.circles = circles;
	this.setLocation();
	this.mod = Object.create(Modification);
    }
}

var CircleObject = {
    x: 0,
    y: 0,
    radius: 0,
    id: 0,
    color: null,
    radians: 0,
    clusters: 0,
    percent: 0,
    mouse: null,
    setRadius: function(data){
	var size = GET_SIZE(data);
	var total = 0;
	for(var row in data)
	    total += parseFloat(data[row]["Probability" + this.id]);
	this.percent = total / size * 100;
	this.radius *= this.percent / 100;
    },

    setLocation: function(){
	this.radians = (this.id-1) / this.clusters * 2 * Math.PI;
	this.x += Math.cos(this.radians) * this.radius/2;
	this.y += Math.sin(this.radians) * this.radius/2;
    },
    setColor: function(colorFunction){
	this.color = colorFunction(255 * Math.sin(this.radians + this.id/this.clusters),
				   255 * Math.sin(this.radians + this.id/this.clusters * 2),
				   255 * Math.sin(this.radians + this.id/this.clusters * 3));
    },    
    
    init: function(id, processing, data, clusters){
	this.id = id;
	this.x = processing.width / 2;
	this.y = processing.height / 2;
	this.mouse = {x:0, y:0};
	this.radius = processing.width * clusters / 2;
	this.clusters = clusters;
	this.setRadius(data);
	this.setLocation();
	this.setColor(processing.color);
    },
    dist: function(){
	return distance(this.mouse.x, this.mouse.y, this.x, this.y);
    },
    draw: function(processing){
	this.mouse.x = processing.mouseX;
	this.mouse.y = processing.mouseY;
	processing.stroke(this.color,100);
	processing.fill(this.color, 150);
	processing.ellipse(this.x, this.y, this.radius, this.radius);
    }
}

var Simulation = {
    objects: {},
    circles: {},
    info: null,
    clusters: 2,
    descriptions: null,
    data: null,
    ready: false,
    get_data_filename: function(){
	return "/data/posterior_factorized_k" + this.clusters + ".json";
    },
    get_description_filename: function(){
	return "/data/description.json";
    },
    reset: function(processing){
	this.circles = {};
	var arr = range(this.clusters);
	for(var i in arr){
	    var tmp = Object.create(CircleObject);
	    tmp.init(arr[i]+1, processing, this.data, this.clusters);
	    this.circles[tmp.id] = tmp;
	}
	for(var o in this.objects)
	    this.objects[o].update(this.data[o], this.circles);
    },
    startup: function(processing){
	this.ready = true;
	this.info = Object.create(InfoTab);
	this.info.init(processing);
	var arr = range(this.clusters);
	for(var i in arr){
	    var tmp = Object.create(CircleObject);
	    tmp.init(arr[i]+1, processing, this.data, this.clusters);
	    this.circles[tmp.id] = tmp;
	}
	for(var i in this.data){
	    var tmp = Object.create(ArtObject);
	    tmp.init(i, this.data[i], this.circles, this.descriptions[i], processing);
	    this.objects[tmp.id] = tmp;
	}
    },
    setBlownVectors: function(){
	var count = 0;
	var idx = 0;
	for(var o in this.objects)
	    if(this.objects[o].mod.blown)
		count++;
	if(count == 1) return;
	for(var o in this.objects)
	    if(this.objects[o].mod.blown)
		this.objects[o].setBlown(idx++, count);	
    },
	
    draw: function(processing){
	if(!this.ready) return;
	if(SELECTED){
	    for(var o in this.objects)
		if(this.objects[o].mod.selected = (o==SELECTED)){
		    this.info.setImage(this.objects[o]);
		}
	    SELECTED = null;
	}
	this.updateObjects(processing);
	var min_distance = -1;
	var circ = null;
	for(var c in this.circles){
	    var circle = this.circles[c];
	    if(min_distance > circle.dist() || min_distance==-1){
		min_distance = circle.dist();
		circ = circle;
	    }
	    circle.draw(processing);
	}

	var magnified = [];
	var selected = [];
	var searched = [];
	for(var o in this.objects){
	    var obj = this.objects[o];
	    obj.mod.magnified = obj.isClose();
	    if(processing.util.stillBlowing() && obj.mod.blown)
		obj.blow(processing.util.timeBlown());
	    else
		obj.mod.blown = false;
	    if(!obj.isModified())
		obj.draw(processing);
	    else if(obj.mod.selected)
		selected.push(obj);
	    else if(obj.mod.searched)
		searched.push(obj);
	    else
		magnified.push(obj);
	}
	
	for(var i in magnified)
	    magnified[i].draw(processing);
	for(var i in searched)
	    searched[i].draw(processing);
	for(var i in selected)
	    selected[i].draw(processing);

	if(GET_SIZE(selected) == 0)
	    this.info.setCluster(circ);
    },
    updateObjects: function(processing, todo){
	if(Math.abs(processing.mouseX-processing.pmouseX) > 0)
	    for(var o in this.objects){
		var obj = this.objects[o];
		obj.setMouse(processing.mouseX, processing.mouseY);
	    }
    },
    mouseDragged: function(processing){
	for(var o in this.objects)
	    if(this.objects[o].mod.selected)
		this.objects[o].drag();
    },
    mousePressed: function(processing){
	this.updateObjects(processing);
	if(!processing.util.stillBlowing() && processing.util.isDoubleClick()){
	    processing.util.setBlown();
	    for(var o in this.objects)
		this.objects[o].mod.blown = this.objects[o].mod.magnified;
	    this.setBlownVectors();
	    processing.util.click();
	    return;
	}
	var selected = null;
	for(var o in this.objects)
	    this.objects[o].mod.selected = false;
	for(var o in this.objects)
	    if(this.objects[o].mod.searched && this.objects[o].mod.magnified)
		selected = this.objects[o];
	if(!selected)
	    for(var o in this.objects)
		if(this.objects[o].mod.magnified)
		    selected = this.objects[o];
	if(selected){
	    selected.mod.selected = true;
	    this.info.setImage(selected);
	}
	processing.util.click();
    }
}

var ProcessingUtility = {
    loading_prefix: "/images/loading_",
    max: 8,
    images: {},
    count: 0,
    lastClick: 0,
    lastBlown: 0,
    time: 0,
    init: function(processing){
	for(var i in range(this.max)){
	    this.images[i] = processing.loadImage(this.loading_prefix + i + ".gif");
	}
    },
    getLoading: function(){
	return this.images[this.count%this.max];
    },
    isDoubleClick: function(){
	return this.time - this.lastClick < 10;
    },
    setBlown: function(){
	this.lastBlown = this.time;
    },
    timeBlown: function(){
	return this.time - this.lastBlown;
    },
    stillBlowing: function(){
	return this.timeBlown() < 30;
    },
    click: function(){
	this.lastClick = this.time;
    },
    update: function(){
	if(this.time % 2 == 0)
	    this.count++;
	this.time++;
    }
}


var SearchBar = {
    search: null,
    objects: null,
    info: null,
    lookup: function(value){
	var viable = [];
	for(var o in this.objects){
	    if(o.toLowerCase().indexOf(value.toLowerCase()) != -1){
		viable.push(this.objects[o]);
		this.objects[o].mod.searched = true;
	    }
	    else{
		this.objects[o].mod.searched = false;
	    }
	}
	this.info.setSearching(value, viable);
    },
    init: function(sim){
	this.search = $("#search");
	this.objects = sim.objects;
	this.info = sim.info;
	this.setup();
    },
    clearSearch: function(val){
	if(val.length >= 1) return;
	this.info.endSearching();
	for(var o in this.objects)
	    this.objects[o].mod.searched = false;
    },
    setup: function(){
	var searchBar = this;
	this.search.bind('click', function(){
	    this.select();
	    searchBar.info.startSearch();
	});
	this.search.bind('keyup', function(){
	    var val = $(this).val();
	    if(val.length > 0)
		searchBar.lookup(val);
	});
	this.search.bind('blur', function(){
	    var val = $(this).val();
	    searchBar.clearSearch(val);
	    if(val.length < 1)
		$(this).val("Search");
	    
	});
    }
}

var InfoTab = {
    title: null,
    description: null,
    box: null,
    image: null,
    div: null,
    processing: null,
    possibilities: null,
    searching: false,
    index: 0,
    init: function(processing){
	this.title = $("<h1 id='info-header'>&nbsp;</h1>");
	this.description = $("<p id='info-p'>&nbsp;</p>");
	this.box = $("<div id='info-box'>&nbsp;</div>");
	this.possibilities = $("<div id='possibilities'></div>");
	this.image = $("<img />");
	this.index = 0;
	this.div = $("#info-div");
	this.div.append(this.title);
	this.div.append(this.description);
	this.div.append(this.box);
	this.processing = processing;
    },
    endSearching: function(){
	var thisObj = this;
	this.title.animate({ "margin-left": "75px"}, function(){
	    thisObj.box.appendTo(thisObj.div);
	    thisObj.description.appendTo(thisObj.div);
	});
	this.possibilities.detach();
	this.possibilities.html("");
	this.searching = false;
    },
    startSearch: function(){
	this.searching = true;
	this.box.detach();
	this.description.detach();
	this.title.animate({"margin-left": "25px"});
    },
    setSearching: function(value, viable){
	this.title.html("Searching for " + value + " (" + viable.length + " found)");
	if(viable.length < 1) return;
	this.possibilities.html("");
	for(var i in range(viable.length)){
	    var object = viable[parseInt(i) + this.index];
	    var toAdd = $("<div class='info-possibility' id='"+object.id+"'></div>");
	    var img = $("<img src='"+object.get_image_name()+"' />")
	    var idx = object.id.indexOf(value);
	    var html = object.id.substring(0,idx);
	    html +="<b>"+value+"</b>";
	    html += object.id.substring(idx+value.length);
	    var p = $("<p>"+html+"</p>");
	    toAdd.append(img);
	    toAdd.append(p);
	    this.possibilities.append(toAdd);
	}
	var poss = this.possibilities;
	this.possibilities.children().each(function(i,e){
	    var obj = $(e);
	    obj.click(function(){ 
		SELECTED = obj.attr("id");
		poss.children().each(function(i,e){$(e).removeClass("selected")});
		obj.addClass("selected");
	    });
	});
	if(viable.length){
	    var more = $("<a id='more' href='javascript:void(0)'>[+]</a>");
	    more.toggle(
		function(){
		    var height = Math.max(viable.length / 3,1);
		    $("#info-div").animate({height: (height * 25 + 75) + "px"},function(){
			$("#possibilities").animate({height: (height * 25) + "px"});
		    });
		    $("#more").html("[-]");
		},
		function(){
		    $("#possibilities").animate({height: 25 + "px"},function(){
			$("#info-div").animate({height: 75 + "px"});});
		    $("#more").html("[+]");
		});
	    
	    var close = $("<a id='close' href='javascript:void(0)'></a>");
	    var obj = this;
	    close.click(function(){
		$("#possibilities").animate({height: 25 + "px"},function(){
		    $("#info-div").animate({height: 75 + "px"});});
		obj.endSearching();
	    });
	    
	    this.possibilities.append(more);
	}
	this.possibilities.prepend(close);
	this.div.append(this.possibilities);
    },
    setCluster: function(cluster){
	if(this.searching) return;
	for(var o in this.objects) 
	    if(this.objects[o].mod.selected)
		return;
	this.image.detach();
	this.title.html("Info (about cluster " + cluster.id +")");
	this.description.html("Contains " + (""+cluster.percent).substring(0,5) +"% of images");
	this.box.html("&nbsp;");
	this.box.css({background: "#" + this.processing.hex(cluster.color,6)});
    },
    setImage: function(image){
	this.box.append(this.image);
	this.image.attr("src",image.get_image_name());
	this.title.html("Info (about image " + image.id +")");
	this.description.html(TO_STRING(image.description));
    }
}



var sketch = new Processing.Sketch();

sketch.attachFunction = function(processing) {  
    var sim = Object.create(Simulation);
    var search = Object.create(SearchBar);
    processing.util = Object.create(ProcessingUtility);
    processing.util.init(processing);
    $.get(sim.get_data_filename(), function(data){ 
	sim.data = data;
	$.get(sim.get_description_filename(), function(data){ 
	    sim.descriptions = data;
	    sim.startup(processing);
	    search.init(sim);
	});
    });
    $( "#slider" ).slider({min:2, max:5, step:1, slide: function( event, ui ) {
	sim.clusters = ui.value; 
	$.get(sim.get_data_filename(), function(data){ sim.data = data; sim.reset(processing); });
	$("#slider-info").val(ui.value + " clusters");
    }});
    $( "#slider" ).slider({min:2, max:5, step:1}).css({width: 200, margin: "auto"});
    
    
    processing.setup = function() {
	processing.size(WIDTH, HEIGHT);
	processing.fill(255);
	processing.imageMode(processing.CENTER);	
    };  
    
    processing.draw = function() {
	processing.background(255);
	processing.util.update();
	sim.draw(processing);
    }
    
    processing.mousePressed = function(){
	sim.mousePressed(processing);
    }
    
    processing.mouseDragged = function(){
	sim.mouseDragged(processing);
    }
}


$(document).ready(function(){
    new Processing(document.getElementById("canvas"), sketch);
    $("#about-big").click(function(){
	$("#about-big").detach();
    });
});