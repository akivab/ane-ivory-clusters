var ArtIcon = {
    get_name: function(name){
	return "images/" + name;
    },
    mouseover: function(){
	var obj = this;
	return function(){
	    obj.size = "big";
	    obj.draw();
	}
    },
    mouseup: function(){
	var obj = this;
	return function(){
	    obj.selected = false;
	    obj.draw();
	}
    },
    mousedown: function(){
	var obj = this;
	return function(e){
	    obj.selected = true;
	    obj.pos.x = e.pageX;
	    obj.pos.y = e.pageY;
	    obj.draw();
	    //this.sim.selected.push(obj);
	}
    },
    mouseout: function(){
	var obj = this;
	return function(){
	    obj.size = "small";
	    obj.draw();
	}
    },
    set_style: function(obj, style){
	for(var s in style){
	    obj.style[s] = style[s];
	}
    },
    setup: function(){
	this.searched = false;
	this.selected = false;

	this.small = "60px";
	this.big = "70px";
	this.background = "100px";
	this.size = 'small';
	this.icon = new Image();
	this.pos = {x:0, y:0};
	this.div = document.createElement('div');
	this.div.appendChild(this.icon);
    },
    setup_event_handlers: function(){
	this.icon.onmouseover = this.mouseover();
	this.icon.onmouseout = this.mouseout();
	this.icon.onmousedown = this.mousedown();
	this.icon.onmouseup = this.mouseup();
    },
    init: function(name, sim){
	this.setup();
	this.icon.src = this.get_name(name);
	this.setup_event_handlers();
	this.sim = sim;
	this.draw();
    },
    icon_margin: function(){
	var size = this[this['size']];
	var background = this['background'];
	var margin =  parseInt(background) - parseInt(size);
	return margin/2;
    },
    icon_size: function(){
	var size = this[this['size']];
	return size;
    },

    div_background: function(){
	if(this.searched)
	    return "icons/blue.png";
	else if(this.selected)
	    return "icons/pink.png";
	return false;
    },
    draw: function(){
	var margin = this.icon_margin();
	var size = this.icon_size();
	var background = this.div_background();
	this.set_style(this.icon, {position: "relative", 
				   top: margin, left: margin,
				   width: size, height: size
				  });
	this.set_style(this.div, {position: "fixed",
				  top: this.pos.x,
				  left: this.pos.y,
				  width: this.background, 
				  height: this.background});
	if(background)
	    background = "url("+background+")";
	else
	    background = "none";
	this.set_style(this.div, {background: background});
    },
    addTo: function(obj){
	obj.appendChild(this.div);
    }
}

var Simulation = {
    init: function(){
	this.objects = [];
	this.first = Object.create(ArtIcon);
	this.first.init("Aleppo9.jpg", this);
	this.first.addTo(document.body);
    }
}


$(document).ready(
    function(){
	var sim = Object.create(Simulation);
	sim.init();
    }
);