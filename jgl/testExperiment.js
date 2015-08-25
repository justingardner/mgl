/**
 * 
 */
$(document).ready(function() {
	testExperiment();
});

function testExperiment() {
	window.myscreen = initScreen();
	
	window.task = [];
	task[0] = [];
	task[0][0] = {};
	task[0][0] = initSurvey();
	task[0][1] = {};
	task[0][1].seglen = [2, Infinity];
	task[0][1].getResponse = [1];
	task[0][1].numBlocks = 10;
	task[0][1].numTrials = 10;
	task[0][1].parameter = {};
	task[0][1].parameter.dir = 0;
	task[0][1].parameter.coherence = 0;
	task[0][1].html = "canvas.html";
	task[0][1].usingScreen = 1;
	task[0][1] = initTask(task[0][1], startSegmentCallback, updateScreenCallback);
	task[0][2] = initSurvey(myscreen);
//	task[0][2].html = "postquestionnaire.html";
	
	window.stimulus = {};
	
	initStimulus("stimulus");
	task[0][1] = initDots(task[0][1], myscreen);
	
	initTurk();
	
	startPhase(task[0]);
	
}


var startSegmentCallback = function(task, myscreen) {
	if (! window.stimulus.hasOwnProperty("dots")) {
		window.stimulus.dots = {};
	}
	
	if (task.thistrial.thisseg == 1) {
		window.stimulus.dots.coherence = task.thistrial.coherence;
	} else {
		window.stimulus.dots.coherence = 0;
	}
	
	window.stimulus.dots.dir = task.thistrial.dir;
	
	console.log(jglGetSecs());

	return [task, myscreen];
}

var updateScreenCallback = function(task, myscreen) {
	jglClearScreen();
	window.stimulus = updateDots(window.stimulus, task, myscreen);
	return [task, myscreen];
}

function initDots(task, myscreen) {
	if (! stimulus.hasOwnProperty("dots")) {
		stimulus.dots = {};
	}
	
	if (! stimulus.dots.hasOwnProperty("rmax")) {
		stimulus.dots.rmax = 5;
	}
	
	if (! stimulus.dots.hasOwnProperty("xcenter")) {
		stimulus.dots.xcenter = 0;
	}
	
	if (! stimulus.dots.hasOwnProperty("ycenter")) {
		stimulus.dots.ycenter = 0;
	}
	
	if (! stimulus.dots.hasOwnProperty("dotsize")) {
		stimulus.dots.dotsize = 0.2;
	}
	
	if (! stimulus.dots.hasOwnProperty("density")) {
		stimulus.dots.density = 0.3;
	}
	
	if (! stimulus.dots.hasOwnProperty("coherence")) {
		stimulus.dots.coherence = 1;
	}
	if (! stimulus.dots.hasOwnProperty("speed")) {
		stimulus.dots.speed = 5;
	}
	if (! stimulus.dots.hasOwnProperty("dir")) {
		stimulus.dots.dir = 0;
	}
	
	stimulus.dots.width = 10;
	stimulus.dots.height = 10;
	
	stimulus.dots.n = Math.round(stimulus.dots.width * stimulus.dots.height * stimulus.dots.density);
	
	stimulus.dots.xmin = -stimulus.dots.width / 2;
	stimulus.dots.xmax = stimulus.dots.width / 2;
	stimulus.dots.ymin = -stimulus.dots.height / 2;
	stimulus.dots.ymax = stimulus.dots.height / 2;
	
	stimulus.dots.x = multiply(rand(task, stimulus.dots.n), stimulus.dots.width);
	stimulus.dots.y = multiply(rand(task, stimulus.dots.n), stimulus.dots.height);
	
	stimulus.dots.x = subtract(stimulus.dots.x, stimulus.dots.width / 2);
	stimulus.dots.y = subtract(stimulus.dots.y, stimulus.dots.height / 2);
	
	stimulus.dots.stepsize = stimulus.dots.speed / myscreen.framesPerSecond;
	
	jglOpen(myscreen.ppi);
	
	jglClearScreen();
	
	jglStencilCreateBegin(1);
	
	jglPoints2([stimulus.dots.xcenter], [stimulus.dots.ycenter], stimulus.dots.rmax, "#ffffff");
	
	jglStencilCreateEnd();
	
	jglClearScreen();
	
	jglClose();
	
	return task;
}

function updateDots(stimulus, task, myscreen) {
//	stimulus.dots.xstep = Math.cos(Math.PI * stimulus.dots.dir / 180) * stimulus.dots.stepsize;
//	stimulus.dots.ystep = Math.sin(Math.PI * stimulus.dots.dir / 180) * stimulus.dots.stepsize;
//	
//	stimulus.dots.coherent = lessThan(rand(task, stimulus.dots.n), stimulus.dots.coherence);
//	
//	stimulus.dots.x = add(stimulus.dots.x, stimulus.dots.xstep, stimulus.dots.coherent);
//	stimulus.dots.y = add(stimulus.dots.y, stimulus.dots.ystep, stimulus.dots.coherent);
//	
//	var notCo = not(stimulus.dots.coherent);
//	var thisdir = rand(task, sum(notCo)) * 2 * Math.PI;
//	
//	stimulus.dots.x = add(stimulus.dots.x, multiply(cos(thisdir), stimulus.dots.stepsize), notCo);
//	stimulus.dots.y = add(stimulus.dots.y, multiply(sin(thisdir), stimulus.dots.stepsize), notCo);
//	
//	stimulus.dots.x = add(stimulus.dots.x, stimulus.dots.width, lessThan(stimulus.dots.x, stimulus.dots.xmin));
//	stimulus.dots.x = subtract(stimulus.dots.x, stimulus.dots.width, greaterThan(stimulus.dots.x, stimulus.dots.xmax));
//	stimulus.dots.y = add(stimulus.dots.y, stimulus.dots.height, lessThan(stimulus.dots.y, stimulus.dots.ymin));
//	stimulus.dots.y = subtract(stimulus.dots.y, stimulus.dots.height, greaterThan(stimulus.dots.y, stimulus.dots.ymax));
	
	stimulus.dots.x = add(stimulus.dots.x,0.1);

	var over = greaterThan(stimulus.dots.x, 10);
	stimulus.dots.x = subtract(stimulus.dots.x, 10, over);
	
	jglStencilSelect(1);
	jglPoints2(stimulus.dots.x, stimulus.dots.y, stimulus.dots.dotsize, "#000000");
	jglStencilSelect(0);

	return stimulus;

}
