$(document).ready(function() {
	cohcon();
});

function cohcon() {

  	window.myscreen = initScreen();

	var instructionPages = [ // add as a list as many pages as you like
		"instructions/instruct-1.html",
		"instructions/instruct-ready.html"
	];

	var pracTrials = Infinity;
	var fullTrials = 75;

	var phases = {};
	phases.s1 = 0;
	phases.s2 = 0;
	phases.s3 = 1;
	phases.i = 3;
	phases.traini1 = 0;
	phases.train1 = 2;
	phases.traini2 = 6;
	phases.train2 = 7;
	phases.pe = 8;
	phases.e1i = 9;
	phases.e1 = 10;
	phases.c = 11;
	phases.e2i = 12;
	phases.e2 = 13;
	phases.post = 14;
	var peds = {};
	peds.con = 0.6; // base contrast
	peds.conInc = [0, 0.025,0.05,0.075,0.1,0.2,0.3,0.4,0.6,0.8]; // max 0.8 so 0.6 + 0.4 = 1.0
	peds.conTInc = 0.4;
	peds.coh = 0.1;
	peds.cohInc = [0, 0.05, 0.15, 0.25, 0.35,0.45,0.55,0.65,0.75,0.85];
	peds.cohTInc = 0.7;

	window.task = [];
	task[0] = [];
	// task[0][phases.s1] = initSurvey();
	// task[0][phases.s1].html = "surveyDemo.html";

	task[0][phases.s2] = initSurvey();
	task[0][phases.s2].html = "surveyScreen.html";

	task[0][phases.s3] = initSurvey();
	task[0][phases.s3].html = "calibrate.html";

	// task[0][phases.i] = initInstructions(instructionPages);

	// var order = [];
	// if (randomElement([true,false])) {
	// 	order = [phases.traini1, phases.train1, phases.traini2, phases.train2];
	// } else {
	// 	order = [phases.traini2, phases.train2, phases.traini1, phases.train1];
	// }
	// task[0][phases.traini1] = {}; task[0][phases.train1] = {};
	// task[0][phases.traini2] = {}; task[0][phases.train2] = {};

	// Practice Run for Motion
	// task[0][order[0]] = initInstructions(motPages);

	// task[0][order[1]] = {};
	// task[0][order[1]].waitForBacktick = 0;
	// task[0][order[1]].segmin = [0.4,0.2,0.4,0,3];
	// task[0][order[1]].segmax = [0.4,0.2,0.4,0,3];
	// task[0][order[1]].numTrials = pracTrials;
	// task[0][order[1]].parameter = {};
	// task[0][order[1]].parameter.practice = 1;
	// task[0][order[1]].parameter.conP = peds.con;
	// task[0][order[1]].parameter.conInc = peds.conTInc;
	// task[0][order[1]].parameter.cohP = peds.coh;
	// task[0][order[1]].parameter.cohInc = peds.cohTInc;
	// task[0][order[1]].parameter.conSide = [1, 2, 2, 1];
	// task[0][order[1]].parameter.cohSide = [1, 2, 1, 2];
	// task[0][order[1]].parameter.dir = [-1,1];
	// task[0][order[1]].parameter.task = 1;
	// task[0][order[1]].parameter.crit = 0;
	// task[0][order[1]].random = 1;
	// task[0][order[1]].usingScreen = 1;
	// task[0][order[1]].getResponse = [0,0,0,0,1];
	// task[0][order[1]].html = "canvas.html";

	// // Practice Run for Contrast
	// task[0][order[2]] = initInstructions(conPages);

	// task[0][order[3]] = {};
	// task[0][order[3]].waitForBacktick = 0;
	// task[0][order[3]].segmin = [0.4,0.2,0.4,0,3];
	// task[0][order[3]].segmax = [0.4,0.2,0.4,0,3];
	// task[0][order[3]].numTrials = pracTrials;
	// task[0][order[3]].parameter = {};
	// task[0][order[3]].parameter.practice = 1;
	// task[0][order[3]].parameter.conP = peds.con;
	// task[0][order[3]].parameter.conInc = peds.conTInc;
	// task[0][order[3]].parameter.cohP = peds.coh;
	// task[0][order[3]].parameter.cohInc = peds.cohTInc;
	// task[0][order[3]].parameter.conSide = [1, 2, 2, 1];
	// task[0][order[3]].parameter.cohSide = [1, 2, 1, 2];
	// task[0][order[3]].parameter.dir = [-1,1];
	// task[0][order[3]].parameter.task = 2;
	// task[0][order[3]].parameter.crit = 0;
	// task[0][order[3]].random = 1;
	// task[0][order[3]].usingScreen = 1;
	// task[0][order[3]].getResponse = [0,0,0,0,1];
	// task[0][order[3]].html = "canvas.html";

	// // Full run for XXX
	// var fullOrder = [];
	// if (randomElement([true,false])) {
	// 	fullOrder = [1,2]; // coherence first
	// } else {
	// 	fullOrder = [2,1]; // contrast first
	// }

	// task[0][phases.pe] = initSurvey();
	// task[0][phases.pe].html = "preExp.html";

	// if (fullOrder[0]==1) {task[0][phases.e1i] = initInstructions(motPages);} else {task[0][phases.e1i] = initInstructions(conPages);}

	// task[0][phases.e1] = {};
	// task[0][phases.e1].segmin = [0.4,0.15,0.4,0,1.5];
	// task[0][phases.e1].segmax = [0.4,0.15,0.4,0,1.5];
	// task[0][phases.e1].numTrials = fullTrials;
	// task[0][phases.e1].parameter = {};
	// task[0][phases.e1].parameter.practice = 0;
	// task[0][phases.e1].parameter.conP = peds.con;
	// task[0][phases.e1].parameter.conInc = peds.conInc;
	// task[0][phases.e1].parameter.dir = [-1,1];
	// task[0][phases.e1].parameter.cohP = peds.coh;
	// task[0][phases.e1].parameter.cohInc = peds.cohInc;
	// task[0][phases.e1].parameter.conSide = [1, 2, 2, 1];
	// task[0][phases.e1].parameter.cohSide = [1, 2, 1, 2];
	// task[0][phases.e1].parameter.crit = 0;
	// task[0][phases.e1].parameter.task = fullOrder[0];
	// task[0][phases.e1].random = 1;
	// task[0][phases.e1].usingScreen = 1;
	// task[0][phases.e1].getResponse = [0,0,0,0,1];
	// task[0][phases.e1].html = "canvas.html";

	// //CRITICAL TRIAL
	// task[0][phases.c] = {};
	// task[0][phases.c].segmin = [0.4,0.15,0.4,4,6];
	// task[0][phases.c].segmax = [0.4,0.15,0.4,4,6];
	// task[0][phases.c].numTrials = 1;
	// task[0][phases.c].parameter = {};
	// task[0][phases.c].parameter.practice = 0;
	// task[0][phases.c].parameter.conP = peds.con;
	// task[0][phases.c].parameter.conInc = peds.conInc;
	// task[0][phases.c].parameter.dir = [-1,1];
	// task[0][phases.c].parameter.cohP = peds.coh;
	// task[0][phases.c].parameter.cohInc = peds.cohInc;
	// task[0][phases.c].parameter.conSide = [1, 2, 2, 1];
	// task[0][phases.c].parameter.cohSide = [1, 2, 1, 2];
	// task[0][phases.c].parameter.task = fullOrder[1];
	// task[0][phases.c].parameter.crit = 1;
	// task[0][phases.c].usingScreen = 1;
	// task[0][phases.c].getResponse = [0,0,0,0,1];
	// task[0][phases.c].html = "canvas.html";

	// if (fullOrder[1]==1) {task[0][phases.e2i] = initInstructions(motPages);} else {task[0][phases.e2i] = initInstructions(conPages);}

	// //FULL RUN
	// task[0][phases.e2] = {};
	// task[0][phases.e2].segmin = [0.4,0.15,0.4,0,1.5];
	// task[0][phases.e2].segmax = [0.4,0.15,0.4,0,1.5];
	// task[0][phases.e2].numTrials = fullTrials;
	// task[0][phases.e2].parameter = {};
	// task[0][phases.e2].parameter.practice = 0;
	// task[0][phases.e2].parameter.conP  = peds.con;
	// task[0][phases.e2].parameter.conInc = peds.conInc;
	// task[0][phases.e2].parameter.dir = [-1,1];
	// task[0][phases.e2].parameter.cohP = peds.coh;
	// task[0][phases.e2].parameter.cohInc = peds.cohInc;
	// task[0][phases.e2].parameter.conSide = [1, 2, 2, 1];
	// task[0][phases.e2].parameter.cohSide = [1, 2, 1, 2];
	// task[0][phases.e2].parameter.task = fullOrder[1];
	// task[0][phases.e2].parameter.crit = 0;
	// task[0][phases.e2].random = 1;
	// task[0][phases.e2].usingScreen = 1;
	// task[0][phases.e2].getResponse = [0,0,0,0,1];
	// task[0][phases.e2].html = "canvas.html";

	// task[0][phases.post] = initSurvey();
	// task[0][phases.post].html = "postquestionnaire-2.html";

	var pi = Math.PI;

	task[0][phases.train1] = {};
	task[0][phases.train1].waitForBacktick = 0;
	task[0][phases.train1].segmin = [0.4,0.2,0.4,Infinity,1];
	task[0][phases.train1].segmax = [0.4,0.2,0.4,Infinity,1];
	task[0][phases.train1].numTrials = pracTrials;
	task[0][phases.train1].parameter = {};
	task[0][phases.train1].parameter.practice = 1;
	task[0][phases.train1].parameter.conP = peds.con;
	task[0][phases.train1].parameter.conInc = peds.conTInc;
	task[0][phases.train1].parameter.cohP = peds.coh;
	task[0][phases.train1].parameter.cohInc = peds.cohTInc;
	task[0][phases.train1].parameter.rotation = [0, pi/4, 2*pi/4, 3*pi/4, 4*pi/4, 5*pi/4, 6*pi/4, 7*pi/4];
	task[0][phases.train1].parameter.dir = [-1,1];
	// task[0][phases.train1].parameter.task = 1;
	task[0][phases.train1].parameter.crit = 0;
	task[0][phases.train1].random = 1;
	task[0][phases.train1].usingScreen = 1;
	task[0][phases.train1].getResponse = [0,0,0,2,0];
	task[0][phases.train1].html = "canvas.html";


	task[0][phases.train1] = initTask(task[0][phases.train1], startSegmentCallback, screenUpdateCallback, getResponseCallback, startTrialCallback,endTrialCallbackPrac,[],blockRandomization);
	// task[0][phases.train2] = initTask(task[0][phases.train2], startSegmentCallback, screenUpdateCallback, getResponseCallback, startTrialCallback,endTrialCallbackPrac,[],blockRandomization);
	// task[0][phases.e1] = initTask(task[0][phases.e1], startSegmentCallback, screenUpdateCallback, getResponseCallback, startTrialCallback,[],[],blockRandomization);
	// task[0][phases.c] = initTask(task[0][phases.c], startSegmentCallback, screenUpdateCallback, getResponseCallback, startTrialCallback,[],[],blockRandomization);
	// task[0][phases.e2] = initTask(task[0][phases.e2], startSegmentCallback, screenUpdateCallback, getResponseCallback, startTrialCallback,[],[],blockRandomization);

	window.stimulus = {};
	initStimulus('stimulus');

	myInitStimulus(task);

	// initStencil(9);

	// var critTasks = ['Motion','Contrast'];
	// stimulus.critTask = critTasks[fullOrder[1]-1];

	initTurk();

	//response related
	jglData.responses = [];
	jglData.respDiff = [];
	jglData.correct = [];
	jglData.rotation = [];

	jglData.prac = [];
	jglData.crit = [];
	jglData.soa = [];
	jglData.task = [];
	jglData.sStart = [];
	jglData.sStop = [];
	jglData.peds = peds;
	jglData.gTrial = []; jglData.aTrial = [];
	jglData.postSurvey = {};

	startPhase(task[0]);
}
	
