/**
 * JGL - A javascript Graphics Library.
 * Modeled after mgl (MATLAB graphics library)
 * 
 * Author - Tuvia Lerea
 * @author Tuvia Lerea
 * @module jgllib
 * 
 */

/** 
 * HTML page must have a div element with class="jgl"
 */


//--------------------------Setup and Globals----------------------
// Screen object, holds a bunch of info about the screen and state of the canvas
/**
 * The canvas object
 * @type Object
 */
var canvas;
// mouse object, tracks mouse state
/**
 * The mouse object, which is always updated to the current state of the mouse
 * @type Mouse
 */
var mouse;
// The main off-screen canvas/context. 
//var backCtx;
//var backCanvas;
// The off-screen canvas/context that is used to combine the stencil and backCanvas
/**
 * The canvas for the stencil to be drawn on
 * @type Object
 * @private
 */
var stencilCanvas;
/**
 * The context of the stencilCanvas.
 * @type Object
 * @private
 */
var stencilCtx;

/**
 * The canvas to draw textures on.
 * @type Object
 * @private
 */
var texCanvas;
/**
 * The context of the texCanvas.
 * @type Object
 * @private
 */
var texCtx;


/**
 * Screen object, contains the canvases and other information
 * @constructor
 * @property {Object} canvas the front canvas.
 * @property {Ojbect} context the context for the front canvas.
 * @property {Object} backCanvas the back canvas.
 * @property {Ojbect} backCtx the context for the back canvas.
 * @property {Number} height the height of the canvas.
 * @property {Number} width the width of the canvas.
 * @property {Array} stencils an array of all of the saved stencils.
 * @property {Boolean} drawingStencil boolean to determine if you are currently drawing a stencil.
 * @property {Boolean} useStencil determines if you are currently using a stencil
 * @property {Number} stencilSelected the number of the currently selected stencil
 * @property {Number} viewDistance defaults to 24 inches
 * @property {Number} ppi the pixels per inch of the screen.
 * @property {Number} degPerPix the degrees in visual angles per pixel
 * @property {Number} pixPerDeg the pixels per degree of visual angle
 * @property {Boolean} usingVisualAngles tells if you are currently drawing in visual angles
 * @property {Boolean} usingVisualAnglesStencil tells if you are currently drawing in visual angels for your stencil
 * @property {String} backgroundColor the color of the background
 * @property {Number} lastFlushTime the time of the last call to flush
 * @property {Number} frameRate the number of frames per second
 * @property {Boolean} isOpen tells if jgllib is open. 
 */
function Canvas() {	
	this.canvas = document.getElementById("canvas");
	this.context = this.canvas.getContext("2d"); // main on-screen context
	this.backCanvas = document.getElementById("backCanvas");
	this.backCtx = backCanvas.getContext("2d");
	this.height = $("#canvas").height(); // height of screen
	this.width = $("#canvas").width(); // width of screen
	this.stencils = []; // array of all stencil canvases
	this.drawingStencil = false; // Are you drawing a stencil?
	this.useStencil = false; // is a stencil in use?
	this.stencilSelected = 0; // if so, which?
	this.viewDistance = 24; // set to a default right now
	this.ppi = 0; // Pixels / Inch, gets set when jglOpen is called
	this.degPerPix = 0; // gets set in jglOpen
	this.pixPerDeg = 0; // gets set in jglOpen
	this.usingVisualAngles = false; // Is the drawing in visualAngles?
	this.usingVisualAnglesStencil = false; // Is the stencil using visualAngles?
	this.backgroundColor = "#ffffff";
	this.lastFlushTime = 0;
	this.frameRate = 30;
	this.isOpen = false;
}

/**
 * Creates a mouse object. 
 * @constructor
 * @property {Array} buttons [left, middle, right]
 * @property {Number} x the x-coordinate
 * @property {Number} y the y-coordinate
 */
function Mouse() {
	this.buttons = []; // [left, middle, right]
	this.x = 0; // x-coordinate
	this.y = 0; // y-coordinate
}

/**
 * Sets up the mouse tracker. 
 * Binds the mouse move, down, and up events to keep track of the mouse movements.
 * @param {Ojbect} mouse the mouse object to keep track of the location of the mouse.
 * @private
 */
