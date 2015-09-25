$(document).ready(function() {
	alttrialexperiment();
});

function alttrialexperiment() {

  window.myscreen = initScreen();

var instructionPages = [ // add as a list as many pages as you like
	"instructions/instruct-1.html",
	"instructions/instruct-2.html",
	"instructions/instruct-ready.html"
];

	window.task = [];
  task[0] = [];
	task[0][0] = initSurvey();
	task[0][0].html = "survey.html";
	task[0][1] = initInstructions(instructionPages);
	task[0][2] = {};
	task[0][2].waitForBacktick = 0;
	task[0][2].seglen = multiply(ones(11), 0.9);
	task[0][2].numTrials = 1;
	task[0][2].parameter = {};
	task[0][2].parameter.practice = 1;
  task[0][2].usingScreen = 1;
  task[0][2].html = "canvas.html";
	task[0][3] = initSurvey();
  task[0][3].html = "postsample.html";
  task[0][4] = initSurvey();
	task[0][4].html = "preExp.html";
  task[0][5] = {};
	task[0][5].seglen = multiply(ones(31), 0.9);
	task[0][5].numTrials = 1;
	task[0][5].parameter = {};
	task[0][5].parameter.practice = 0;
  task[0][5].usingScreen = 1;
  task[0][5].html = "canvas.html";
	task[0][6] = initSurvey();
	task[0][6].html = "postquestionnaire-1.html";
	task[0][7] = initSurvey();
	task[0][7].html = "postquestionnaire-2.html";


  task[0][2] = initTask(task[0][2], startSegmentCallback, screenUpdateCallback);
  task[0][5] = initTask(task[0][5], startSegmentCallback, screenUpdateCallback, undefined, startTrialCallback, endTrialCallback);

	window.stimulus = {};
	initStimulus('stimulus');

	myInitStimulus();

  initTurk();

		startPhase(task[0]);

}

var startTrialCallback = function(task, myscreen) {
  stimulus.dots.blue.sampleCount = stimulus.dots.blue.count;
	stimulus.dots.red.sampleCount = stimulus.dots.red.count;
	stimulus.dots.blue.count = 0;
	stimulus.dots.red.count = 0;

  return [task, myscreen];
}

var endTrialCallback = function(task, myscreen) {
  stimulus.dots.blue.realCount = stimulus.dots.blue.count;
	stimulus.dots.red.realCount = stimulus.dots.red.count;

  return [task, myscreen];
}

var startSegmentCallback = function(task, myscreen) {

  if (task.thistrial.thisseg == stimulus.polygon.moving.startseg) {
		stimulus.polygon.moving.x = stimulus.polygon.moving.xmax;
	}
  return [task, myscreen];
}