function getMousePos(canvas, event) {
	var x,y;
		if (event.x != undefined && event.y != undefined) {
	    x = event.x;
	    y = event.y;
	  }
	  else { // Firefox method to get the position
	    x = event.clientX + document.body.scrollLeft +
	        document.documentElement.scrollLeft;
	    y = event.clientY + document.body.scrollTop +
	        document.documentElement.scrollTop;
	  }
	x -= canvas.width/2;
	y -= canvas.height/2;
	return {
	  x: x,
	  y: y,
	  theta: (Math.atan2(y,x) + (2*Math.PI)) % (Math.PI*2)
	};
}
// var initStencil = function(snum) {
// 	jglStencilCreateBegin(snum);
// 	jglClearScreen(0);
// 	jglFillOval(0,0,10,'#ffffff');
// 	jglStencilCreateEnd();
// 	jglStencilSelect(snum);
// }

var checkPractice = function(ctask) {
	ctrials = and(jglData.prac,equals(jglData.task,ctask));
	correct = index(jglData.correct,ctrials,true);
	correct = sum(correct.slice(Math.max(0,correct.length-20),correct.length));
	return correct >= 10;
}

// var checkExp = function(ctask) {
// 	ctrials = and(not(jglData.prac),equals(jglData.task,ctask));
// 	correct = index(jglData.correct,ctrials,true);
// 	correct = sum(correct.slice(Math.max(0,correct.length-20),correct.length));
// 	return correct < 0;
// }

