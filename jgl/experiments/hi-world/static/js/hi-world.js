/**
 * Simple app that uses jgl to print "hi world"
 */

$(document).ready(function() {
	hiWorld();
});

function hiWorld() {
	// Setup the screen
	window.myscreen = initScreen();
	// Provide task structure. 
	// These lines 
	window.task = [];
	task[0] = [];
	//task[0][0] = {};
	//task[0][0] = initSurvey();
	task[0][0] = {};
	// Let's have segments. In the first, "hi world" will be 
	// shown. In the second, a keyboard response will be collected
	task[0][0].seglen = [2, 3];
	task[0][0].getResponse = [1];
	task[0][0].numBlocks = 1;
	task[0][0].numTrials = 10;
	// task[0][1].parameter = {};
	// task[0][1].parameter.dir = 0;
	// task[0][1].parameter.coherence = 0;
	
	// "canvas.html" contains class "jgl" which is 
	// used by jgl to show visual stimuli
	task[0][0].html = "canvas.html";
	// Does task use screen? 1=yes
	task[0][0].usingScreen = 1;
	// Initialize the task by defining which functions will be called 
	// at the start of each segment and when updating the screen
	task[0][0] = initTask(task[0][0], startSegmentCallback, updateScreenCallback);
	
	window.stimulus = {};
	
	initStimulus("stimulus");
	//task[0][0] = initDots(task[0][1], myscreen);
	
	// Initialize PstiTurk experiment
	initTurk();

	//task[0][1] = createStencilsForDisplay(task, myscreen); 
	
	startPhase(task[0]);
	
}


var startSegmentCallback = function(task, myscreen) {
	// if (! window.stimulus.hasOwnProperty("dots")) {
	// 	window.stimulus.dots = {};
	// }
	//debugger
	if (task.thistrial.thisseg == 0) {
		//debugger
		//jglClearScreen();
	}
	if (task.thistrial.thisseg == 1) {
		//debugger
		jglTextSet('Arial',1,'#ff0000',0,0);
		jglTextDraw('__ hi world __ trial number: ' + task.trialnum,-6.5,-2.75);
	}
	
	//window.stimulus.dots.dir = task.thistrial.dir;
	
	console.log(jglGetSecs());
	//jglFillRect([-1, -4], [0, 3], [1, 2], "#0000ff");
 	
 	//jglStencilCreateBegin(1);


	return [task, myscreen];
}

var updateScreenCallback = function(task, myscreen) {
	//jglClearScreen();
	//window.stimulus = updateDots(window.stimulus, task, myscreen);
	// jglTextSet('Arial',1,'#ff0000',0,0);
	// jglTextDraw('__ hi world __',-1.5,-2.75);

 	//jglVisualAngleCoordinates();
 	//jglStencilCreateBegin(1);

    // jglFillRect([-1, -4, -5], [0, 3, 5], [1, 2], "#0000ff");
    // jglFillRect([-3, -5, -9], [2, 7, 9], [1, 2], "#00AAff");
    // jglFillRect([-6], [-2], [2, 3], "#FFFF00");
    // jglLines2([-2], [0], [0], [5], 0.5, "#AAEEAA");
    // jglPoints2([4, -4], [4, -4], [2], 1);

    //jglStencilCreateEnd();

    //jglStencilSelect(1);
    //jglWaitSecs(1);
	//jglTextDraw('__ HELLO world __',-1.5,0);
	//jglFillRect([-1, -4, -5], [0, 3, 5], [1, 2], "#0000ff");
	//jglFlush();
    //jglStencilSelect(0);
    //jglClearScreen();

    //jglFlush();
    //jglFlush();
    //jglFlush();
	return [task, myscreen];
}

var createStencilsForDisplay = function(task, myscreen) {
	//debugger;
	jglOpen(myscreen.ppi);
	jglClearScreen(128);
	
	jglStencilCreateBegin(1);	
    jglFillRect([-2], [-3], [2,3], "#112233");
    
    // jglFillRect([-1, -4, -5], [0, 3, 5], [1, 2], "#0000ff");
    // jglFillRect([-3, -5, -9], [2, 7, 9], [1, 2], "#00AAff");
    // jglFillRect([-6], [-2], [2, 3], "#FFFF00");
    // jglLines2([-2], [0], [0], [5], 0.5, "#AAEEAA");
    // jglPoints2([4, -4], [4, -4], [2], 1);

    jglStencilCreateEnd();
	
	//jglClearScreen(128);
	jglClose();
	//debugger;
	return task;
}



// function initDots(task, myscreen) {
// 	jglOpen(myscreen.ppi);
	
// 	jglClearScreen();
	
// 	jglStencilCreateBegin(1);
	
// 	jglPoints2([stimulus.dots.xcenter], [stimulus.dots.ycenter], stimulus.dots.rmax, "#ffffff");
	
// 	jglStencilCreateEnd();
	
// 	jglClearScreen();
	
// 	jglClose();
	
// 	return task;
// }


// var startTrialCallback = function(task, myscreen) {

// 	document.getElementById("canvas").addEventListener('mousemove', function(e) {mdata = getMousePos(canvas, e);}, false);

// 	if(task.thistrial.crit) {
// 		task.thistrial.seglen[stimulus.seg.resp] = 5;
// 	}
// 	jglData.responses.push(0);
// 	jglData.rotation.push(task.thistrial.rotation);
// 	jglData.respDiff.push(0);
// 	jglData.correct.push(0);
// 	jglData.soa.push(task.thistrial.seglen[stimulus.seg.stim]);
// 	jglData.prac.push(task.thistrial.practice);
// 	jglData.crit.push(task.thistrial.crit);
// 	jglData.task.push(task.thistrial.task);
// 	jglData.sStart.push(-1);
// 	jglData.sStop.push(-1);
// 	jglData.gTrial.push(task.trialnum);
// 	jglData.aTrial.push(jglData.gTrial.length);
// 	stimulus.gotResp = false;

//   return [task, myscreen];
// }

// var getResponseCallback = function(task, myscreen) {
// 	jumpSegment(task,0);
// 	var realRot = task.thistrial.rotation;
// 	var resp = mdata.theta;
// 	var diff = (resp-realRot+Math.PI*2) % (Math.PI*2);

// 	jglData.respDiff[jglData.respDiff.length-1] = diff;

// 	var corr;
// 	if ((diff < Math.PI/4) || (diff > (Math.PI*2-Math.PI/4))) {
// 		corr = 1;
// 	} else {
// 		corr = -1;
// 	}
// 	jglData.responses[jglData.responses.length-1] = resp;
// 	jglData.correct[jglData.correct.length-1] = corr;
// 	stimulus.gotResp = corr;
// 	return [task, myscreen];
// }



// function upCorrectText() {	
// 	if (stimulus.gotResp==-1) {
// 		jglTextSet('Arial',1,'#ff0000',0,0);
// 		jglTextDraw('Wrong',-1.5,-2.75);
// 	} else if (stimulus.gotResp==1) {
// 		jglTextSet('Arial',1,'#00ff00',0,0);
// 		jglTextDraw('Correct',-1.65,-2.75);
// 	}
// }

// function upNowRespondText() {	
// 	jglTextSet('Arial',1,'#000000',0,0);
// 	jglTextDraw('Respond Now',-3,-2.75);
// }