function mouseSetup(mouse) {
	$(window).mousemove(function(event){
		mouse.x = event.pageX;
		mouse.y = event.pageY;
	});
	$(window).mousedown(function(event){
		var button = event.which;
		mouse.buttons[button - 1] = 1;
	});
	$(window).mouseup(function(event) {
		var button = event.which;
		mouse.buttons[button - 1] = 0;
	});
}

//----------------------Main Screen Functions--------------------

/**
 * Sets up the jgl screen. This function adds both canvases to the
 * end of the class="jgl" element. The two canvases are the two buffers, 
 * one is on screen one is off, more about this in the jglFlush doc.
 * @param {Number} resolution The ppi of the screen.
 */
function jglOpen(resolution) {
	var stencils = [];
	if (canvas !== undefined && canvas.hasOwnProperty("stencils")) {
		stencils = canvas.stencils;
	}
	$(".jgl").append("<div id=\"jglDiv\" style=\"position: relative;\"><canvas style=\" position: absolute; top: 0px; left: 0px;\" id=\"canvas\" width=\"800\" height=\"800\"></canvas>"
			+ "<canvas style=\" position: absolute; top: 0px; left: 0px;\" id=\"backCanvas\" width=\"800\" height=\"800\"></canvas> </div>");
	$("#backCanvas").hide();
	canvas = new Canvas();
	window.resizeTo(canvas.width + 50, canvas.height + 80);
	canvas.stencils = stencils;
	mouse = new Mouse();
	mouseSetup(mouse);
	canvas.ppi = resolution;
	var inPerDeg = canvas.viewDistance * (Math.tan(0.0174532925));
	canvas.pixPerDeg = resolution * inPerDeg;
	canvas.degPerPix = 1 / canvas.pixPerDeg;
	
	stencilCanvas = document.createElement("canvas");
//	stencilCanvas = document.getElementById("stencilcanvas");
	stencilCtx = stencilCanvas.getContext("2d");
	
	stencilCanvas.width = canvas.width;
	stencilCanvas.height = canvas.height;
	stencilCtx = stencilCanvas.getContext("2d");
	
	texCanvas = document.createElement('canvas');
	texCanvas.width = canvas.width;
	texCanvas.height = canvas.height;
	texCtx = texCanvas.getContext("2d");
	
	jglVisualAngleCoordinates();
	
	canvas.isOpen = true;
}

/**
 * Determines if jgllib is currently open
 * @returns {Boolean} true is yes, false if no
 */
function jglIsOpen() {
	if (canvas === undefined) {
		return false;
	}
	return canvas.isOpen;
}

/**
 * Closes jgllib by removing the canvases from the page
 * sets isOpen to false. 
 */
function jglClose() {
	$("#jglDiv").remove();
	canvas.isOpen = false;
}

/**
 * Flips the visiblity of the two buffers, and draws the background.
 * Operates in discrete frames, meaning that each draw
 * draws all the elements to the screen at once. If a stencil
 * is selected works with the backCanvas and stencilCanvas to maintain
 * discrete frames, read Stencil Comment for more information.
 */
function jglFlush() {
	if (! canvas.useStencil) {
		canvas.backCtx.save();
		canvas.backCtx.globalCompositeOperation = "destination-over"; // enables background painting
		// 2*screen.width is used so either coordinate system will work
		jglFillRect([0],[0], [2*canvas.width, 2*canvas.height], canvas.backgroundColor); // colors background
		canvas.backCtx.restore();
		screenSwapPrivate(); // swap buffers (read function comments)
	} else {
		// Need to combine stencil and image, use stencilCtx, and offscreen canvas for the combination
		// First draw the stencil on the canvas
		stencilCtx.drawImage(canvas.stencils[canvas.stencilSelected], 0, 0);
		stencilCtx.save();
		// Turn on stenciling
		stencilCtx.globalCompositeOperation = "source-in";
		// Draw the image, which will be stenciled
		stencilCtx.drawImage(canvas.backCanvas, 0, 0);
		stencilCtx.restore();
		// Clear the back buffer
		privateClearContext(canvas.backCtx);
		// Draw the stenciled image to the back buffer then clear the stencilCanvas for later use
		if (canvas.usingVisualAngles) {
			
			jglScreenCoordinates(); // Change back to screen coordinates for ease of image drawing
			canvas.backCtx.drawImage(stencilCanvas, 0, 0);
			jglVisualAngleCoordinates();
			stencilCtx.clearRect(0, 0, stencilCanvas.width, stencilCanvas.height);
		} else {
			canvas.backCtx.drawImage(stencilCanvas, 0, 0);
			stencilCtx.clearRect(0,0, stencilCanvas.width, stencilCanvas.height);
		}
		// Draw background and swap buffers
		canvas.backCtx.save();
		canvas.backCtx.globalCompositeOperation = "destination-over";
		jglFillRect([0],[0], [2*canvas.width, 2*canvas.height], canvas.backgroundColor);
		canvas.backCtx.restore();
		screenSwapPrivate();
	}
	
	canvas.lastFlushTime = jglGetSecs();

}