var endTrialCallbackPrac = function(task,myscreen) {
	if(task.trialnum>5) {
		// while practicing we check to see whether we are doing well. If we are exceeding some arbitrary success threshold, 
		// then we can quit practice and continue.
		if (checkPractice(task.thistrial.task)) {
			task.numTrials = task.trialnum+1;
		}
	}
	if(task.trialnum>55) {
		alert('Hello Turker--your performance on the practice run was below our cutoff for the experiment. It is possible you did not understand the task or were pressing buttons randomly. You will be paid for the time you spent in practice! Thanks.');
		finishExp();
		myscreen.psiTurk.completeHIT();
	}
	return [task,myscreen];
}

// var endTrialCallbackExp = function(task,myscreen) {
// 	if(task.trialnum>5) {
// 		// while practicing we check to see whether we are doing well. If we are exceeding some arbitrary success threshold, 
// 		// then we can quit practice and continue.
// 		if (checkExp(task.thistrial.task)) {
// 			task.numTrials = task.trialnum+1;
// 		}
// 	}
// 	return [task,myscreen];
// }
var mdata;

var startTrialCallback = function(task, myscreen) {

	document.getElementById("canvas").addEventListener('mousemove', function(e) {mdata = getMousePos(canvas, e);}, false);

	if(task.thistrial.crit) {
		task.thistrial.seglen[stimulus.seg.resp] = 5;
	}
	jglData.responses.push(0);
	jglData.rotation.push(task.thistrial.rotation);
	jglData.respDiff.push(0);
	jglData.correct.push(0);
	jglData.soa.push(task.thistrial.seglen[stimulus.seg.stim]);
	jglData.prac.push(task.thistrial.practice);
	jglData.crit.push(task.thistrial.crit);
	jglData.task.push(task.thistrial.task);
	jglData.sStart.push(-1);
	jglData.sStop.push(-1);
	jglData.gTrial.push(task.trialnum);
	jglData.aTrial.push(jglData.gTrial.length);
	stimulus.gotResp = false;

	// contrast
	// convert to hex color
	stimulus.dots.white = con2hex(task.thistrial.conP );
	stimulus.dots.black = con2hex(1-task.thistrial.conP);
	stimulus.dotsT.white = con2hex(task.thistrial.conP + task.thistrial.conInc/2);
	stimulus.dotsT.black = con2hex((1-task.thistrial.conP) - task.thistrial.conInc/2);

	// coherence

	stimulus.dots.coherence = task.thistrial.cohP;
	stimulus.dotsT.coherence = task.thistrial.cohP = task.thistrial.cohInc;

	// rot
	stimulus.rotation = task.thistrial.rotation;

	// update coherence
	upDotCoherence();

  return [task, myscreen];
}