var screenUpdateCallback = function(task, myscreen) {

  jglClearScreen(128);

	stimulus.polygon.moving.x = add(stimulus.polygon.moving.x, stimulus.polygon.moving.xstepsize);

	stimulus.dots.blue.xstep = multiply(cos(divide(multiply(Math.PI, stimulus.dots.blue.dir), 180)), stimulus.dots.stepsize);
	stimulus.dots.blue.ystep = multiply(sin(divide(multiply(Math.PI, stimulus.dots.blue.dir), 180)), stimulus.dots.stepsize);
	
	
	stimulus.dots.red.xstep = multiply(cos(divide(multiply(Math.PI, stimulus.dots.red.dir), 180)), stimulus.dots.stepsize);
	stimulus.dots.red.ystep = multiply(sin(divide(multiply(Math.PI, stimulus.dots.red.dir), 180)), stimulus.dots.stepsize);

  var bluePos = greaterThan(stimulus.dots.blue.x, 0);
	var redPos = greaterThan(stimulus.dots.red.x, 0);

	stimulus.dots.blue.x = add(stimulus.dots.blue.x, stimulus.dots.blue.xstep);
	stimulus.dots.blue.y = add(stimulus.dots.blue.y, stimulus.dots.blue.ystep);
	stimulus.dots.red.x = add(stimulus.dots.red.x, stimulus.dots.red.xstep);
	stimulus.dots.red.y = add(stimulus.dots.red.y, stimulus.dots.red.ystep);

	var changeBluePos = greaterThan(stimulus.dots.blue.x, 0);
	var changeRedPos = greaterThan(stimulus.dots.red.x, 0);


	stimulus.dots.blue.count += sum(xor(bluePos, changeBluePos));
	stimulus.dots.red.count += sum(xor(redPos, changeRedPos));
  
  // Play sound

	if (task.thistrial.thisseg >= stimulus.polygon.moving.startseg) {
		if (any(greaterThan(stimulus.polygon.moving.x,-6))) {
			jglPolygon(stimulus.polygon.moving.x, stimulus.polygon.moving.y, stimulus.polygon.moving.color);
		}
	}

  var offBluePosX = greaterThan(stimulus.dots.blue.x, stimulus.dots.xrange);
  var offBluePosY = greaterThan(stimulus.dots.blue.y, stimulus.dots.yrange + stimulus.dots.ystart);
	var offBluePos = or(offBluePosX, offBluePosY);

	stimulus.dots.blue.dir = change(stimulus.dots.blue.dir, multiply(rand(task, sum(offBluePos)), stimulus.dots.degrees), offBluePos);
//	stimulus.dots.blue.x = change(stimulus.dots.blue.x, subtract(multiply(rand(task, sum(offBluePos)), 2*stimulus.dots.xrange), stimulus.dots.xrange), offBluePos);
	stimulus.dots.blue.x = change(stimulus.dots.blue.x, genXArray(sum(offBluePos)), offBluePos);
	stimulus.dots.blue.y = change(stimulus.dots.blue.y, subtract(multiply(rand(task, sum(offBluePos)), stimulus.dots.yrange), -stimulus.dots.ystart), offBluePos);

  var offBlueNegX = lessThan(stimulus.dots.blue.x, -stimulus.dots.xrange);
  var offBlueNegY = lessThan(stimulus.dots.blue.y, stimulus.dots.ystart);
	var offBlueNeg = or(offBlueNegX, offBlueNegY);

	stimulus.dots.blue.dir = change(stimulus.dots.blue.dir, multiply(rand(task, sum(offBlueNeg)), stimulus.dots.degrees), offBlueNeg);
	stimulus.dots.blue.x = change(stimulus.dots.blue.x, genXArray(sum(offBlueNeg)), offBlueNeg);
	stimulus.dots.blue.y = change(stimulus.dots.blue.y, subtract(multiply(rand(task, sum(offBlueNeg)), stimulus.dots.yrange), -stimulus.dots.ystart), offBlueNeg);

  var offRedPosX = greaterThan(stimulus.dots.red.x, stimulus.dots.xrange);
  var offRedPosY = greaterThan(stimulus.dots.red.y, stimulus.dots.yrange + stimulus.dots.ystart);
	var offRedPos = or(offRedPosX, offRedPosY);

	stimulus.dots.red.dir = change(stimulus.dots.red.dir, multiply(rand(task, sum(offRedPos)), stimulus.dots.degrees), offRedPos);
	//stimulus.dots.red.x = change(stimulus.dots.red.x, subtract(multiply(rand(task, sum(offRedPos)), 2*stimulus.dots.xrange), stimulus.dots.xrange), offRedPos);
	stimulus.dots.red.x = change(stimulus.dots.red.x, genXArray(sum(offRedPos)), offRedPos);
	stimulus.dots.red.y = change(stimulus.dots.red.y, subtract(multiply(rand(task, sum(offRedPos)), stimulus.dots.yrange), -stimulus.dots.ystart), offRedPos);

  var offRedNegX = lessThan(stimulus.dots.red.x, -stimulus.dots.xrange);
  var offRedNegY = lessThan(stimulus.dots.red.y, stimulus.dots.ystart);
	var offRedNeg = or(offRedNegX, offRedNegY);

	stimulus.dots.red.dir = change(stimulus.dots.red.dir, multiply(rand(task, sum(offRedNeg)), stimulus.dots.degrees), offRedNeg);
	stimulus.dots.red.x = change(stimulus.dots.red.x, genXArray(sum(offRedNeg)), offRedNeg);
	stimulus.dots.red.y = change(stimulus.dots.red.y, subtract(multiply(rand(task, sum(offRedNeg)), stimulus.dots.yrange), -stimulus.dots.ystart), offRedNeg);

	jglLines2([0], [15], [0], [-15], 0.02, "#00ff00");
  jglPoints2(stimulus.dots.blue.x, stimulus.dots.blue.y, stimulus.dots.blue.r, stimulus.dots.blue.color);
  jglPoints2(stimulus.dots.red.x, stimulus.dots.red.y, stimulus.dots.red.r, stimulus.dots.red.color);

  return [task, myscreen];

}