/**
 * Flushes and then waits for a frame to pass.
 */
function jglFlushAndWait() {
	var lastFlushTime = canvas.lastFlushTime;
	
	var frameRate = canvas.frameRate;
	
	if (isEmpty(frameRate)) {
		console.error("jglFushAndWait: No frameRate set");
		return;
	}
	
	var frameTime = 1 / frameRate;
	
	jglFlush();
	
	console.log('should not get here');
	jglWaitSecs(frameTime - jglGetSecs(lastFlushTime));
	
	canvas.lastFlushTime =  jglGetSecs();
}

/**
 * Waits for a frame but does not flush
 */
function jglNoFlushWait() {
	var lastFlushTime = canvas.lastFlushTime;
	
	var frameRate = canvas.frameRate;
	
	if (isEmpty(frameRate)) {
		console.error("jglFlushAndWait: no framerate set");
		return;
	}
	
	var frameTime = 1 / frameRate;
	
	console.log('should not get here');
	jglWaitSecs(frameTime - jglGetSecs(lastFlushTime));
	
	canvas.lastFlushTime = jglGetSecs();
}

/**
 * Private function to swap the two buffers. 
 * This is done by toggling both canvases (if hidden, shows, if shown, hides),
 * then the values of canvas and backCanvas are swapped, as well as the values
 * of context and backCtx.
 * @private
 */
function screenSwapPrivate() {
	$("#canvas").toggle();
	$("#backCanvas").toggle();
	var temp = canvas.context;
	canvas.context = canvas.backCtx;
	canvas.backCtx = temp;
	temp = canvas.canvas;
	canvas.canvas = canvas.backCanvas;
	canvas.backCanvas = temp;
}

/**
 * Private function for clearing a context, written to shorten code.
 * @param {Object} context the context to clear.
 * @private
 */
function privateClearContext(context) {
	if (canvas.usingVisualAngles) {
		context.clearRect(-canvas.width / 2, -canvas.height / 2, canvas.width, canvas.height);
	} else {
		context.clearRect(0, 0, canvas.width, canvas.height);
	}
}

/**
 * Function to clear the front buffer, as well as set the background color.
 * @param {Number} background the color to set the background to. param can be given
 * as a number on the grayscale, 0-255 or an array of three numbers [r,g,b].
 */
function jglClearScreen(background) {
	// if (arguments.length != 0) {
	// 	var r, g, b;
	// 	if ($.isArray(background)) {
	// 		r = numToHex(background[0]);
	// 		g = numToHex(background[1]);
	// 		b = numToHex(background[2]);
	// 	} else {
	// 		r = numToHex(background);
	// 		g = numToHex(background);
	// 		b = numToHex(background);
	// 	}
	// 	canvas.backgroundColor = "#" + r + g + b;

	// }
	canvas.backgroundColor = con2hex(background);
	privateClearContext(canvas.context);
}

/**
 * Function to convert a number between 0-255 to hex.
 * Includes zero padding so result.length always == 2
 * @param {Number} number the number to convert
 * @returns {String} the hex value of the number given
 */
function numToHex(number) {
	var hex = number.toString(16); // returns the base 16 string version of the number
	if (hex.length == 1) {
		hex = "0" + hex;
	}
	return hex;
}


//-------------------Drawing Different Shapes-------------------

/**
 * Function for drawing 2D points.
 * @param {Array} x array of x coordinates
 * @param {Array} y array of y coordinates
 * @param {Number} size Size of point in degrees (diameter)
 * @param {String} color Color of points in #hex format
 */
