function GET_SIZE(obj){
    count = 0;
    for(var i in obj)
	count++;
    return count;
}

function GET_RADIUS(){
    return Math.min(width, height) / 3;
}

function SET_COLOR(circle){
    var tmp = circle.orientation * 2 * PI;
    return color(256*sin(tmp+Math.PI*1/15), 
		 256*sin(tmp+Math.PI*7/15), 
		 256*sin(tmp+Math.PI*5/15),100);
}



var ImageObject = {
    orig_x: 0,
    orig_y: 0,
    x: 0,
    y: 0,
    isSelected: false,
    isSearched: false,
    isBlown: false,
    isMagnified: false,
    data: {},
    id: 0,

    get_image_filename: function(){
	var image_prefix = "/images/";
	var image_ext = ".jpg";
	this.data = loadImage(this.image_prefix + this.id + this.image_ext);
    }
}

var CircleObject = {
    x: 0,
    y: 0,
    radius: 0,
    portion: 0,
    id: 0,
    orientation: 0,
    color: false
}

var Simulation{
    prefix: "/data/",
    data_file: "posterior_factorized_k",
    description_file: "description",
    ext: ".json",
    image_objects: {},
    circle_objects: {},
    get_data_filename: function(){
	return this.prefix + this.data_file + this.num_points + this.ext;
    },
    get_description_filename: function(){
	return this.prefix + this.description_file + this.ext;
    },
    reset: function(np){
	this.num_points = np;
	$.get(this.get_data_file(), 
	      function(data){ this.position(data); }
	     );
    },
    startup: function(np){
	this.num_points = np;
	$.get(this.get_data_filename(), 
	      function(data){ this.load(data); }
	     );
	$.get(this.get_description_filename(), 
	      function(data){ this.finalize_startup(data); }
	     );
    },
    finalize_startup: function(data){
	this.descriptions = data;
	$("#go").html("Let's go!");
    },
    load: function(data){
	this.set_circle_positions(data);
	for( var d in data ){
	    var tmp = Object.create(ImageObject);
	    tmp.id = d;
	    tmp.probabilities = data[d];
	    tmp.data = loadImage(tmp.get_image_filename());
	    this.image_objects[tmp.id] = tmp;
	}
	this.position();
    },
    position: function(){
	var radius = GET_RADIUS();
	for( var img in this.image_objects ){
	    for( var circle in this.circle_objects ){
		var probability = img.probabilities["Probability" + circle.id];
		img.orig_x += circle.x * probability;
		img.orig_y += circle.y * probability;
	    }
	    img.x = img.orig_x;
	    img.y = img.orig_y;
	}
    },
    set_circle_positions: function(data){
	var data_size = GET_SIZE(data);
	var radius = GET_RADIUS();
	for( var i = 1; i <= this.num_points ; i++ ){
	    var tmp = Object.create(CircleObject);
	    tmp.id = i;
	    for( var obj in this.image_objects )
		tmp.portion += obj.probabilities["Probability" + tmp.id];
	    tmp.portion /= data_size;
	    tmp.radius = tmp.portion * 4 * radius;
	    this.set_circle_position(tmp);
	    this.circle_objects[tmp.id] = tmp;
	}
    },
    set_circle_position: function(circle){
	circle.orientation = (circle.id - 1) / this.num_points;
	circle.x = circle.radius * Math.cos(tmp);
	circle.y = circle.radius * Math.sin(tmp);
	SET_COLOR(circle);
    }
}

/**
   Setup -- the first method called in the animation
*/
sim = false;
void setup() {
    // sets size of canvas
    size(900,500);
    sim = Object.create(Simulation)
    sim.startup();
    console.log(sim);
    $( "#slider" ).slider({min:2, max:5, step:1, slide: function( event, ui ) {
		reset(ui.value);
	$("#clusters").val(ui.value + " clusters");
    }});
}

/**
Resizes width of canvas if animation is occuring
*/
void checkWidth(){
    if(width != parseInt($("#demo").css("width")))
	size(parseInt($("#demo").css("width")), 500);
}