var getResponseCallback = function(task, myscreen) {
	jumpSegment(task,0);
	var realRot = task.thistrial.rotation;
	var resp = mdata.theta;
	var diff = (resp-realRot+Math.PI*2) % (Math.PI*2);

	jglData.respDiff[jglData.respDiff.length-1] = diff;

	var corr;
	if ((diff < Math.PI/4) || (diff > (Math.PI*2-Math.PI/4))) {
		corr = 1;
	} else {
		corr = -1;
	}
	jglData.responses[jglData.responses.length-1] = resp;
	jglData.correct[jglData.correct.length-1] = corr;
	stimulus.gotResp = corr;
	return [task, myscreen];
}

var startSegmentCallback = function(task, myscreen) {

	switch (task.thistrial.thisseg) {
		case stimulus.seg.stim:
			jglData.sStart[jglData.sStart.length-1] = jglGetSecs();
			break;
		case stimulus.seg.ISI:
			jglData.sStop[jglData.sStop.length-1] = jglGetSecs();
			break;
		case stimulus.seg.resp:
			stimulus.dotsT.white = con2hex(task.thistrial.conP + 0.4);
			stimulus.dotsT.black = con2hex(1-task.thistrial.conP - 0.4);
			stimulus.dotsT.coherence = 1;
			break;
	}

  	return [task, myscreen];
}