function jglPoints2(x, y, size, color) {
	if (x.length != y.length) {
		// Error
		throw "Points2: Lengths dont match";
	}
	for (var i=0;i<x.length;i++) {
		canvas.backCtx.fillStyle=color;
		canvas.backCtx.beginPath();
		canvas.backCtx.arc(x[i], y[i], size/2, 0, 2*Math.PI);
		canvas.backCtx.fill();
		canvas.backCtx.closePath();
	}
	//screen.context.save();
}

/**
 * Function for drawing 2D Lines
 * @param {Array} x0 array of starting x coordinates
 * @param {Array} y0 array of starting y coordinates
 * @param {Array} x1 array of ending x coordinates
 * @param {Array} y1 array of ending y coordinates
 * @param {Number} size width of line in pixels
 * @param {String} color in hex format "#000000"
 */
function jglLines2(x0, y0, x1, y1, size, color) {
	if (x0.length != y0.length || x1.length != y1.length || x0.length != x1.length) {
		//Error
		throw "Lines2: Lengths dont match";
	}
	for (var i=0;i<x0.length;i++) {
		canvas.backCtx.lineWidth = size;
		canvas.backCtx.strokeStyle=color;
		canvas.backCtx.beginPath();
		canvas.backCtx.moveTo(x0[i], y0[i]);
		canvas.backCtx.lineTo(x1[i], y1[i]);
		canvas.backCtx.stroke();
	}
}

function jglFillOval(x, y, size, color) {
	if (x.length != y.length || size.length != 2) {
		//Error
		throw "Fill Oval: Lengths dont match";
	}
	var radius = Math.min(size[0], size[1]);
	canvas.backCtx.save();
	canvas.backCtx.transform(0, size[0], size[1],0,0,0);
	jglPoints2(x, y, radius, color);
	canvas.backCtx.restore();
}

function jglFillArc(x, y, size, color, sAng, wAng) {
	if (x.length != y.length) {
		//Error
		throw "Fill Oval: Lengths dont match";
	}
	canvas.backCtx.fillStyle=color;
	canvas.backCtx.beginPath();
	canvas.backCtx.moveTo(0,0);
	canvas.backCtx.arc(x,y,size,sAng,wAng);
	canvas.backCtx.fill();
	canvas.backCtx.closePath();
}

/**
 * Makes Filled Rectangles
 * @param {Array} x an array of x coordinates of the centers
 * @param {Array} y an array of y coordinates of the centers
 * @param {Array} size [width,height] array
 * @param {String} color color in hex format #000000
 */
function jglFillRect(x, y, size, color) {
	if (x.length != y.length || size.length != 2) {
		//Error
		throw "Fill Rect: Lengths dont match"
	}
	var upperLeft = {
			x:0,
			y:0
	};
	for (var i=0;i<x.length;i++) {
		canvas.backCtx.fillStyle = color;
		upperLeft.x = x[i] - (size[0] / 2);
		upperLeft.y = y[i] - (size[1] / 2);
		canvas.backCtx.fillRect(upperLeft.x, upperLeft.y, size[0], size[1]);
	}
}

/**
 * Draws a fixation cross onto the screen. 
 * If no params are given, cross defaults to center,
 * with lineWidth = 1, width = 10, and black.
 * @param {Number} width the width of the cross
 * @param {Number} lineWidth the width of the lines of the cross
 * @param {String} color the color in hex format
 * @param {Array} origin the center point in [x,y]
 */
function jglFixationCross(width, lineWidth, color, origin) {
	
	if (arguments.length == 0) {
		if (canvas.usingVisualAngles) {
			width = 1;
			lineWidth = 0.04;
			color = "#ff0000";
			origin = [0 , 0];
		} else {
			width = 20;
			lineWidth = 1;
			color = "#ff0000";
			origin = [canvas.backCanvas.width / 2 , backCanvas.height / 2];
		}
		
	}
	canvas.backCtx.lineWidth = lineWidth;
	canvas.backCtx.strokeStyle = color;
	canvas.backCtx.beginPath();
	canvas.backCtx.moveTo(origin[0] - width / 2, origin[1]);
	canvas.backCtx.lineTo(origin[0] + width / 2, origin[1]);
	canvas.backCtx.stroke();
	canvas.backCtx.beginPath();
	canvas.backCtx.moveTo(origin[0], origin[1] - width / 2);
	canvas.backCtx.lineTo(origin[0], origin[1] + width / 2);
	canvas.backCtx.stroke();
}