function myInitStimulus() {
	
	stimulus.dots = {};
	stimulus.dots.n = 5;
  stimulus.dots.xrange = 2;
	stimulus.dots.yrange = 4;
	stimulus.dots.ystart = -2;
	stimulus.dots.center = 0;
	stimulus.dots.condition = Math.round(rand(task[0][0])); // 1 is red, 0 is blue
  stimulus.dots.lineBuf = 0.4;

	var updateSegs = randPerm(task[0][0], 40);
	stimulus.dots.target = {};
	stimulus.dots.target.segs = index(updateSegs, [0,1,2,3,4]);
	stimulus.dots.stepsize = 0.02;
	stimulus.dots.backstep = 3;
	stimulus.dots.buffer = {};
	stimulus.dots.buffer.center = 0.12;

	stimulus.dots.degrees = 360;

  stimulus.dots.blue = {};
	stimulus.dots.blue.xstart = stimulus.dots.center + stimulus.dots.xrange;
	stimulus.dots.blue.ystart = stimulus.dots.center;
	stimulus.dots.blue.r = 0.2;
	stimulus.dots.blue.color = "#000000";
	stimulus.dots.blue.x = add(multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.xrange), stimulus.dots.blue.xstart);
	stimulus.dots.blue.y = add(multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.yrange), stimulus.dots.ystart);
	stimulus.dots.blue.dir = multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.degrees);
	stimulus.dots.blue.realCount = 0;
	stimulus.dots.blue.sampleCount = 0;
  stimulus.dots.blue.count = 0;

  stimulus.dots.red = {};
	stimulus.dots.red.xstart = stimulus.dots.center - stimulus.dots.xrange;
	stimulus.dots.red.ystart = stimulus.dots.center - 3;
	stimulus.dots.red.r = 0.2;
	stimulus.dots.red.color = "#ffffff";
	stimulus.dots.red.x = add(multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.xrange), stimulus.dots.red.xstart);
	stimulus.dots.red.y = add(multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.yrange), stimulus.dots.ystart);
	stimulus.dots.red.dir = multiply(rand(task[0][0], stimulus.dots.n), stimulus.dots.degrees);
	stimulus.dots.red.realCount = 0;
  stimulus.dots.red.sampleCount = 0;
  stimulus.dots.red.count = 0;

	stimulus.polygon = {};
  stimulus.polygon.moving = {};
	stimulus.polygon.moving.xmin = -100;
	stimulus.polygon.moving.xmax = [stimulus.dots.xrange + 1, stimulus.dots.xrange + 1.5, stimulus.dots.xrange + 1.25];
	stimulus.polygon.moving.x = stimulus.polygon.moving.xmax;
	stimulus.polygon.moving.y = [0.1, 0.1, -0.1];
	stimulus.polygon.moving.color = "#000000";
	stimulus.polygon.moving.xstepsize = [-0.025, -0.025, -0.025];
	stimulus.polygon.moving.speeds = [1, 2, 4, 8];
	stimulus.polygon.moving.multiplier = stimulus.polygon.moving.speeds[Math.round(rand(task[0][0]) * 3)];
	stimulus.polygon.moving.xstepsize = multiply(stimulus.polygon.moving.xstepsize, stimulus.polygon.moving.multiplier);
  stimulus.polygon.moving.startseg = 15;
}

function genXArray(length) {
  var negs = lessThan(rand(task[0][0], length), 0.5);

	var values = add(multiply(rand(task[0][0], length), stimulus.dots.xrange - stimulus.dots.lineBuf), stimulus.dots.lineBuf);

	values = change(values, multiply(index(values, negs, true), -1), negs);

	return values;

}