var screenUpdateCallback = function(task, myscreen) {
	jglClearScreen(0.5);

	switch (task.thistrial.thisseg) {
		case stimulus.seg.ITI:
			// upMask();
			upFix('#000000');
			break;
		case stimulus.seg.stim:
			upFix('#000000');
			upDots(task);
			break;
		case stimulus.seg.ISI:
			// upMask();
			upFix('#000000');
			break;
		case stimulus.seg.resp:
			if (task.trialnum < 5 && task.thistrial.practice) {upNowRespondText();}
			upFix('#ffffff');
			// upRotateBar();

			upDots(task);
			break;
		case stimulus.seg.fback:
			if (stimulus.gotResp==1) {
				upFix('#00ff00');
				if (task.trialnum < 5 && task.thistrial.practice) {
					upCorrectText();
				}
			} else if (stimulus.gotResp==-1) {
				upFix('#ff0000');
				if (task.trialnum < 5 && task.thistrial.practice) {
					upCorrectText();
				}
			} else {
				upFix('#ffffff');
				jglTextSet('Arial',1,'#000000',0,0);
				jglTextDraw('Incorrect Key',-3,-2);
				jglTextDraw('Press A or D',-3,2.2);
			}
			break;
		default:
			AssertException('screenUpdate failed. Segment does not exist');
	}

	return [task, myscreen];

}

var upRotateBar = function() {
	jglFillArc(0,0,7,'#ffffff',theta-Math.PI/8,theta+Math.PI/8);
}

function upCorrectText() {	
	if (stimulus.gotResp==-1) {
		jglTextSet('Arial',1,'#ff0000',0,0);
		jglTextDraw('Wrong',-1.5,-2.75);
	} else if (stimulus.gotResp==1) {
		jglTextSet('Arial',1,'#00ff00',0,0);
		jglTextDraw('Correct',-1.65,-2.75);
	}
}


function upNowRespondText() {	
	jglTextSet('Arial',1,'#000000',0,0);
	jglTextDraw('Respond Now',-3,-2.75);
}

function upMask() {
	jglFillRect(index(stimulus.mask.X,stimulus.mask.black,true), index(stimulus.mask.Y,stimulus.mask.black,true), [stimulus.mask.blocksize,stimulus.mask.blocksize],'#000000');
	jglFillRect(index(stimulus.mask.X,stimulus.mask.white,true), index(stimulus.mask.Y,stimulus.mask.white,true), [stimulus.mask.blocksize,stimulus.mask.blocksize],'#ffffff');

	stimulus.mask.black = sortIndices(stimulus.mask.black,randPerm(task,stimulus.mask.n));
	stimulus.mask.white = not(stimulus.mask.black);
}

function upFix(color) {
	jglFixationCross(1,0.1,color,[0,0]);
}