/**
 * Function for drawing a polygon.
 * The x and y params lay out a set of points.
 * @param {Array} x the x coordinates
 * @param {Array} y the y coordinates
 * @param {String} color the color, in hex format #000000
 */
function jglPolygon(x, y, color) {
	if (x.length != y.length || x.length < 3) {
		// Error, need at least three points to
		// make a polygon.
		throw "Polygon arrays not same length";
	}
	canvas.backCtx.fillStyle = color;
	canvas.backCtx.strokeStyle = color;
	canvas.backCtx.beginPath();
	canvas.backCtx.moveTo(x[0], y[0]);
	for (var i=1;i<x.length;i++) {
		canvas.backCtx.lineTo(x[i], y[i]);
	}
	canvas.backCtx.closePath();
	canvas.backCtx.fill();
//	backCtx.stroke();
}


//----------------Timing Functions---------------------------

/**
 * Gets the current seconds since Jan 1st 1970.
 * @return Returns the seconds value;
 */
function jglGetSecs(t0) {
	if (t0 === undefined) {
		var d = new Date();
		return d.getTime() / 1000;
	} else {
		var d = new Date();
		return (d.getTime() / 1000) - t0;
	}
}

/**
 * Waits the given number of seconds. WARNING may not work!!
 * @param {Number} secs the number of seconds to wait.
 */
function jglWaitSecs(secs) {
	var first, second;
	first = new Date();
	var current = first.getTime();
	do {
		second = new Date();
	} while (Date.now() < current + (secs * 1000));
	
//	setTimeout(secs, function(){});
}

//-----------------------Text Functions------------------------

/**
 * Function to set the text params. Needs to be called right before jglTextDraw
 * @param {String} fontName the name of the font to use
 * @param {Number} fontSize the size of the font to use
 * @param {String} fontColor the color of the font to use
 * @param {Number} fontBold 1 for bold, 0 for not
 * @param {Number} fontItalic 1 for italic, 0 for not
 */
function jglTextSet(fontName, fontSize, fontColor, fontBold, fontItalic) {
	// fontString needs to be in a specific format, this function builds it.
	var fontString = "";
	if (fontBold == 1) {
		fontString = fontString.concat("bold ");
	}
	
	if (fontItalic == 1) {
		fontString = fontString.concat("italic ");
	}
	
	fontString = fontString.concat(fontSize, "px ", fontName);
	canvas.backCtx.font = fontString;
	canvas.backCtx.fillStyle = fontColor;
}

/**
 * Draws the given text starting at (x, y)
 * @param {String} text the text to be drawn
 * @param {Number} x the x coordinate of the beginning of the text
 * @param {Number} y the y coordinate of the beginning of the text
 */
function jglTextDraw(text, x, y) {
	canvas.backCtx.fillText(text, x, y);
}


//------------------------Keyboard and Mouse functions ---------------------

/**
 * A function for getting information about the mouse.
 * @return A Mouse object, contains x, y, and buttons 
 * fields. buttons is a logical array, 1 means that button
 * is pressed.
 */
var jglGetMouse = function jglGetMouse() {
	return mouse;
}

/**
 * Function to gain access to the mouse event listener.
 * @param {Object} mouseEventCallback the mouse down callback function. 
 * This function must take an event object as a parameter.
 * @private
 */
function jglOnMouseClick(mouseEventCallback) {
	$(window).mouseDown(function(event) {
		mouseEventCallback(event);
	});
}

/**
 * Function to gain access to the key down event listener.
 * @param {Ojbect} keyDownEventCallback the key down callback Function.
 * This function must take an event object as a parameter.
 * @private
 */
function jglOnKeyDown(keyDownEventCallback) {
	$(window).keyDown(function(event) {
		keyDownEventCallback(event);
	});
}

/**
 * Function to get all active keys.
 * @returns {Array} an array of all active keys
 */
var jglGetKeys = function jglGetKeys() {
	return KeyboardJS.activeKeys();
}


