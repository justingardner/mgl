/**
 * These functions are mainly helpers and for psychophysics.
 * Functions are similar to those in mgl's folder called "utils". 
  * This includes functions to do basic array operations
 * @author Dan Birman & Arman Abrahamyan
 * @module jglUtils
 */


/**
 * Make a sinusoidal grating. Creates a texture that later needs 
 * to be used with jglCreateTexture. 
 * Note: 0 deg means horizontal grating. 
 * If you want to ramp the grating with 
 * 2D Gaussian, also call function jglMakeGaussian and average the 
 * results of both functions
 * @param {Number} width: in pixels
 * @param {Number} height: in pixels
 * @param {Number} sf: spatial frequency in number of cycles per degree of visual angle
 * @param {Number} angle: in degrees
 * @param {Number} phase: in degrees 
 * @param {Number} pixPerDeg: pixels per degree of visual angle 
 * @memberof module:jglUtils
 */
 function jglMakeGrating(width, height, sf, angle, phase, pixPerDeg) {

// TODO. Fix jglMakeArray to return proper 

// Get sf in number of cycles per pixel
sfPerPix = sf / pixPerDeg; 
// Convert angle to radians
angleInRad = ((angle+0)*Math.PI)/180;
// Phase to radians
phaseInRad = (phase*Math.PI)*180;

// Get x and y coordinates for the grating in 2D
xStep = 2*Math.PI/width; 
yStep = 2*Math.PI/height; 
x = jglMakeArray(-Math.PI, xStep, Math.PI+1);  // to nudge jglMakeArray to include +PI
y = jglMakeArray(-Math.PI, yStep, Math.PI+1); 
// To tilt the 2D grating, we need to tilt 
// x and y coordinates. These are tilting constants.
xTilt = Math.cos(angleInRad) * sf * 2 * Math.PI; 
yTilt = Math.sin(angleInRad) * sf * 2 * Math.PI; 

//What is width and height? Are these in degrees of visual angle or pixels? 
//See how lines2d and dots work. For example, jglFillRect(x, y, size, color) uses size in pixels
//

//How does jgl compute size in degress of visual angle 
var ixX, ixY; // x and y indices for arrays
var grating = []; // 2D array 
for (ixX = 0; ixX < x.length; ixX++) {
	currentY = y[ixY];
	grating[ixX] = [];
	for (ixY=0; ixY < y.length; ixY++) {
		grating[ixX][ixY] = Math.cos(x[ixX] * xTilt + y[ixY] * yTilt);
		// Scale to grayscale between 0 and 255
		grating[ixX][ixY] = Math.round(((grating[ixX][ixY] + 1)/2)*255);
	}
}
return(grating); 

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
 * Function to linearize the luminance output relative to input contrast 
 * using screen gamma value (also called gamma correction).
 * You must set myscreen.pow via the calibration.html survey first. This function
 * returns either adjusted contrast (from 0 to 1) or hex string of adjusted color
 * @param {Number} contrast between 0 to 255
 * @param {Boolean} hex if true, returns contrast as heximal string, otherwise as number
 * @returns {Number|String} Gamma corrected contrast. Either number between 0-255 or hex color code as string
 * @memberof module:jglUtils
 */
 jglGammaCorr = function(contrast, hex) {
 	contrastCorr = Math.round(Math.pow(contrast/255,1/myscreen.pow)*255);
 	// If hex is undefined, default to false
 	hex = typeof hex !== 'undefined' ? hex : false;
 	if (!hex) {
 		return(contrastCorr);
 	} else {
 		contrastCorrAsStr = numToHex(contrastCorr); // convert contrast to hex value
        contrastHex = '#' + contrastCorrAsStr + contrastCorrAsStr + contrastCorrAsStr; // make it hex rgb triplet 
 		return(contrastHex);
 	}
 }

/**
 * Wrapper around jglGammaCorr to return hex color value 
 * @param {Number} contrast between 0 to 255
 * @returns {String} Gamma corrected contrast. Either number between 0-255 or hex color code as string
 * @memberof module:jglUtils
 */
jglGammaCorrHex = function(contrast) {
	return(jglGammaCorr(contrast, true));
}

/**
 * Function to convert a number between 0-255 to hex.
 * Includes zero padding so result.length always == 2
 * @param {Number} number the number to convert
 * @returns {String} the hex value of the number given
 * @memberof module:jglUtils
 */
function numToHex(number) {
	var hex = number.toString(16); // returns the base 16 string version of the number
	if (hex.length == 1) {
		hex = "0" + hex;
	}
	return hex;
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