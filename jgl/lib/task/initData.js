/**
 * This function is in charge of initializing the jglData object.
 * The jglData object holds all data, responses as well as survey responses.
 * jglData has two main fields, keys and mouse. Keys holds all keyboard event data,
 * and mouse holds all mouse response data. keys fields are tasknum, phasenum, blocknum,
 * trialnum, segnum, time, and keyCode. mouse fields are: which, x, y, tasknum, phasenum, blocknum,
 * trialnum, segnum, time. When an event occurs if the segment requires a response gotResponse is set to one
 * the event is recorded in jglData, and if a trialResponse callback is set it is called. 
 * @memberof module:jglTask
 */
function initData() {
	window.jglData = {};
	jglData.keys = [];
	jglData.mouse = [];
	
	$("body").focus().keydown(keyResponse);
	$("body").focus().mousedown(mouseResponse);
}

/**
 * Gathers key events and saves them in jglData.
 * checks to see for each running task if the current segment wants a response
 * if so records it.
 * @param {Object} e the event given by the handler
 * @memberof module:jglTask
 */
var keyResponse = function(e) {
	for (var i = 0;i<task.length;i++) { //cycle through tasks
		if (task[i][tnum].thistrial.gotResponse == 0 && task[i][tnum].getResponse[task[i][tnum].thistrial.thisseg] == 1) {
			task[i][tnum].thistrial.gotResponse = 1;
			writeTrace(e.keyCode, task[i][tnum].responseTrace);
			jglData.keys[jglData.keys.length] = {};
			jglData.keys[jglData.keys.length - 1].keyCode = e.keyCode;
			jglData.keys[jglData.keys.length - 1].tasknum = i;
			jglData.keys[jglData.keys.length - 1].phasenum = tnum;
			jglData.keys[jglData.keys.length - 1].blocknum = task[i][tnum].blocknum;
			jglData.keys[jglData.keys.length - 1].trialnum = task[i][tnum].trialnum;
			jglData.keys[jglData.keys.length - 1].segnum = task[i][tnum].thistrial.thisseg;
			jglData.keys[jglData.keys.length - 1].time = jglGetSecs();
			if (task[i][tnum].callback.hasOwnProperty("trialResponse")) {
				task[i][tnum].callback.trialResponse(task[i][tnum], myscreen);
			}
		}
	}
}

/**
 * Gathers mouse events and saves them in jglData.
 * checks to see for each running task if the current segment wants a response
 * if so records it.
 * @param {Object} e the event given by the handler
 * @memberof module:jglTask
 */
var mouseResponse = function(e) {
	for (var i = 0;i<task.length;i++) { //cycle through tasks
		if (task[i][tnum].thistrial.gotResponse == 0 && task[i][tnum].getResponse[task[i][tnum].thistrial.thisseg] == 2) {
			task[i][tnum].thistrial.gotResponse = 1;
			writeTrace(-e.which, task[i][tnum].responseTrace);
			jglData.mouse[jglData.mouse.length] = {};
			jglData.mouse[jglData.mouse.length - 1].which = e.which;
			jglData.mouse[jglData.mouse.length - 1].x = e.pageX;
			jglData.mouse[jglData.mouse.length - 1].y = e.pageY;
			jglData.mouse[jglData.mouse.length - 1].tasknum = i;
			jglData.mouse[jglData.mouse.length - 1].phasenum = tnum;
			jglData.mouse[jglData.mouse.length - 1].blocknum = task[i][tnum].blocknum;
			jglData.mouse[jglData.mouse.length - 1].trialnum = task[i][tnum].trialnum;
			jglData.mouse[jglData.mouse.length - 1].segnum = task[i][tnum].thistrial.thisseg;
			jglData.mouse[jglData.mouse.length - 1].time = jglGetSecs();
			if (task[i][tnum].callback.hasOwnProperty("trialResponse")) {
				task[i][tnum].callback.trialResponse(task[i][tnum], myscreen);
			}
		}
	}
}