function upDots(task) {
	stimulus.dots = updateDots(task,stimulus.dots);
	stimulus.dotsT = updateDots(task,stimulus.dotsT);

	jglPoints2(index(stimulus.dots.x,stimulus.dots.con,true), index(stimulus.dots.y,stimulus.dots.con,true), 0.2, stimulus.dots.white);
	jglPoints2(index(stimulus.dots.x,not(stimulus.dots.con),true), index(stimulus.dots.y,not(stimulus.dots.con),true), 0.2, stimulus.dots.black);

	jglPoints2(index(stimulus.dotsT.x,stimulus.dotsT.con,true), index(stimulus.dotsT.y,stimulus.dotsT.con,true), 0.2, stimulus.dotsT.white);
	jglPoints2(index(stimulus.dotsT.x,not(stimulus.dotsT.con),true), index(stimulus.dotsT.y,not(stimulus.dotsT.con),true), 0.2, stimulus.dotsT.black);
}

function upDotCoherence() {
	// Start by repicking dots
	stimulus.dots.incoherent = greaterThan(subtract(rand(task,stimulus.dots.n),multiply(stimulus.dots.coherence,ones(stimulus.dots.n))),zeros(stimulus.dots.n));
	stimulus.dots.incoherentn = sum(stimulus.dots.incoherent);
	stimulus.dots.coherent = not(stimulus.dots.incoherent);
	stimulus.dots.coherentn = stimulus.dots.n-stimulus.dots.incoherentn;

	stimulus.dotsT.incoherent = greaterThan(subtract(rand(task,stimulus.dotsT.n),multiply(stimulus.dotsT.coherence,ones(stimulus.dotsT.n))),zeros(stimulus.dotsT.n));
	stimulus.dotsT.incoherentn = sum(stimulus.dotsT.incoherent);
	stimulus.dotsT.coherent = not(stimulus.dotsT.incoherent);
	stimulus.dotsT.coherentn = stimulus.dotsT.n-stimulus.dotsT.incoherentn;
}

function updateDots(task,dots) {

	// Check frequency? Not sure how to do this...
	freq_factor = 0.1;

	// Move coherent dots
	dots.R = add(dots.R,multiply(rand(task,dots.n),task.thistrial.dir*freq_factor),dots.coherent);
	dots.R = add(dots.R,subtract(multiply(rand(task,dots.n),2*freq_factor),freq_factor),dots.incoherent);
	// var randT = subtract(multiply(10,rand(task,dots.n)),5);
	// var prandT = sortIndices(randT,randPerm(task,randT.length));
	// dots.T = add(dots.T,multiply(prandT,freq_factor),dots.coherent);

	// move incoherent dots
	// dots.randX = multiply(jglMakeArray(-1,1,dots.n),freq_factor);
	// dots.randY = multiply(-1,dots.randX);

	// // Move incoherent dots
	// dots.Y = add(dots.Y,dots.randY,dots.incoherent);
	// dots.X = add(dots.X,dots.randX,dots.incoherent);

	// Flip dots back if they go too far
	for (var i=0;i<dots.R.length;i++) {
		if (dots.R[i] > dots.maxR) {
			dots.R[i] = dots.R[i] - (dots.maxR - dots.minR);
		}
		if (dots.R[i] < dots.minR) {
			dots.R[i] = dots.R[i] + (dots.maxR - dots.minR);
		}
		if (dots.T[i] < dots.minT) {
			dots.T[i] = dots.T[i] + (dots.maxT - dots.minT);
		}
		if (dots.T[i] > dots.maxT) {
			dots.T[i] = dots.T[i] - (dots.maxT - dots.minT);
		}
		// if (dots.X[i] > dots.maxX) {
		// 	dots.X[i] = dots.X[i] - (dots.maxX - dots.minX);
		// } else if (dots.X[i] < dots.minX) {
		// 	dots.X[i] = dots.X[i] + (dots.maxX - dots.minX)
		// }
		// if (dots.Y[i] > dots.maxY) {
		// 	dots.Y[i] = dots.Y[i] - (dots.maxY - dots.minY);
		// } else if (dots.Y[i] < dots.minY) {
		// 	dots.Y[i] = dots.Y[i] + (dots.maxY - dots.minY)
		// }
	}

	// Update x, y
	if (task.thistrial.thisseg == stimulus.seg.stim) {
		rot = stimulus.rotation - Math.PI/8;
	} else if (task.thistrial.thisseg == stimulus.seg.resp) {
		rot = mdata.theta - Math.PI/8;
	} else {
		rot = 0;
	}
	dots.x = multiply(dots.R,cos(mod(add(dots.T, rot), Math.PI*2)));
	dots.y = multiply(dots.R,sin(mod(add(dots.T, rot), Math.PI*2)));

	return(dots);
}