//-----------------------Stencil Functions----------------------------
/*
 * A Note on how stencils work:
 * Stencils must be used in the following flow:
 * createBegin(i)
 * Drawing functions...
 * createEnd
 * select(i)
 * drawing functions...
 * flush
 * 
 * Stencils work by creating a new off-screen canvas on which to draw.
 * The drawing functions called between createBegin and createEnd draw
 * to that off-screen canvas, not the main off-screen canvas. When 
 * createEnd is called, all following draw functions draw to the normal
 * off-screen canvas. When select is called screen.useStencil is set to 
 * true and the stencilNumber is remembered. The big change happens in
 * flush. If a stencil is being used, flush behaves quite differently. 
 * flush first draws the stencil to a third off-screen canvas, stencilCanvas,
 * then draws the backCanvas to stencilCanvas with stencil mode enabled, 
 * and then finally draws stencilCanvas to the on-screen canvas. This is 
 * done so that only the final image is ever drawn to the screen, and it
 * is drawn all at once. This makes sure that flush ensures discrete frames.
 *  
 */

/**
 * Starts the creation of a stencil with the given number.
 * @param {Number} stencilNumber the number of the stencil about to be created.
 */
function jglStencilCreateBegin(stencilNumber) {
	var newCanvas = document.createElement('canvas');
	newCanvas.width = canvas.width;
	newCanvas.height = canvas.height;
	canvas.stencils[stencilNumber] = newCanvas;
	canvas.backCtx = newCanvas.getContext("2d");
	if (canvas.usingVisualAngles) {
		canvas.backCtx.save();
		canvas.backCtx.translate(canvas.width / 2, canvas.height / 2);
		canvas.backCtx.transform(canvas.pixPerDeg,0,0,canvas.pixPerDeg, 0,0);
		canvas.usingVisualAnglesStencil = true;

	}
	canvas.drawingStencil = true;
}

/**
 * Ends the creation of a stencil.
 */
function jglStencilCreateEnd() {
	canvas.backCtx = canvas.backCanvas.getContext("2d");
	canvas.drawingStencil = false;
}

/**
 * Selects the stencil with the given number.
 * @param {Number} stencilNumber the number of the stencil to select.
 * @throw Number too large if the number given is greater than the number of stencils.
 * @throw No stencil if the number does not correspond to a stencil.
 */
function jglStencilSelect(stencilNumber) {
	if (stencilNumber == 0) {
		jglStencilDeselect();
		return;
	}
	
	if (stencilNumber >= canvas.stencils.length) {
		//Error
		throw "StencilSelect: Number too large";
	}
	if (canvas.stencils[stencilNumber] == null) {
		// TODO: Not sure if javaScript works like that, need to check
		throw "StencilSelect: No Stencil with that number";
	}
	
	canvas.useStencil = true;
	canvas.stencilSelected = stencilNumber;
}

/**
 * Deselects the selected stencil, this will cause flush to act as normal.
 */
function jglStencilDeselect() {
	canvas.useStencil = false;
}

//----------------------Coordinate Functions---------------------------

/**
 * Function for changing to visual Angle Coordinates.
 * If this function is called while drawing a stencil, 
 * it does not effect the normal canvas. 
 */
function jglVisualAngleCoordinates() {
	if ((canvas.usingVisualAngles && ! canvas.drawingStencil) || 
			(canvas.usingVisualAnglesStencil && canvas.drawingStencil)) {
		//Error
		throw "VisualCoordinates: Already using visual coordinates";
	}
	canvas.backCtx.save();
	canvas.backCtx.translate(canvas.width / 2, canvas.height / 2);
	canvas.backCtx.transform(canvas.pixPerDeg,0,0,canvas.pixPerDeg, 0,0);
	
	canvas.context.save();
	canvas.context.translate(canvas.width / 2, canvas.height / 2);
	canvas.context.transform(canvas.pixPerDeg,0,0,canvas.pixPerDeg, 0,0);
	
	if (! canvas.drawingStencil) {
		canvas.usingVisualAngles = true;
	} else {
		canvas.usingVisualAnglesStencil = true;
	}
}

/**
 * Function for changing to screen coordinates.
 * If this function is called while drawing a stencil,
 * it does not effect the normal canvas.
 */
function jglScreenCoordinates() {
	if ((! canvas.usingVisualAngles && ! canvas.drawingStencil) || 
			(canvas.drawingStencil && ! canvas.usingVisualAnglesStencil)) {
		// Error
		throw "ScreenCoordinates: Already using screen coordinates";
	}
	canvas.backCtx.restore();
	
	canvas.context.restore();
	if (! canvas.drawingStencil) {
		canvas.usingVisualAngles = false;
	} else {
		canvas.usingVisualAnglesStencil = false;
	}
}

