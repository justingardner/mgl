
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

function randomInteger(n) {
	return Math.floor(Math.random()*n);
}

function randomElement(array) {
	return array[randomInteger(array.length)];
}