function myInitStimulus(task) {
	stimulus.critTrial = 5;

	stimulus.rotation = 0;

	stimulus.seg = {};
	stimulus.seg.ITI = 0;
	stimulus.seg.stim = 1;
	stimulus.seg.ISI = 2;
	stimulus.seg.resp = 3;
	stimulus.seg.fback = 4;

	stimulus.mask = {};
	stimulus.mask.x = {}; stimulus.mask.y = {};
	stimulus.mask.color = {};
	stimulus.mask.n = 400; // pre-calculated len(-6.75:0.5:6.75)*len(-4.75:0.5:4.75)
	stimulus.mask.black = sortIndices(repmat([0,1],stimulus.mask.n/2),randPerm(task,stimulus.mask.n));
	stimulus.mask.white = not(stimulus.mask.black);
	stimulus.mask.blocksize = 1;

	// build mask
	stimulus.mask.X = [];
	stimulus.mask.Y = [];
	stimulus.mask.x.min = -7;
	stimulus.mask.x.max = 7;
	stimulus.mask.y.min = -7;
	stimulus.mask.y.max = 7;
	for (var i = stimulus.mask.x.min+stimulus.mask.blocksize/2;i < stimulus.mask.x.max;i += stimulus.mask.blocksize) {
		for (var j = stimulus.mask.y.min+stimulus.mask.blocksize/2;j<stimulus.mask.y.max;j += stimulus.mask.blocksize) {
			r = Math.sqrt(Math.pow(i,2)+Math.pow(j,2));
			if (r < 7 && r > 1) {
				stimulus.mask.X.push(i);
				stimulus.mask.Y.push(j);
			}
		}
	}

	stimulus.dots = {};
	stimulus.dots.minR = 1;
	stimulus.dots.maxR = 7
	stimulus.dots.minT = Math.PI/4;
	stimulus.dots.maxT = Math.PI*2;
	stimulus.dots.n = 280;
	stimulus.dots.con = sortIndices(repmat([0,1],stimulus.dots.n/2),randPerm(task,stimulus.dots.n));
	stimulus.dots.group = []
	stimulus.dots.T = add(multiply(rand(task,stimulus.dots.n), (stimulus.dots.maxT-stimulus.dots.minT)),stimulus.dots.minT);
	stimulus.dots.R = add(multiply(rand(task,stimulus.dots.n), (stimulus.dots.maxR-stimulus.dots.minR)),stimulus.dots.minR);
	stimulus.dots.coherent = ones(stimulus.dots.n);
	stimulus.dots.mult = -1;
	stimulus.dots.x = multiply(stimulus.dots.R,cos(stimulus.dots.T));
	stimulus.dots.y = multiply(stimulus.dots.R,sin(stimulus.dots.T));

	stimulus.dotsT = {};
	stimulus.dotsT.minR = 1;
	stimulus.dotsT.maxR = 7
	stimulus.dotsT.minT = 0;
	stimulus.dotsT.maxT = Math.PI/4;
	stimulus.dotsT.n = 40;
	stimulus.dotsT.con = sortIndices(repmat([0,1],stimulus.dotsT.n/2),randPerm(task,stimulus.dotsT.n));
	stimulus.dotsT.group = []
	stimulus.dotsT.T = add(multiply(rand(task,stimulus.dotsT.n), (stimulus.dotsT.maxT-stimulus.dotsT.minT)),stimulus.dotsT.minT);
	stimulus.dotsT.R = add(multiply(rand(task,stimulus.dotsT.n), (stimulus.dotsT.maxR-stimulus.dotsT.minR)),stimulus.dotsT.minR);
	stimulus.dotsT.coherent = ones(stimulus.dotsT.n);
	stimulus.dotsT.mult = -1;
	stimulus.dotsT.x = multiply(stimulus.dotsT.R,cos(stimulus.dotsT.T));
	stimulus.dotsT.y = multiply(stimulus.dotsT.R,sin(stimulus.dotsT.T));
}