//--------------------------Texture Functions-----------------------------------

/**
 * Function to make array starting at low,
 * going to high, stepping by step.
 * @param {Number} low The low bound of the array
 * @param {Number} step the step between two elements of the array
 * @param {Number} high the high bound of the array
 */
function jglMakeArray(low, step, high) {
	if (step === undefined) {
		step = 1;
	}
	
	if (low < high) {
		var size = Math.floor((high - low) / step);
		var array = new Array(size);
		array[0] = low;
		for (var i=1;i<array.length;i++) {
			array[i] = array[i-1] + step;
		}
		return array;
	} else if (low > high) {
		var size = Math.floor((low - high) / step);
		var array = new Array(size);
		array[0] = low;
		for (var i=1;i<array.length;i++) {
			array[i] = array[i-1] - step;
		}
		return array;
	}
	return [low];
}

function repmat(array,reps) {
	out = [];
	for (i=0;i<reps;i++) {
		out = out.concat(array);
	}
	return(out);
}

/**
 * Function for generating jgl textures.
 * This function does different things depending on
 * what it is given. If a 1D array is passed in, 
 * the array is replicated down to make a square and the
 * resulting texture is returned, the texture is using grayscale.
 * If a 2D array is passed, a greyscale texture is created and returned.
 * If a 3D array is passed, if it is NxMx3 an RGB texture is returned,
 * and if it is NxMx4 and RGB and Alpha texture is returned.
 * @param {Array} array the array to pass in.
 * @returns the texture
 */
function jglCreateTexture(array) {
	
	/* Note on how imageData's work.
	 * ImageDatas are returned from createImageData,
	 * they have an array called data. The data array is
	 * a 1D array with 4 slots per pixel, R,G,B,Alpha. A
	 * greyscale texture is created by making all RGB values
	 * equals and Alpha = 255. The main job of this function
	 * is to translate the given array into this data array.
	 */
	if (! $.isArray(array)) {
		return;
	}
	var image;
	if ( ! $.isArray(array[0])) {
		// 1D array passed in
		image = canvas.backCtx.createImageData(array.length, array.length);
		var counter = 0;
		for (var i=0;i<image.data.length;i += 4) {
			image.data[i + 0] = array[counter];
			image.data[i + 1] = array[counter];
			image.data[i + 2] = array[counter];
			image.data[i + 3] = 255;
			counter++;
			if (counter == array.length) {
				counter = 0;
			}
		}
		return image;
		
	} else if (! $.isArray(array[0][0])) {
		// 2D array passed in
		image = canvas.backCtx.createImageData(array.length, array.length);
		var row = 0;
		var col = 0;
		for (var i=0;i<image.data.length;i += 4) {
			image.data[i + 0] = array[row][col];
			image.data[i + 1] = array[row][col];
			image.data[i + 2] = array[row][col];
			image.data[i + 3] = 255;
			col++;
			if (col == array[row].length) {
				col = 0;
				row++;
			}
		}
		return image;
	
	} else {
		// 3D array passed in
		if (array[0][0].length == 3) {
			// RGB
			image = canvas.backCtx.createImageData(array.length, array.length);
			var row = 0;
			var col = 0;
			for (var i=0;i<image.data.length;i += 4) {
				image.data[i + 0] = array[row][col][0];
				image.data[i + 1] = array[row][col][1];
				image.data[i + 2] = array[row][col][2];
				image.data[i + 3] = 255;
				col++;
				if (col == array[row].length) {
					col = 0;
					row++;
				}
			}
			return image;
		} else if(array[0][0].length == 4) {
			//RGB and Alpha
			image = canvas.backCtx.createImageData(array.length, array.length);
			var row = 0;
			var col = 0;
			for (var i=0;i<image.data.length;i += 4) {
				image.data[i + 0] = array[row][col][0];
				image.data[i + 1] = array[row][col][1];
				image.data[i + 2] = array[row][col][2];
				image.data[i + 3] = array[row][col][3];
				col++;
				if (col == array[row].length) {
					col = 0;
					row++;
				}
			}
			return image;
		} else {
			//Error
			throw "jglCreateTexture: invalid array dimensions";
		}
	}
}

