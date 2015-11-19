/**
 * These functions are mainly helpers and for psychophysics.
 * Functions are similar to those in mgl's folder called "utils". 
  * This includes functions to do basic array operations
 * @author Dan Birman & Arman Abrahamyan
 * @module jglUtils
 */


/**
 * Make a sinusoidal grating. Creates a texture that later needs 
 * to be used with jglCreateTexture. If you want to ramp it with 
 * 2D Gaussian, separately call function jglMakeGaussian and average the 
 * results of both functions
 * @param {Number} width: in pixels
 * @param {Number} height: in pixels
 * @param {Number} sf: spatial frequency in number of cycles per degree of visual angle
 * @param {Number} angle: in degrees
 * @param {Number} phase: in degrees 
 * @param {Number} pixPerDeg: pixels per degree of visual angle 
 */
function jglMakeGrating(width, height, sf, angle, phase, pixPerDeg) {

// Get sf in number of cycles per pixel
sfPerPix = sf / pixPerDeg; 
// Convert angle to radians and make sure 0 deg is horizontal
angleInRad = ((angle-90)*Math.PI)/180;
// Phase to radians
phaseInRad = (phase*Math.PI)*180;

// Get x and y coordinates for the grating in 2D
xStep = 2*Math.PI/width; 
yStep = 2*Math.PI/height; 
x = jglMakeArray(-Math.PI, xStep, Math.PI); 
y = jglMakeArray(-Math.PI, yStep, Math.PI); 
// To tilt the 2D grating, we need to scale 
// x and y coordinates by constants a and b, respectively
//x

//What is width and height? Are these in degrees of visual angle or pixels? 
//See how lines2d and dots work. For example, jglFillRect(x, y, size, color) uses size in pixels
//

//How does jgl compute size in degress of visual angle 


return(grating)

/**
// From Justin's Matlab code
  % 2D grating
  % calculate orientation
  angle = pi*angle/180;
  a=cos(angle)*sf*2*pi;
  b=sin(angle)*sf*2*pi;

  % get a grid of x and y coordinates that has 
  % the correct number of pixels
  x = -width/2:width/(widthPixels-1):width/2;
  y = -height/2:height/(heightPixels-1):height/2;
  [xMesh,yMesh] = meshgrid(x,y);

  % compute grating
  m = cos(a*xMesh+b*yMesh+phase);
*/
}



// From Matlab
/**
function [m xMesh yMesh] = mglMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix) {

}
*/


/**
 * Function to adjust the contrast of a stimulus relative to the screen gamma.
 * You must set myscreen.pow via the calibration.html survey first. This function
 * returns the hex of your color.
 */
con2hex = function(contrast) {
	con = Math.round(Math.pow(contrast,1/myscreen.pow)*255);
	conS = con.toString(16);
	if (conS.length == 1) {
		conS = conS + conS;
	}
	hex = '#' + conS + conS + conS;
	return(hex);
}



//// NOTE: Wonder if these functions would better suit to be part of stdlib.js

function AssertException(message) { this.message = message; }
AssertException.prototype.toString = function () {
	return 'AssertException: ' + this.message;
};

function assert(exp, message) {
	if (!exp) {
		throw new AssertException(message);
	}
}

// Mean of booleans (true==1; false==0)
function boolpercent(arr) {
	var count = 0;
	for (var i=0; i<arr.length; i++) {
		if (arr[i]) { count++; } 
	}
	return 100* count / arr.length;
}

sortIndices = function (array,indices) {
    var ret = zeros(array.length);

    for (var i=0;i<array.length;i++) {
        ret[i] = array[indices[i]];
    }
    return(ret);
}


function randomInteger(n) {
	return Math.floor(Math.random()*n);
}

function randomElement(array) {
	return array[randomInteger(array.length)];
}