/**
 * Function for drawing the given texture to screen. All params except texture
 * are optional, defaults to center with 0 rotation.
 * @param {Object} texture the texture to draw, should only pass something
 * given by jglCreateTexture.
 * @param {Number} xpos the x-coordinate to place the center of the texture.
 * @param {Number} ypos the y-coordinate to place the center of the texture.
 * @param {Number} rotation the rotation of the texture in degrees.
 */
function jglBltTexture(texture, xpos, ypos, rotation) {
	
	// Variables to keep track of the center, xpos and ypos will
	// be used to keep track of the top left corner, which is needed
	// by the canvas API.
	var xcenter, ycenter;

	if (xpos === undefined) {
		// default to center
		if (canvas.usingVisualAngles) {
			xpos = -texture.width * canvas.degPerPix/2;
			xcenter = 0;
		} else {
			xpos = canvas.width / 2 - texture.width/2;
			xcenter = canvas.width / 2;
		}
	} else { // center is given
		xcenter = xpos; // remember given center
		// determine top left corner given size of texture
		if (canvas.usingVisualAngles) {
			xpos = xpos - (texture.width * canvas.degPerPix) / 2;
		} else {
			xpos = xpos - texture.width / 2;
		}
	}
	if (ypos === undefined) {
		// default to center
		if (canvas.usingVisualAngles) {
			ypos = texture.height * canvas.degPerPix / 2;
			ycenter = 0;
		} else {
			ypos = canvas.height / 2 - texture.height / 2
			ycenter = canvas.height / 2;
		}
	} else { // center is given
		ycenter = ypos; // remember given center
		// determine top left corner given size of texture
		if (canvas.usingVisualAngles) {
			ypos = ypos + (texture.height * canvas.degPerPix) / 2;
		} else {
			ypos = ypos - texture.height / 2;
		}
	}
	
	if (rotation === undefined) { // default to 0 rotation
		rotation = 0;
	}
	
	// x and y coordinates of the top left corner in pixels, will only be used, 
	// if visualAngles are being used, meaning that xpos and ypos are in degrees
	var xtopLeft = (backCanvas.width / 2) + (xpos * canvas.pixPerDeg);
	var ytopLeft = (backCanvas.height / 2) - (ypos * canvas.pixPerDeg);

	// need another canvas to put the ImageData to so that stenciling and Alpha will work
	// since drawImage will be allow for those things, but putImageData will not. So,
	// the texture is drawn to the texCtx, and then the texCtx is drawn to the back buffer.

	if (canvas.usingVisualAngles) {
		xcenter = xcenter * canvas.pixPerDeg;
		xcenter = canvas.width / 2 + xcenter;
		
		ycenter = ycenter * canvas.pixPerDeg;
		ycenter = canvas.width / 2 - ycenter;
		
		texCtx.putImageData(texture, xtopLeft, ytopLeft); // draws texture to texCtx
		jglScreenCoordinates(); // switch to screenCoordinates to make image placement easier
		canvas.backCtx.save();
		canvas.backCtx.translate(xcenter, ycenter); // translate to rotate about the center of the texture
		canvas.backCtx.rotate(rotation * 0.0174532925); // rotate uses radians, must convert
		canvas.backCtx.drawImage(texCanvas, -xcenter, -ycenter); // draw image, 
		// The translate means that the top left corner is -width/2, -height/2
		canvas.backCtx.restore(); // restore back to factory settings
		jglVisualAngleCoordinates(); // go back to visualAngleCoordinates
	} else {
		// put texture on texCtx
		texCtx.putImageData(texture, xpos, ypos);
		canvas.backCtx.save();
		canvas.backCtx.translate(xcenter, ycenter); //rotate about the center of the texture 
		canvas.backCtx.rotate(rotation * 0.0174532925); // rotate in degrees
		canvas.backCtx.drawImage(texCanvas, -xcenter, -ycenter);
		canvas.backCtx.restore();
	}
	texCtx.clearRect(0,0,canvas.width, canvas.height); // clear texCtx


}

/**
 * Function to get a parameter of the canvas object. 
 * @param {String} str the name of the parameter
 * @returns the value of that field in canvas
 */
function jglGetParam(str) {
	return eval("canvas." + str);
}

/**
 * Function to set a parameter of the canvas object
 * @param {String} param the field to set
 * @param {Any} val the value to set it to.
 */
function jglSetParam(param, val) {
	eval("canvas." + param + " = " + val);
}