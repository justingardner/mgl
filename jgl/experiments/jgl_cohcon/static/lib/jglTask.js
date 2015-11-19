/**
 * Generates block randomized combination of parameters. Unlike mgl it does
 * not randomly permutate the entire set of parameters. It only permutates
 * each block of trials individually. 
 * @memberof module:jglTask
 */
var blockRandomization = function(task, parameter, previousParamIndexes) {
	if (previousParamIndexes === undefined) {
		var temp = initRandomization(parameter);
		parameter = temp[0];
		if (! parameter.hasOwnProperty("doRandom_")) {
			parameter.doRandom_ = 1;
		}
		return parameter;
	}

	paramIndexes = [];
	var block = {};
	block.parameter = {};
	for (var paramnum = 0;paramnum<parameter.n_;paramnum++) {
		paramIndexes[paramnum] = [];
		for (var i = 0; i< parameter.totalN_ / parameter.size_[paramnum];i++) {

			if (parameter.doRandom_) {
				paramIndexes[paramnum] = paramIndexes[paramnum].concat(randPerm(task, parameter.size_[paramnum]));
			} else {
				paramIndexes[paramnum] = paramIndexes[paramnum].concat(jglMakeArray(0,1,parameter.size_[paramnum]));
			}
		}
		eval("block.parameter." + parameter.names_[paramnum] + " = index(parameter." + parameter.names_[paramnum] + ",paramIndexes[paramnum], false);");
	}
	block.trialn = parameter.totalN_;
	return block;
}/**
 * Function to get task seglen.
 * @param task the task object.
 * @returns {Array} [seglen, task]
 * @memberof module:jglTask
 */
function getTaskSeglen(task) {
	
	var seglen;
	if (task.timeInTicks || task.timeInVols) {
		seglen = add(task.segmin, floor(multiply(rand(numel(task.segmax)), (add(subtract(task.segmax, task.segmin), 1)))));
	} else {
		seglen = add(task.segmin, multiply(rand(task, numel(task.segmax)), subtract(task.segmax, task.segmin)));
		var temp = find(or(isinf(task.segmin), isinf(task.segmax)));
		jQuery.map(temp, function(n,i) {
			seglen[n] = Infinity;
		});
	}
	
	var nansegs = find(isnan(seglen));
	if (! isEmpty(nansegs)) {
		for (var i=0;i<nansegs.length;i++) {
			seglen[nansegs[i]] = task.segdur[nansegs[i]][sum(greaterThan(rand(task), task.segprob[nansegs[i]]))];
		}
	}
	return [seglen, task];
	// TODO: line 44 randstate
}/**
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
}/**
 * Function for initializing an instruction phase.
 * runExp checks to see if the current phase is an instruction phase
 *  and if so it starts instructions and when they finish it starts
 *  the next phase.
 *  @memberof module:jglTask
 */
function initInstructions(pages) {
//	myscreen.psiTurk.preloadPages(pages);
	var task = {};
	task.seglen = [10];
	task.usingScreen = 0;
	task.html = "instructions";
	
	task = initTask(task, function(task, myscreen){return [task, myscreen]}, function(task, myscreen){return [task, myscreen]});
	task.instructionPages = pages;
	
	return task;
}/**
 * Function to initialize the parameter object for the rand callback.
 * @param {Object} parameter the parameter object that needs initializing
 * @returns {Array} the first element is the initialized parameter object,
 * the second is a number, 1 means it was already initialized, 0 means it was not
 * @memberof module:jglTask
 */
function initRandomization(parameter) {
	var alreadyInitialized = false;
	
	if (parameter.hasOwnProperty("n_")) {
		console.log("initRandomization: Re-initialized parameters");
		alreadyInitialized = true;
	}
	parameter.names_ = [];
	parameter.n_ = [];
	parameter.size_ = [];
	parameter.totalN_ = [];

	
	var names = fields(parameter);
	
	var n = 0;
	
	for (var i = 0; i < names.length;i++) {
		if (isEmpty(names[i].match("_$"))) {
			parameter.names_[n++] = names[i];
		}
	}
	
	parameter.n_ = parameter.names_.length;
	
	for (var i=0;i<parameter.n_;i++) {
		var paramsize = eval("size(parameter." + parameter.names_[i] + ");");
		parameter.size_[i] = paramsize;
	}
	
	parameter.totalN_ = prod(parameter.size_);
	
	return [parameter, alreadyInitialized];
}

/**
 * Private function to get URL parameters
 * @returns an array of the params from the URL
 * @memberof module:jglTask
 */
function getURLParams() {
	var args = location.search;
	if (args.length > 0) {
		args = args.substring(1);
		return args.split('&');
	} else {
		return [];
	}
}

/**
 * Setups up screen object
 * @returns the setup screen object
 * @memberof module:jglTask
 */
function initScreen() {
	var screen = {};
	
	screen.screenWidth = window.screen.width; // width in pixels
	screen.screenHeight = window.screen.height; // height in pixels
	screen.ppi; // pixels per inch
	screen.data = {}; // some sort of data object TODO: more notes
	screen.events = {};
	screen.thisPhase; // current running phase
	screen.htmlPages = []; // all html pages to be used
	screen.psiTurk; // psiTurk object
//	this.keyboard = {};
//	this.keyboard.state = jglGetKeys; // pointer to keyboard status function
//	this.keyboard.backtick = '`';
//	this.mouse = jglGetMouse; // pointer to mouse status function
	screen.assignmentID; // assignmentID given by turk
	screen.hitID; // hitID given by turk
	screen.workerID; // workerID given by turk
	screen.startTime = jglGetSecs(); // start time, used for random state
	screen.numTasks = 0; // number of tasks
	var params = getURLParams();
	if (! isEmpty(params)) {
		screen.assignmentID = params[0].substring(params[0].indexOf('='));
		screen.hitID = params[1].substring(params[1].indexOf('='));
		screen.workerID = params[2].substring(params[2].indexOf('='));
	} else {
		console.error("init Screen: could not get assignmentID, hitID, or workerID");
	}
	
	screen.userHitEsc = 0;

	screen.events = {};
	screen.events.n = 0;
	screen.events.tracenum = [];
	screen.events.data = [];
	screen.events.ticknum = [];
	screen.events.time = [];
	screen.events.force = [];

	screen.traceNames = [];
	screen.traceNames[0] = 'volume';
	screen.traceNames[1] = 'segmentTime';
	screen.traceNames[2] = 'responseTime';
	screen.traceNames[3] = 'taskPhase';
	screen.traceNames[4] = 'fixationTask';

	screen.numTraces = 5;
	
	screen.tick = 0;
	screen.totaltick = 0;
	screen.totalflip = 0;
//	screen.volnum = 0;
	screen.intick = 0;
	screen.fliptime = Infinity;
	screen.dropcount = 0;
	screen.checkForDroppedFrames = 1;
	screen.dropThreshold = 1.05;
	screen.ppi = 127;
	screen.flushMode = 0;
	
	screen.framesPerSecond = 60;
	screen.frametime = 1 / screen.framesPerSecond;
	
	window.segTimeout = [];
	window.drawInterval = null;
	window.tnum = 0;
	
	return screen;
	
}/**
 * Function to register a stimulus name with myscreen.
 * Must be used if stimulus is to be saved to database.
 * @param {String} stimName the name of the stimulus to be registered with myscreen.
 * @memberof module:jglTask
 */
function initStimulus(stimName) {
	eval("window." + stimName + ".init = 1"); // set stimulus to inited.
	
	// register name in myscreen
	if (! myscreen.hasOwnProperty("stimulusNames")) {
		myscreen.stimulusNames = [];
		myscreen.stimulusNames[0] = stimName;
	} else {
		var notFound = 1;
		for (var i = 0;i<myscreen.stimulusNames.length;i++) {
			if (myscreen.stimulusNames[i].localeCompare(stimName) == 0) {
				console.log("init Stimulus: There is already a stimulus called " + stimName + " registered");
				notFound = 0;
			}
		}
		if (notFound) {
			myscreen.stimulusNames[myscreen.stimulusNames.length] = stimName;
		}
	}
}/**
 * Function for making a survey phase. Currently, all a survey phase is 
 * is a phase that has infinite blocks and trials and does not use the screen.
 * The html page defaults to survey.html
 * @returns {Object} the initialized task object 
 * @memberof module:jglTask
 */
function initSurvey() {
	
	var task = {};
	task.seglen = [10];
	task.usingScreen = 0;
	task.html = "survey.html";
	
	task = initTask(task, function(task, myscreen){return [task, myscreen]}, function(task, myscreen){return [task, myscreen]});
	

	
	task.numTrials = Infinity;
	task.numBlocks = Infinity;
	
	return task;
}/**
 * This is a phase object, while this constructor is never used, 
 * It is useful to see what members a phase object can have. 
 * @constructor

 * @property {Number} verbose determines if the phase object is verbose with the console.
 * @property {Object} parameter an object to hold parameters for trials.
 * @property {Array} seglen holds definite lengths of all segments within a trial
 * @property {Array} segmin holds the minimum values of all segment lengths
 * @property {Array} segmax holds the maximum values of all segment lengths
 * @property {Array} segquant holds the quantization of all segment lengths
 * @property {Array} segdur a 2-D array, an array for each segment of possible durations
 * @property {Array} segprob a 2-D array, an array for each segment of probabilities for each duration in segdur
 * @property {Array} segnames holds all the segment names
 * @property {Object|Boolean} seglenPrecompute if true, the seglens are precomputed, if false then not,
 * or if a precomputation is provided, then it is validated.
 * @property {Object} seglenPrecomputeSettings an object to determine the precompute settings
 * @property {Array} getResponse a logical array where zero means no response during that segment, one means collect response
 * @property {Number} numBlocks the maximum number of blocks to be run during this phase
 * @property {Number} numTrials the maximum number of trials to be run during this phase
 * @property {Number} timeInTicks 1 means keep track of time in ticks, 0 means don't (WARNING: not tested)
 * @property {Number} segmentTrace the number for the segment trace.
 * @property {Number} responseTrace the number for the response trace.
 * @property {Number} phaseTrace the number for the phase trace.
 * @property {Object} private this is an object with which you may do whatever you like.
 * @property {Object} randVars NOT USED
 * @property {Object} genRandom this is an object whose structure can be found in [rand.js]{@link rand.js}
 * @property {Number} usingScreen 1 means yes, 0 means no
 * @property {String} html the name of the html page to be used
 * @memberof module:jglTask
 */
function Phase() {
	this.verbose;
	this.parameter;
	this.seglen;
	this.segmin;
	this.segmax;
	this.segquant;
	this.segdur;
	this.segprob;
	this.segnames;
	this.seglenPrecompute;
	this.seglenPrecomputeSettings;
	this.writeTrace;
	this.getResponse;
	this.numBlocks;
	this.numTrials;
	this.timeInTicks;
	this.segmentTrace;
	this.responseTrace;
	this.phaseTrace;
	this.private;
	this.randVars;
	this.thisblock;
	this.genRandom;
	this.usingScreen;
}

/**
 * This is the jglTask module. It is in charge of managing an experiment and its structure. 
 * @module jglTask
 * @requires module:stdlib
 * @requires module:jgllib
 */

/**
 * Function for initializing a stimulus phase. 
 * @param {Object} task the phase object to be initialized, (cannot be null)
 * @param {Function} startSegmentCallback the callback function for a start Segment event. (required)
 * @param {Function} screenUpdateCallback the callback function for a screen update event. (required)
 * @param {Function} trialResponseCallback the callback function for a response event. (optional)
 * @param {Function} startTrialCallback the callback function for a start Trial event. (optional)
 * @param {Function} endTrialCallback the callback function for a end Trial event. (optional)
 * @param {Function} startBlockCallback the callback function for a start Block event. (optional)
 * @param {Function} randCallback the callback function to randomize the parameters in a block (optional)
 * @returns the initialized phase object. 
 * @memberof module:jglTask
 */
function initTask(task, startSegmentCallback,
		screenUpdateCallback, trialResponseCallback,
		startTrialCallback, endTrialCallback, 
		startBlockCallback, randCallback) {
	
	var knownFieldNames = ['verbose', 
	                   'parameter', 
	                   'seglen',
	                   'segmin', 
	                   'segmax', 
	                   'segquant', 
	                   'segdur',
	                   'segprob',
	                   'segnames', 
	                   'seglenPrecompute',
	                   'seglenPrecomputeSettings',
	                   'synchToVol', 
	                   'writeTrace', 
	                   'getResponse', 
	                   'numBlocks', 
	                   'numTrials', 
	                   'waitForBacktick', 
	                   'random', 
	                   'timeInTicks', 
	                   'timeInVols', 
	                   'segmentTrace', 
	                   'responseTrace', 
	                   'phaseTrace', 
	                   'parameterCode', 
	                   'private', 
	                   'randVars', 
	                   'fudgeLastVolume', 
	                   'collectEyeData',
	                   'data',
	                   'html',
	                   'notYetStarted',
	                   'usingScreen'
	            ];
	
	if (! task.hasOwnProperty("verbose")) {
		task.verbose = 1;
	}
	var taskFieldNames = fields(task);
	
	
	for (var i = 0; i < taskFieldNames.length;i++) {
		var upperMatch = upper(knownFieldNames).indexOf(taskFieldNames[i].toUpperCase());
		var match = knownFieldNames.indexOf(taskFieldNames[i]);
		if (upperMatch > -1 && match == -1) {
			console.error('initTask: task.' + taskFieldNames[i] + ' is miscappatilized, changing to task.' + knownFieldNames[upperMatch]);
			var value = task[taskFieldNames[i]];
			delete task[taskFieldNames[i]];
			task[knownFieldNames[upperMatch]] = value;
		} else if (upperMatch < 0) {
			console.error('initTask: unknown task field task.' + taskFieldNames[i]);
		}
	}
	
	if (! task.hasOwnProperty("parameter")) {
		task.parameter = {};
		task.parameter.default = 1;
	}
	
	
	task.notYetStarted = 1;
	task.blocknum = -1;
	task.thistrial = {};
	task.thistrial.thisseg = Infinity;
	
	if (task.hasOwnProperty("seglenPrecompute") && typeof task.seglenPrecompute === "object") {
		task = seglenPrecomputeValidate(task);
	} else {
		if (task.hasOwnProperty("seglen")) {
			if (task.hasOwnProperty("segmin") || task.hasOwnProperty("segmax")) {
				console.error("init Task: Found both seglen field and segmin/segmax. using seglen");
			}
			task.segmin = task.seglen;
			task.segmax = task.seglen;
		}
		if (! task.hasOwnProperty("segmin") || ! task.hasOwnProperty("segmax")) {
			console.error("init Task: Must specify task.segmin and task.segmax");
			throw "init Task"; // TODO: Should get input from user maybe?
		}
		
		if (! task.hasOwnProperty("segquant")) {
			task.segquant = zeros(task.segmin.length);
		} else if (task.segquant.length < task.segmin.length) {
			task.segquant = arrayPad(task.segquant, task.segmin.length, 0);
		}
		
		if (! task.hasOwnProperty("synchToVol")) {
			task.synchToVol = zeros(task.segmin.length);
		} else if (task.synchToVol.length < task.segmin.length) {
			task.synchToVol = arrayPad(task.synchToVol, task.segmin.length, 0);
		}
		
		if (! task.hasOwnProperty("segdur") || task.segdur.length < task.segmin.length) {
			task.segdur = [];
			task.segdur = arrayPad(task.segdur, task.segmin.length, []);
		} else if (task.segdur.length > task.segmin.length) {
			task.segmin = arrayPad(task.segmin, task.segdur.length, NaN);
			task.segmax = arrayPad(task.segmax, task.segdur.length, NaN);
			if (task.segquant.length < task.segmin.length) {
				task.segquant = arrayPad(task.segquant,task.segmin.length,0);
			}
			if (task.synchToVol.length < task.segmin.length) {
				task.synchToVol = arrayPad(task.synchToVol,task.segmin.length,0);
			}
		}
		
		if (! task.hasOwnProperty("segprob") || task.segprob.length < task.segmin.length) {
			task.segprob = [];
			task.segprob = arrayPad(task.segprob, task.segmin.length, []);
		}
		
		for (var i=0;i<task.segmin.length;i++) {
			if (! isEmpty(task.segdur[i])) {
				if (isEmpty(task.segprob[i])) {
					task.segprob[i] = fillArray(1 / task.segdur[i].length, task.segdur[i].length);
				} else if (task.segprob[i].length != task.segdur[i].length) {
					console.error("init Task: segprob and segdur for segment: " + i + " must have the same length");
					throw "init Task";
				} else if (Math.round(10000 * sum(task.segprob[i])) / 10000.0 != 1) {
					console.error("init Task: segprob for segment: " + i + " must add to one");
					throw "init Task";
				}
				
				task.segmin[i] = NaN;
				task.segmax[i] = NaN;
				
				task.segprob[i] = cumsum(task.segprob[i]);
				task.segprob[i] = [0].concat(task.segprob[i].slice(0, task.segprob[i].length - 1));
			} else if (! isEmpty(task.segprob[i])) {
				console.error("init Task: Non-empty segprob for empty segdur for seg: " + i);
				throw "init Task";
			} else if (isNaN(task.segmin[i])) {
				console.error("init Task: Segmin is nan without a segdur for seg: " + i);
				throw "init Task";
			}
		}
		
		for (var i = 0; i<task.segquant.length;i++) {
			if (task.segquant[i] != 0) {
				if (isEmpty(task.segdur[i])) {
					task.segdur[i] = jglMakeArray(task.segmin[i], task.segquant[i], task.segmax[i]);
					task.segprob[i] = cumsum(fillArray(1 / task.segdur[i].length, task.segdur[i].length));
					task.segprob[i] = [0].concat(task.segprob[i].slice(0,task.segprob[i].length - 1));
					task.segquant[i] = 0;
					task.segmin[i] = NaN;
					task.segmax[i] = NaN;
				}
			}
		}
		
		task.numsegs = task.segmin.length;
		
		if (task.segmin.length != task.segmax.length) {
			throw "init Task: task.segmin and task.segmax not of same length";
		}
		var difference = jQuery.map(task.segmax, function (n, i) {
			if (n - task.segmin[i] < 0)
				return 1;
			return 0;
		});
		if (any(difference)) {
			throw "init Task: task.segmin not smaller than task.segmax";
		}
		if (task.hasOwnProperty("segnames")) {
			if (numel(task.segnames) != task.numsegs) {
				console.error("init Task: task.segnames does not match the number of segments");
			} else {
				for (var i=0;i<task.segnames.length;i++) {
					// TODO: did not understand MATLAB code
				}
			}
		}
	}
	
	if (! task.hasOwnProperty("html")) {
		console.error("init Task, defaulting html page");
		task.html = "blank.html";
	}
	
	if (! task.hasOwnProperty("usingScreen")) {
		task.usingScreen = 0;
	}
	
	if (! task.hasOwnProperty("block")) {
		task.block = [];
	}
	
	if (! task.hasOwnProperty("timeInTicks")) {
		task.timeInTicks = 0;
	}
	
	if (! task.hasOwnProperty("timeInVols")) {
		task.timeInVols = 0;
	}
	
	if (task.timeInTicks && task.timeInVols) {
		console.error("init Task: Time is both in ticks and vols, setting to vols");
		task.timeInTicks = 0;
	}
	//TODO :
//	var randTypes = ["block", "uniform", "calculated"];
//	
//	if (typeof task.randVars != "object") {
//		task.randVars = {};
//	}
//	task.randVars.n_ = 0;
//	task.randVars.calculated_n_ = 0;
//	
//	if (! task.randVars.hasOwnProperty("len_")) {
//		if (task.hasOwnProperty("numTrials") && task.numTrials > -1) {
//			task.randVars.len_ = Math.max(task.numTrials, 250);
//		} else {
//			task.randVars.len_ = 250;
//		}
//	}
//	
//	var randVarNames = fields(task.randVars);
//	var originalNames = [], shortNames = [];
//	for (var i=0;i<randVarNames.length;i++) {
//		if (any(strcmp(randVarNames[i], randTypes))) {
//			var vars = {};
//			var thisRandVar = [];
//			var thisIsCell;
//			
//			if (! $.isArray(task.randVars[randVarNames[i]])) {
//				thisRandVar[1] = task.randVars[randVarNames[i]];
//				thisIsCell = false;
//			} else {
//				thisRandVar[0] = task.randVars[randVarNames[i]];
//				thisIsCell = true;
//			}
//			
//			for (var i=0;i<thisRandVar.length;i++) {
//				var varBlock = [], totalTrials = 0;
//				for (var vnum = 0;vnum<vars.n_;i++) {
//					if (thisIsCell) {
//						shortNames[shortNames.length] = vars.names_[vnum];
//					}
//				}
//			}
//		}
//	}
	
	if (! task.hasOwnProperty("getResponse")) {
		task.getResponse = [];
	}
	task.getResponse = arrayPad(task.getResponse, task.numsegs, 0);
	
	if (! task.hasOwnProperty("numBlocks")) {
		task.numBlocks = Infinity;
	}
	
	if (! task.hasOwnProperty("numTrials")) {
		task.numTrials = Infinity;
	}
	
	if (! task.hasOwnProperty("waitForBacktick")) {
		task.waitForBacktick = 0;
	}
	
	if (! task.hasOwnProperty("random")) {
		task.random = 0;
	}
	
	task.parameter.doRandom_ = task.random;
	
	task.trialnum = 0;
	task.trialnumTotal = 0;
	
	myscreen.numTasks += 1;
	task.taskID = myscreen.numTasks;
	
//	
//	if (! task.hasOwnProperty("segmentTrace")) {
//		if (myscreen.numTasks == 1) {
//			task.segmentTrace = 2;
//		} else {
//			var temp = addTraces(task, myscreen, 'segment');
//			task = temp[0];
//			myscreen = temp[1];
//		}
//	}
//	
//	if (! task.hasOwnProperty("responseTrace")) {
//		if (myscreen.numTasks == 1) {
//			task.segmentTrace = 3;
//		} else {
//			var temp = addTraces(task, myscreen, 'response');
//			task = temp[0];
//			myscreen = temp[1];
//		}
//	}
//	
//	if (! task.hasOwnProperty("phaseTrace")) {
//		if (myscreen.numTasks == 1) {
//			task.segmentTrace = 4;
//		} else {
//			var temp = addTraces(task, myscreen, 'phase');
//			task = temp[0];
//			myscreen = temp[1];
//		}
//	}
	
//	myscreen = writeTrace(1, task.phaseTrace, myscreen);
	
	if (! task.hasOwnProperty("callback")) {
		task.callback = {};
	}
	
	if (startSegmentCallback != undefined && jQuery.isFunction(startSegmentCallback)) {
		task.callback.startSegment = startSegmentCallback;
	}
	
	if (trialResponseCallback != undefined && jQuery.isFunction(trialResponseCallback)) {
		task.callback.trialResponse = trialResponseCallback;
	}
	
	if (screenUpdateCallback != undefined && jQuery.isFunction(screenUpdateCallback)) {
		task.callback.screenUpdate = screenUpdateCallback;
	}
	
	if (endTrialCallback != undefined && jQuery.isFunction(endTrialCallback)) {
		task.callback.endTrial = endTrialCallback;
	}
	
	if (startTrialCallback != undefined && jQuery.isFunction(startTrialCallback)) {
		task.callback.startTrial = startTrialCallback;
	}
	
	if (startBlockCallback != undefined && jQuery.isFunction(startBlockCallback)) {
		task.callback.startBlock = startBlockCallback;
	}
	
	if (randCallback != undefined && jQuery.isFunction(randCallback)) {
		task.callback.rand = randCallback;
	} else {
		task.callback.rand = blockRandomization;
	}
	
	task = setupTraces(task);
	
	task.parameter = task.callback.rand(task, task.parameter);
	
	if (task.hasOwnProperty("seglenPrecompute")) {
		if (typeof task.seglenPrecompute != "object") {
			task = seglenPrecompute(task);
		}
	} else {
		task.seglenPrecompute = false;
	}
	
	task.thistrial = {};
	task.timeDiscrepancy = 0;
	
	if (! task.hasOwnProperty("fudgeLastVolume")) {
		task.fudgeLastVolume = 0;
	}
	
	//TODO: didnt setup randstate stuff
	return task;
}

/**
 * Function to precompute the seglen array
 * @param {Object} task the task object to precompute in.
 * @returns {Object} the precomputed task object. 
 */
function seglenPrecompute(task) {
	task.seglenPrecompute = {};
	if (! task.hasOwnProperty("seglenPrecomputeSettings")) {
		task.seglenPrecomputeSettings = {};
	}

	var settingsDefaults = [
	                        {key: "synchWaitBeforeTime", value: 0.1},
	                        {key: "verbose", value: 1},
	                        {key: "averageLen", value: []},
	                        {key: "numTrials", value: []},
	                        {key: "maxTries", value: 500},
	                        {key: "idealDiffFromIdeal", value: []}
	                        ];

	for (var i=0;i<settingsDefaults.length;i++) {
		var settingsName = settingsDefaults[i].key;
		var settingsDefault = settingsDefaults[i].value;
		if (! task.seglenPrecomputeSettings.hasOwnProperty(settingsName)
				|| isEmpty(task.seglenPrecomputeSettings[settingsName])) {
			task.seglenPrecomputeSettings[settingsName] = settingsDefault;
		}
	}
	
	for (var i = 0; i<settingsDefaults.length;i++) {
		settingsName = settingsDefaults[i].key;
		eval("var " + settingsName + " = task.seglenPrecomputeSettings." + settingsName + ";");
	}
	
	var synchToVol = any(task.synchToVol);
	if (synchToVol) {
		if (! task.synchToVol[task.synchToVol.length - 1]) {
			console.error("init Task, segLenPrecompute: You have not set the last segment to have synchToVol though others are");
			throw "init Task";
		}
		if (! task.seglenPrecomputeSettings.hasOwnProperty("framePeriod")) {
			console.error("init Task, segLenPrecompute: You have set seglenPrecompute, and you have synchtoVol..."); //TODO: complete line 613
			throw "init Task";
		}
		var framePeriod = task.seglenPrecomputeSettings.framePeriod;
		if (! task.hasOwnProperty("fudgeLastVolume") || isEmpty(task.fudgeLastVolume)) {
			task.fudgeLastVolume = true;
		}
	} else {
		var framePeriod = NaN;
	}
	
	if (isEmpty(averageLen)) {
		var nSegs = task.segmin.length;
		var trialLens = [];
		trialLens[0] = {};
		trialLens[0].freq = 1;
		trialLens[0].min = 0;
		trialLens[0].max = 0;
		trialLens[0].segmin = [];
		trialLens[0].segmax = [];
		trialLens[0].synchmin = [];
		trialLens[0].synchmax = [];
		for (var i=0;i<nSegs;i++) {
			if (isNaN(task.segmin[i])) {
				var newTrialLens = [];
				var segprob = diff(task.segprob[i].concat([1]));
				for (var iTrial = 0;iTrial<trialLens.length;iTrial++) {
					for (var iSeg = 0;iSeg<task.segdur[i].length;iSeg++) {
						if (isEmpty(newTrialLens)) {
							newTrialLens = trialLens[iTrial];
						} else {
							newTrialLens[newTrialLens.length] = trialLens[iTrial];
						}
						newTrialLens[newTrialLens.length - 1].segmin[newTrialLens[newTrialLens.length - 1].segmin.length] = task.segdur[i][iSeg];
						newTrialLens[newTrialLens.length - 1].segmax[newTrialLens[newTrialLens.length - 1].segmax.length] = task.segdur[i][iSeg];
						newTrialLens[newTrialLens.length - 1].synchmin[newTrialLens[newTrialLens.length - 1].synchmin.length] = task.segdur[i][iSeg];
						newTrialLens[newTrialLens.length - 1].synchmax[newTrialLens[newTrialLens.length - 1].synchmax.length] = task.segdur[i][iSeg];
						newTrialLens[newTrialLens.length - 1].freq *= segprob[iSeg];
						newTrialLens[newTrialLens.length - 1].min += task.segdur[i][iSeg];
						newTrialLens[newTrialLens.length - 1].max += task.segdur[i][iSeg];

					}
				}
				trialLens = newTrialLens;
			} else if (task.segquant[i] == 0) {
				for (var iTrialLens=0;iTrialLens<trialLens.length;iTrialLens++) {
					trialLens[iTrialLens].min += task.segmin[i];
					trialLens[iTrialLens].max += task.segmax[i];
					trialLens[iTrialLens].segmin[trialLens[iTrialLens].segmin.length] = task.segmin[i];
					trialLens[iTrialLens].segmax[trialLens[iTrialLens].segmax.length] = task.segmax[i];
					trialLens[iTrialLens].synchmin[trialLens[iTrialLens].synchmin.length] = task.segmin[i];
					trialLens[iTrialLens].synchmax[trialLens[iTrialLens].synchmax.length] = task.segmax[i];
				}
			} else {
				// line 679
				var segLens = jglMakeArray(task.segmin[i], task.segquant[i], task.segmax[i]);
				if (segLens[segLens.length - 1] != task.segmax[i]) {
					segLens[segLens.length] = task.segmax[i];
				}
				var newTrialLens = [];
				for (var iTrialLen = 0;iTrialLen<trialLens.length;iTrialLen++) {
					var thisSegLenMin = task.segmin[i];
					var thisSegLen = task.segmax[i] - task.segmin[i];
					for (var iSegLen=0;iSegLen<segLens.length;iSegLen++) {
						if (isEmpty(newTrialLens)) {
							newTrialLens = trialLens[iTrialLen];
						} else {
							newTrialLens[newTrialLens.length] = trialLen[iTrialLen];
						}
						
						if (thisSegLen > 0) {
							var thisSegLenMax = Math.min(thisSegLenMin+task.segquant[i], task.segmax[i]);
							var freq = (thisSegLenMax=thisSegLenMin) / thisSegLen;
							thisSegLenMin = thisSegLenMax;
						} else {
							var freq = 1;
						}
						
						newTrialLens[newTrialLens.length - 1].freq *= freq;
						newTrialLens[newTrialLens.length - 1].min += segLens[iSegLen];
						newTrialLens[newTrialLens.length - 1].max += segLens[iSegLen];
						newTrialLens[newTrialLens.length - 1].segmin[newTrialLens[newTrialLens.length - 1].segmin.length] = segLens[iSegLen];
						newTrialLens[newTrialLens.length - 1].segmax[newTrialLens[newTrialLens.length - 1].segmax.length] = segLens[iSegLen];
						newTrialLens[newTrialLens.length - 1].synchmin[newTrialLens[newTrialLens.length - 1].synchmin.length] = segLens[iSegLen];
						newTrialLens[newTrialLens.length - 1].synchmax[newTrialLens[newTrialLens.length - 1].synchmax.length] = segLens[iSegLen];


					}
				}
				trialLens = newTrialLens;
			}
			
			if (task.synchToVol[i]) {
				var newTrialLens = [];
				for (var iTrialLen = 0; iTrialLen<trialLens.length;iTrialLen++) {
					var minLen = trialLens[iTrialLen].min;
					var maxLen = trialLens[iTrialLen].max;
					var segLens = jglMakeArray(Math.ceil(minLen / framePeriod) * framePeriod, framePeriod, Math.ceil(maxLen / framePeriod) * framePeriod);
					var segLensProbCompute = [minLen].concat(segLens);
					for (var iSegLen = 0;iSegLen < segLens.length;iSegLen++) {
						if (isEmpty(newTrialLens)) {
							newTrialLens = trialLens[iTrialLen];
						} else {
							newTrialLens[newTrialLens.length] = trialLens[iTrialLen];
						}
						newTrialLens[newTrialLens.length].min = segLens[iSegLen];
						newTrialLens[newTrialLens.length].max = segLens[iSegLen];
						
						if (sum(newTrialLens[newTrialLens.length - 1].synchmin) == sum(newTrialLens[newTrialLens.length - 1].synchmax)) {
							var freq = 1;
						} else {
							var freq = computeLenProb(newTrialLens[newTrialLens.length - 1].synchmin, newTrialLens[newTrialLens.length - 1].synchmax, segLensProbCompute[iSegLen], segLensProbCompute[iSegLen + 1]);
						}
						
						newTrialLens[newTrialLens.length - 1].freq *= freq;
						var synchWaitTime = newTrialLens[newTrialLens.length - 1].max - sum(newTrialLens[newTrialLens.length - 1].segmin);
						
						synchWaitTime = Math.max(synchWaitTime - synchWaitBeforeTime, 0);
						newTrialLens[newTrialLens.length - 1].segmin[newTrialLens[newTrialLens.length - 1].segmin.length] += synchWaitTime;
						newTrialLens[newTrialLens.length - 1].segmax[newTrialLens[newTrialLens.length - 1].segmax.length] = 
							newTrialLens[newTrialLens.length - 1].segmin[newTrialLens[newTrialLens.length - 1].segmin.length];
						newTrialLens[newTrialLens.length - 1].synchmin[newTrialLens[newTrialLens.length - 1].synchmin.length] = newTrialLens[newTrialLens.length - 1].min;
						newTrialLens[newTrialLens.length - 1].synchmax[newTrialLens[newTrialLens.length - 1].synchmax.length] = newTrialLens[newTrialLens.length - 1].max;
					}
				}
				trialLens = newTrialLens;
			}
		}
		
		var averageLen = 0, actualNumTrials = 0;
		
		for (var iTrialLen = 0;iTrialLen < trialLens.length; iTrialLen++) {
			averageLen += trialLens[iTrialLen].freq * (trialLens[iTrialLen].max + trialLens[iTrialLen].min) / 2;
		}
		
		if (verbose > 1) {
			for (var i =0 ; i < trialLens.length;i++) {
				var seglenStr = "seglen=[";
				for (iSeg = 0; iSeg < trialLens[i].segmin.length;iSeg++) {
					if (task.synchToVol[iSeg]) {
						var seglen = trialLens[i].segmin[iSeg] + synchWaitBeforeTime;
						seglenStr = seglenStr.concat("*", seglen);
					} else {
						if (trialLens[i].segmin[iSeg] == trialLens[i].segmax[iSeg]) {
							seglenStr = seglenStr.concat(trialLens[i].segmax[iSeg]);
						} else {
							seglenStr = seglenStr.concat(trialLens[i].segmin[iSeg] , "-", trialLens[i].segmax[iSeg]);
						}
					}
				}
				seglenStr = seglenStr.concat("]");
				
				if (trialLens[i].min == trialLens[i].max) {
					var trialLenStr = "trialLen: " + trialLens[i].min;
				} else {
					var trialLenStr = "trialMin: " + trialLens[i].min + " trialMax: " + trialLens[i].max;
				}
				
				var trialFreqStr = "frequency: " + trialLens[i].freq;
				console.log("initTask: seglenPrecompute ", trialLenStr, seglenStr, trialFreqStr);
			}
		}
	}
	if (isEmpty(numTrials)) {
		if (task.hasOwnProperty("numTrials") && ! isEmpty(task.numTrials) && isFinite(task.numTrials)) {
			numTrials = task.numTrials;
		} else if (task.hasOwnProperty("numBlocks") && ! isEmpty(task.numBlocks) && ! isFinite(task.numTrials)) {
			numTrials = task.numBlocks * task.parameter.totalN_;
		} else {
			console.error("init Task: Must set number of trials to precompute");
			throw "init Task";
		}
	}
	
	console.log("init Task: Computing " + numTrials + " trials with average length " + averageLen);
	var trialLength = [], seglen, newTrialLength;
	task.seglenPrecompute.seglen = [];
	for (var i = 0;i < numTrials;i++) {
		var temp = getTaskSeglen(task);
		seglen = temp[0];
		task = temp[1];
		
		temp = computeTrialLen(seglen, task.synchToVol, framePeriod, synchWaitBeforeTime);
		trialLength[i] = temp[0];
		seglen = temp[1];
		task.seglenPrecompute.seglen[i] = seglen;
	}
	
	// TODO: line 838 randstate
	
	var diffFromIdeal = numTrials*averageLen - sum(trialLength);
	
	if (isEmpty(idealDiffFromIdeal)) {
		if (! isNaN(framePeriod)) {
			idealDiffFromIdeal = framePeriod / 2;
		} else {
			idealDiffFromIdeal = 1;
		}
	}
	
	var nTries = 0;
	
	while (Math.abs(diffFromIdeal) > idealDiffFromIdeal) {
		var randTrialNum = Math.ceil(rand(task)*numTrials);
		var temp = getTaskSeglen(task);
		seglen = temp[0];
		task = temp[1];
		
		temp = computeTrialLen(seglen, task.synchToVol, framePeriod, synchWaitBeforeTime);
		newTrialLength = temp[0];
		seglen = temp[1];
		var newDiffFromIdeal = numTrials*averageLen-
			(sum(index(trialLength,jglMakeArray(0, undefined, randTrialNum - 1).concat(jglMakeArray(randTrialNum+1, undefined, trialLength.length)), false))
					+ newTrialLength);
		
		if ((Math.abs(newDiffFromIdeal) < Math.abs(diffFromIdeal)) || (rand(task) < 0.1)) {
			trialLength[randTrialNum] = newTrialLength;
			task.seglenPrecompute.seglen[randTrialNum] = seglen;
			diffFromIdeal = newDiffFromIdeal;
		}
		
		nTries++;
		
		if (nTries % maxTries == 0) {
			// TODO: line 869
		}
	}
		
		// TODO: line 876

	trialLength = [];
	for (var i=0;i<numTrials;i++) {
		var temp = computeTrialLen(task.seglenPrecompute.seglen[i], task.synchToVol, framePeriod, synchWaitBeforeTime);
		trialLength[i] = temp[0];
		seglen = temp[1];
		if (verbose > 1) {
			console.log("init Task:seglenPrecompute Trial #" + i + ": seglen [" + seglen + "] trialLen: " + trialLength[i]);
		}
	}

	var numVolumes = [];
	if (! isNaN(framePeriod)) {
		numVolumes = Math.round((numTrials * averageLen) / framePeriod);
	}

	if (verbose) {
		console.log("init Task: seglenPrecompute Total length .... line 896"); // TODO: fix
		if (! isEmpty(numVolumes)) {
			console.log("init Task: seglenPrecompute volumes needed .... line 898"); // TODO: fix
		}
	}

	if (synchToVol || isEqual([trialLens.min], [trialLens.max])) {
		var lens = $.unique(trialLength);
		var freq = diff([0].concat(find(diff(trialLength.sort())), trialLength.length));
		if (trialLens != undefined) {
			var temp = unique(gatherFields(trialLens, "max")); 
			var expectedLens = temp[0];
			var dummy = temp[1];
			var indexes = temp[2];

			var expectedFreq = [];
			for (var iLen = 0; iLen< expectedLens.length;iLen++) {
				expectedFreq[iLen] = sum(gatherFields(index(trialLens, equals(indexes, iLen), true), "freq"));
			}
		} else {
			var expectedLens = lens;
			var expectedFreq = nan(lens.length);
		}
		lens = jQuery.map(lens, function (n, i) {
			return Math.round(n * 1000000) / 1000000;
		});
		expectedLens = jQuery.map(expectedLens, function (n, i) {
			return Math.round(n * 1000000) / 1000000;
		});

		for (var iLen = 0;iLen<expectedLens.length;iLen++) {
			var matchLen = find(equals(lens, expectedLens[iLen]));
			if (isEmpty(matchLen)) {
				if (expectedFreq[iLen] > 0) {
					console.log("something ... line 928 initTask");
				}
			} else {

			}
		}
	}
	
	task = seglenPrecomputeValidate(task);
	
	if (! isEmpty(numVolumes) && ! task.seglenPrecompute.hasOwnProperty("numVolumes")) {
		task.seglenPrecompute.numVolumes = numVolumes;
	}
	if (! task.seglenPrecompute.hasOwnProperty("totalLength")) {
		task.seglenPrecompute.totalLength = sum(trialLength);
	}
	
	return task;
}


function computeTrialLen(seglen, synchToVol, framePeriod, synchWaitBeforeTime) {
	var seglenSynch = seglen;
	var findArray = find(synchToVol);
	for (var i = 0;i < findArray.length;i++) {
		seglenSynch[findArray[i]] = Math.ceil(sum(index(seglenSynch, jglMakeArray(1, undefined, findArray[i]), false)) / framePeriod)*framePeriod - sum(index(seglenSynch, jglMakeArray(1, undefined, findArray[i]-1), false));
	}
	var trialLen = sum(seglenSynch);
	findArray = find(synchToVol);
	for (var i = 0; i < findArray.length;i++) {
		if (seglenSynch[findArray[i]] > synchWaitBeforeTime) {
			seglen[findArray[i]] = Math.min(seglen[findArray[i]], seglenSynch[findArray[i]] - synchWaitBeforeTime);
		}
	}
	return [trialLen, seglen];
}

//function computeLenProb(segmin, segmax, lenmin, lenmax) {
//	
//}
/**
 * Function to validate a given seglenPrecompute object.
 * @param {Ojbect} task the task object. 
 * @returns {Object} the task object.
 * @memberof module:jglTask
 */
function seglenPrecomputeValidate(task) {
	if (task.seglenPrecompute === false) {
		return;
	}
	
	if (typeof task.seglenPrecompute != "object") {
		console.error("init Task: seglenPrecomputeValidate task.seglenPrecompute should be an object");
		throw "init Task";
	}
	
	if (! task.seglenPrecompute.hasOwnProperty("seglen")) {
		console.error("init Task: seglenPrecompute must have the field seglen");
		throw "init Task";
	}
	
	task.seglenPrecompute.fieldNames = fields(task.seglenPrecompute);
	task.seglenPrecompute.nFields = task.seglenPrecompute.fieldNames.length;
	
	var x = {};
	
	for (var i = 0;i<task.seglenPrecompute.nFields;i++) {
		x.vals = eval("task.seglenPrecompute." + task.seglenPrecompute.fieldNames[i]);
		$.isArray(x.vals) ? x.nTrials = x.vals.length : x.nTrials = 1;
		eval("task.seglenPrecompute." + task.seglenPrecompute.fieldNames[i] + " = x");
	}
	
	task.seglenPrecompute.fieldNames.splice(task.seglenPrecompute.fieldNames.indexOf('seglen'), 1);
	task.seglenPrecompute.nFields--;
	
	task.numsegs = 0;
	
	for (var i = 0; i<task.seglenPrecompute.seglen.nTrials;i++) {
		task.numsegs = Math.max(task.numsegs, task.seglenPrecompute.seglen.vals[i].length);
	}
	
	if (! task.hasOwnProperty('synchToVol') || task.synchToVol.length < task.numsegs) {
		arrayPad(task.synchToVol, task.numsegs, 0);
	}
	
	if (! task.hasOwnProperty('segquant') || task.segquant.length < task.numsegs) {
		arrayPad(task.segquant, task.numsegs, 0);
	}
	
	if (! task.hasOwnProperty('segdur') || task.segdur.length < task.numsegs) {
		arrayPad(task.segdur, task.numsegs, []);
	}
	
	if (! task.hasOwnProperty('segprob') || task.segprob.length < task.numsegs) {
		arrayPad(task.segprob, task.numsegs, []);
	}
	
	return task;
}

/**
 * Function to setup trace numbers
 * @param {Object} task the phase object
 * @returns the setup phase object
 * @memberof module:jglTask
 * @private
 */
function setupTraces(task) {
	var start = ((task.taskID - 1) * 3) + 1;
	task.segmentTrace = start++;
	task.responseTrace = start++;
	task.phaseTrace = start;
	return task;
}/**
 * Initializes turk experiment.
 * Gathers all turk data (uniqueID, condition, adServerloc, and counterbalance)
 * initializes the psiTurk object.
 * loads the pages.
 * calls initData to setup key and mouse events. 
 * @memberof module:jglTask
 */
function initTurk() {
		
	myscreen.uniqueId = uniqueId;
	myscreen.condition = condition;
	myscreen.counterbalance = counterbalance;
	myscreen.adServerLoc = adServerLoc;
	myscreen.psiTurk = new PsiTurk(uniqueId, adServerLoc);
	
	var pageNames = [];
	window.jgl_Done_ = [];
	for (var i = 0;i<task.length;i++) {
		for (var j = 0;j<task[i].length;j++) {
			if (task[i][j].html.localeCompare("instructions") == 0) {
				pageNames = pageNames.concat(task[i][j].instructionPages);
			} else {
				pageNames.push(task[i][j].html);
			}
		}
	}
	myscreen.psiTurk.preloadPages(pageNames);
	myscreen.htmlPages = pageNames;
	initData();
}/**
 * Function to generate random numbers in a controlled way.
 * Since one cannot set the random number generator seed in
 * JavaScript this solution was devised. The task object
 * has a field, genRandom which contains and array of random numbers.
 * this function grabs a number from that array while growing the array
 * if necessary. To recreate the experiment initialize the task object with
 * the same genRandom field. 
 * @param {Object} task the task object
 * @param {Number} length the length of the array to return, if left undefined a single number will be returned
 * @returns {Number|Array} A single number or array of random numbers between 0 and 1
 * @memberof module:jglTask
 */
function rand(task, length) {
	if (! task.hasOwnProperty("genRandom")) {
		task.genRandom = {};
		task.genRandom.current = 0;
		task.genRandom.nums = new Array(32);
		for (var i =0;i<task.genRandom.nums.length;i++) {
			task.genRandom.nums[i] = Math.random();
		}
	}
	if (length === undefined) {
		if (task.genRandom.current == task.genRandom.nums.length) {
			task.genRandom.nums = randomResize(task.genRandom.nums);
		}

		return task.genRandom.nums[task.genRandom.current++];
	} else {
		while (task.genRandom.current + length >= task.genRandom.nums.length) {
			task.genRandom.nums = randomResize(task.genRandom.nums);
		}
		var temp = new Array(length);
		for (var i=0;i<length;i++) {
			temp[i] = task.genRandom.nums[task.genRandom.current++];
		}
		return temp;
	}
}

/**
 * Function for growing the array of random numbers.
 * @param array the array to grow
 * @returns {Array} the new array, twice the size
 * @memberof module:jglTask
 */
function randomResize(array) {
	var tempArray = new Array(array.length * 2);
	for (var i=0;i<array.length;i++) {
		tempArray[i] = array[i];
	}
	for (var i=array.length;i<tempArray.length;i++) {
		tempArray[i] = Math.random();
	}
	return tempArray;
}/*
 * This file contains the functions that control the experimental timing.
 * The experiment is now event based unlike mgl. The experiment is started
 * by calling startPhase on each task. These calls then fall down a chain
 * starting the first block, then the first trial, then the first segment. 
 * The segment then sets a timeout to call startSeg after the segment has 
 * finished. startPhase, startBlock, startTrial, and startSeg all check to
 * see if they are the last one and if so to start the next. Note that if 
 * startPhase sees that its past the last phase it calls finishExp. 
 * 
 * nextPhase is an important function for artificially changing phases. This
 * is used for survey type phases where there are infinite trials and blocks.
 * nextPhase should be called when a done button is pressed. This JS must be
 * included in the html page for that phase. 
 */


/**
 * This experiment finishes the Experiment, it clears all intervals and timeouts.
 * It unbinds the keydown and mousedown events, and calles completeHIT.
 * @memberof module:jglTask
 */
function finishExp() {
	clearIntAndTimeouts();
	$("body").unbind("keydown", keyResponse);
	$("body").unbind("mousedown", mouseResponse);
	saveAllData();	
}

/**
 * This function clears all timeouts and intervals that have been set. 
 * This is important when advancing to the next phase or ending the experiment. 
 * @memberof module:jglTask
 */
function clearIntAndTimeouts() {
	for (var i=0;i<window.segTimeout.length;i++) {
		if (window.segTimeout.length) {
			clearTimeout(window.segTimeout[i]);
		}
	}
	if (window.drawInterval) {
		window.cancelAnimationFrame(window.drawInterval);
		// clearInterval(window.drawInterval);
		window.drawInterval = null;
	}
}

/**
 * This function advances to the next phase. It stops the previous phase by
 * clearing the timeout and interval that runs that phase then calls startPhase.
 * @memberof module:jglTask
 */
var nextPhase = function() {
	clearIntAndTimeouts();
	tnum++;
	if (task[0][tnum - 1].usingScreen) {
		jglClose();
	}
	for (var i=0;i<window.task.length;i++) {
		startPhase(task[i]);
	}
}

/**
 * This function starts the current phase dictated by tnum. It loads the html page for 
 * the phase, opens the screen if needed, and starts an interval if needed.
 * If tnum is too high it calls finishExp.
 * @param {Array} task the task object (an array of phases)
 * @memberof module:jglTask
 */
var startPhase = function(task) {
	if (tnum == task.length) {
		finishExp();
		return;
	}
	if (task[tnum].html.localeCompare("instructions") == 0) {
		myscreen.psiTurk.doInstructions(task[tnum].instructionPages, nextPhase);
		return;
	}
	
	myscreen.psiTurk.showPage(task[tnum].html);
	if (task[tnum].usingScreen) {
		if (! jglIsOpen()) {
			jglOpen(myscreen.ppi);
		}
		if (! window.drawInterval) {
			// window.drawInterval = setInterval(tickScreen, 17);
			window.drawInterval = window.requestAnimationFrame(requestFrame);
		}
	}
	writeTrace(1, task[tnum].phaseTrace);
	initBlock(task[tnum]);
	startBlock(task);
}

var requestFrame = function() {
	tickScreen();

	window.drawInterval = window.requestAnimationFrame(requestFrame);
}

/**
 * This function starts a block. First is checks to make sure there are blocks left, if
 * so it starts the current block by initing a trial and starting it.
 * @param {Array} the task object (array of phases)
 * @memberof module:jglTask
 */
var startBlock = function(task) {
	if (task[tnum].blocknum == task[tnum].numBlocks) { // If phase is done due to blocks
		nextPhase();
		return;
	}
	if (task[tnum].callback.hasOwnProperty("startBlock")) {
		var temp = task[tnum].callback.startBlock(task[tnum], myscreen);
		task[tnum] = temp[0];
		myscreen = temp[1];
	}
	initTrial(task[tnum]);
	startTrial(task);
}

/**
 * This function starts a trial. First it checks to make sure that there are more trials
 * left in the block, if not, it inits a new block and starts it. If there are no more trials
 * left in the phase it calls nextPhase. Otherwise it starts the first segment.
 * @memberof module:jglTask
 * @param {Array} task the task object (array of phases)
 */
var startTrial = function(task) {
	if (task[tnum].blockTrialnum == task[tnum].block[task[tnum].blocknum].trialn) {
		initBlock(task[tnum]);
		startBlock(task);
		return;
	}
	if (task[tnum].trialnum == task[tnum].numTrials) {
		nextPhase();
		return;
	}
	if (task[tnum].callback.hasOwnProperty("startTrial")) {
		var temp = task[tnum].callback.startTrial(task[tnum], myscreen);
		task[tnum] = temp[0];
		myscreen = temp[1];
	}
	startSeg(task);
}

/**
 * This function is very important. It starts a segment. First it checks to makes sure
 * that there are more segments to run, if not it inits a new trial and starts it, otherwise, 
 * it sets a timeout for the length of the current segment to call startSeg again. This timeout
 * is only set if the segment has a finite length. If the length of the segment is infinite, 
 * It does not set a timeout. In this case it is vital that startSeg be called in the response callback.
 * @param {Array} task the task object (array of phases)
 * @memberof module:jglTask
 */
var startSeg = function(task) {
	if (task[tnum].thistrial.thisseg == task[tnum].thistrial.seglen.length - 1) {
		if (task[tnum].callback.hasOwnProperty("endTrial")) {
			var temp = task[tnum].callback.endTrial(task[tnum], myscreen);
			task[tnum] = temp[0];
			myscreen = temp[1];
		}
		
		//TODO: randVars line 253
		
		task[tnum].blockTrialnum++;
		task[tnum].trialnum++;
		
//		task[tnum].thistrial.waitingToInit = 1;
		initTrial(task[tnum]);
		startTrial(task);
		return;
		//TODO: randstate
		
	}
	
	task[tnum].thistrial.thisseg++;
	
	if (task[tnum].callback.hasOwnProperty("startSegment")) {
		var temp = task[tnum].callback.startSegment(task[tnum], myscreen);
		task[tnum] = temp[0];
		myscreen = temp[1];
	}
	
	writeTrace(1, task[tnum].segmentTrace);
	thistime = jglGetSecs();

	task[tnum].thistrial.trialstart = thistime;
	if (isFinite(task[tnum].thistrial.seglen[task[tnum].thistrial.thisseg])) {
		window.segTimeout[task[tnum].taskID] = setTimeout(startSeg, task[tnum].thistrial.seglen[task[tnum].thistrial.thisseg] * 1000, task);
	}
	return;
}

/**
 * Function to jump to a different segment. This function is to mainly be used in the response callback
 * in conjunction with infinitely long segments.
 * @param task {Object} the phase
 * @param tasknum {Number} the task number that this phase belongs to
 * @param segnum {Number} the segment to jump to. If undefined, start next segment, if Infinity, start next trial,
 * if number, start that segment. 
 * @memberof module:jglTask
 */
function jumpSegment(task, tasknum, segnum) {
	clearTimeout(window.segTimeout[task.taskID]);
	if (segnum === undefined) {
		startSeg(window.task[tasknum]);
	} else if (! isFinite(segnum)) {
		startTrial(window.task[tasknum]);
	} else {
		if (segnum >= task.thistrial.seglen.length) {
			throw "jumpSegment: segnum too high";
		}
		task.thistrial.thisseg = segnum - 1;
		startSeg(window.task[tasknum]);
	}
}

/**
 * This function inits a block. It calls the rand callback which is defaultly set to blockRandomization
 * to set the parameter orders. then calls startBlock callback if present. 
 * @param {Ojbect} task the task object to init a block for.
 * @memberof module:jglTask
 */
function initBlock(task) {
	
	task.blocknum++;
	
	if (task.blocknum > 0) {
		task.block[task.blocknum] = task.callback.rand(task, task.parameter, task.block[task.blocknum-1]);
	} else {
		task.block[task.blocknum] = task.callback.rand(task, task.parameter, []);
	}
	
	task.blockTrialnum = 0;
	

}

/**
 * This function inits a trial. A trial object keeps track of the current segment,
 * if a response has been collected, and the seglen array. Calls startTrial callback.
 * @param {Object} task the task object
 * @memberof module:jglTask
 */
function initTrial(task) {
	task.lasttrial = task.thistrial;
	task.thistrial.thisphase = tnum;

	task.thistrial.thisseg = -1;
	task.thistrial.gotResponse = 0;

	task.thistrial.segstart = -Infinity;

	if (task.seglenPrecompute === false) {
		var temp = getTaskSeglen(task);
		var seglen = temp[0];
		task = temp[1];

		task.thistrial.seglen = seglen;
	} else {
		for (var i = 0;i<task.seglenPrecompute.nFields;i++) {
			fieldName = task.seglenPrecompute.fieldNames[i];

			fieldRow = (task.trialnum % task.seglenPrecompute[fieldName].nTrials)// + 1

			task.thistrial[fieldName] = task.seglenPrecompute[fieldName].vals[fieldRow];
		}

		fieldRow = Math.min(task.seglenPrecompute.seglen.nTrials, task.trialnum);
		task.thistrial.seglen = task.seglenPrecompute.seglen.vals[fieldRow];
	}

//	if (task.waitForBacktick && (task.blocknum == 0) && task.blockTrialnum == 0) {
//		task.thistrial.waitForBacktick = 1;
//		backtick = myscreen.keyboard.backtick;
//		console.log("updateTask: wating for backtick: '"+ backtick + "'");
//	} else {
		task.thistrial.waitForBacktick = 0;
//	}

	task.thistrial.buttonState = [0,0];

	for (var i =0;i<task.parameter.n_;i++) {
		eval("task.thistrial." + task.parameter.names_[i] + " = task.block[task.blocknum].parameter." + task.parameter.names_[i] + "[task.blockTrialnum];");
	}

	//TODO: randvars line 507



	task.thistrial.waitingToInit = 0;
}/**
 * Function for generating an XML object from a javascript object.
 * Requires that the root tag be places around the return value.
 * This is the xml tagname scheme:
 * All objects are surrounded by an object tag, every field of an
 * object has its own tagname. Arrays are surrounded by array tag
 * names. Array tags have an attribute type, with either cell or mat
 * as the value. mat means its a numeric array and can be a matrix in matlab.
 * cell means the array contains non-numeric elements. Every value is enclosed in
 * a val tag. val tags also have a type attribute, with a value num or str. num means
 * it isNumeric, str means its not.
 * @param {Any} object the object to XMLify
 * @param {String} xml should always be left undefined
 * @returns {String} The XML version of the given object, object 
 * field names are tags, array tag starts an array, val tag for value of a given item.
 * @memberof module:jglTask
 */
function genXML(object, xml) {
	if (xml === undefined) {
		xml = "";
	}
	if ($.type(object) == "object") {
		var fieldNames = fields(object);
		xml += "<object>";
		for (var i =0; i<fieldNames.length;i++) {
			if (fieldNames[i] != "callback" && fieldNames[i] != "psiTurk") {
				xml += "<" + fieldNames[i] + ">";
				xml += genXML(object[fieldNames[i]]);
				xml += "</" + fieldNames[i] + ">";
			}
		}
		xml += "</object>";
	} else if ($.isArray(object)) {
		if (isNumeric(object)) {
			xml += '<array type=&quot;mat&quot;>'; // &quot; is an escaped " in xml
		} else {
			xml += '<array type=&quot;cell&quot;>';
		}
		for (var i = 0;i<object.length;i++) {
			xml += genXML(object[i]);
		}
		xml += "</array>";
	} else {
		if (isNumeric(object)) {
			xml += '<val type=&quot;num&quot;>' + object + '</val>';
		} else {
			xml += '<val type=&quot;str&quot;>' + object + '</val>';
		}
	}
	return xml;
}

/**
 * Function to save all of the data to the database.
 * This function creates a large object xml string containing
 * the jglData object, the task array, the myscreen object, and
 * all stimulus objects that have been registered with initStimulus.
 * The xml is then saved in the database using psiTurk with the key
 * experimentXML.
 * @memberof module:jglTask
 */
function saveAllData() {
	/*
	 * xml will represent an xml object with jglData, task, myscreen, and all
	 * the stimuli as fields. The generateMat function in matlab can then use
	 * the xml to make a mat file
	 */
	
	var xml = "<object>";
	
	xml += "<jglData>";
	xml += genXML(jglData);
	xml += "</jglData>";
	
	xml += "<task>";
	xml += genXML(task);
	xml += "</task>";
	
	xml += "<myscreen>";
	xml += genXML(myscreen);
	xml += "</myscreen>";
	
	// Get all stimuli registered using initStimulus.
	for (var i=0;i<myscreen.stimulusNames.length;i++) {
		xml += "<" + myscreen.stimulusNames[i] + ">";
		xml += eval("genXML(" + myscreen.stimulusNames[i] + ");");
		xml += "</" + myscreen.stimulusNames[i] + ">";
	}
	
	xml += "</object>";
	
	// Save data.
	myscreen.psiTurk.recordUnstructuredData("experimentXML", xml);
	myscreen.psiTurk.saveData({
		success: function() {
			myscreen.psiTurk.completeHIT();
		},
		error: function() {alert("error!!!");}
	});
	
}/**
 * Basic Set Data Structure.
 * @constructor
 */

function Set() {
	var data = [];
	var count = 0;
	
	function find(val) {
		for (var i=0;i<data.length;i++) {
			if (data[i] === val) {
				return i;
			}
		}
		return -1;
	}
	
	/**
	 * Function to see if the set contains the given val.
	 * @param val the value to check
	 * @returns {Boolean} true if contains, false if not
	 */
	this.contains = function(val) {
		return find(val) > -1;
	}
	
	/**
	 * Function to insert a value into the set.
	 * @param val the value to insert
	 * @returns {Boolean} true if succeeded, false if not
	 */
	this.insert = function(val) {
		if (! this.contains(val)) {
			data[count++] = val;
			return true;
		}
		return false;
	}
	
	/**
	 * Function to remove a value from the set.
	 * @param val the value to remove
	 * @returns {Boolean} true if removed, false if not found
	 */
	this.remove = function(val) {
		if (this.contains(val)) {
			data.splice(find(val), 1);
			count--;
			return true;
		}
		return false;
	}
	
	/**
	 * Function to grab the contents of the set.
	 * @returns {Array} an array with all the values contained by the set
	 */
	this.toArray = function() {
		var tempArray = new Array(data.length);
		
		for (var i=0;i<tempArray.length;i++) {
			tempArray[i] = data[i];
		}
		
		return tempArray;
	}
}/**
 * Things that need to be at the beginning of the concatenated file.
 * This module contains mostly matlab standard library functions.
 * This includes functions to do basic array operations
 * @author Tuvia Lerea
 * @module stdlib
 */

//$.getScript("/scripts/jgllib.js");

/**
 * Function to make all elements of an array uppercase.
 * @returns {Array} the uppercase array
 */
function upper(array) {
	var tempArray = [];
	for (var i = 0;i<array.length;i++) {
		tempArray.push(array[i].toUpperCase());
	}
	return tempArray;
}

/**
 * Function to grab all properties of the given object.
 * @param {Object} object the object to get the fields from
 * @returns {Array} the array of field names
 */
function fields(object) {
	var tempArray = [];
	var i = 0;
	for (var field in object) {
		if (object.hasOwnProperty(field)) {
			tempArray[i++] = field;
		}
	}
	return tempArray;
}

/**
 * Function to make array of zeros of given length.
 * @param {Number} length the length of the array to make
 * @returns {Array} the zero array
 */
function zeros(length) {
	var tempArray = new Array(length);
	for (var i=0;i<tempArray.length;i++) {
		tempArray[i] = 0;
	}
	return tempArray;
}

/**
 * Function to make array of ones of given length.
 * @param {Number} length the length of the array to make.
 * @returns {Array} the ones array
 */
function ones(length) {
	var tempArray = new Array(length);
	for (var i=0;i<length;i++) {
		tempArray[i] = 1;
	}
	return tempArray;
}

/**
 * Function to pad the end of an array with the given value.
 * @param {Array} array the array to pad
 * @param {Number} endLength the final length the array should be
 * @param {Any} padVal the value to pad with
 * @returns {Array} the padded array
 */
function arrayPad(array, endLength, padVal) {
	while (array.length < endLength) {
		array.push(padVal);
	}
	return array;
}

/**
 * Function to make array of given length filled with the given value.
 * @param {Any} value the value to fill the array with
 * @param {Number} length the length the array should be
 * @returns {Array} the array that is made
 */
function fillArray(value, length) {
	var tempArray = new Array(length);
	for (var i=0;i<length;i++) {
		tempArray[i] = value;
	}
	return tempArray;
}

/**
 * Function to get the sum of an array
 * @param {Array} array the array to sum
 * @returns {Number} the sum of the array
 */
function sum(array) {
	var sum = 0;
	for (var i=0;i<array.length;i++) {
		sum += array[i];
	}
	return sum;
}

/**
 * Function to make cumulative sum array.
 * @param {Array} array the array to generate the cumulative sum from.
 * @returns {Array} the cumulative sum array
 */
function cumsum(array) {
	if (array.length == 0) {
		return [];
	}
	var sum = array[0];
	for (var i=0;i<array.length;i++) {
		sum += array[i];
		array[i] = sum;
	}
	return array;
}

/**
 * Function to determine if an array is empty
 * @param {Array} array the array
 * @returns {Boolean} true if array.length == 0 or given array is undefined
 */
function isEmpty(array) {
	if (array === undefined) {
		return true;
	}
	
	if (array === null) {
		return true;
	}
	if ($.isArray(array)) {
		return array.length == 0;
	}
	if (array === Infinity || array === NaN) {
		return true;
	}
	console.log("isEmpty: used with non-array");
	return false;
}

/**
 * Function to determine if there are any non-zero values in the array.
 * @param {Array} array the array to check
 * @returns {Boolean} true if there is at least one non-zero value in array
 */
function any(array) {
	for (var i =0; i< array.length;i++) {
		if (array[i] != 0) {
			return true;
		}
	}
	return false;
}

/**
 * Function to determine the number of elements in the given array
 * @param {Array} array the array to count from
 * @returns {Number} number of defined elements in the given array
 */
function numel(array) {
	var count = 0;
	for (var i=0;i<array.length;i++) {
		if (array[i] != undefined) {
			count++;
		}
	}
	return count;
}

/**
 * Function to determine where in the given array is the given string.
 * @param {String} string the string to search for. 
 * @param {Array} array the array to search through
 * @returns {Array} a logical array, 0 means the that slot in the array was not the string,
 * 1 means that slot was the string.
 */
function strcmp(string, array) {
	var tempArray = zeros(array.length);
	for (var i=0;i<array.length;i++) {
		if (string.localeCompare(array[i]) == 0) {
			tempArray[i] = 1;
		}
	}
	return tempArray;
}

/**
 * Function to calculate the element wise difference of an array.
 * @param {Array} array the array to calculate the diff from
 * @returns {Array} the diff array where diff[0] == array[1] - array[0]
 */
function diff(array) {
	var tempArray = new Array(array.length - 1);
	for (var i = 1;i<array.length;i++) {
		tempArray[i-1] = array[i] - array[i-1];
	}
	return tempArray;
}

/**
 * Function to index an array by another array.
 * @param {Array|Number} master the array to index.
 * @param {Array} slave the index array
 * @param {Boolean} logical if true, the slave is treated as a logical array, if false then not.
 * @returns {Array} the array generated by this indexing
 */
function index(master, slave, logical) {
	var tempArray = [];

	if (! $.isArray(master)) {
		for (var i=0;i<slave.length;i++) {
			if (slave[i] != 0) {
				throw "index error";
			}
			tempArray.push(master);
		}
	} else {
		if (logical) {
			for (var i=0;i<slave.length;i++) {
				if (slave[i] == 1) {
					tempArray.push(master[i]);
				}
			}
		} else {
			for (var i =0;i<slave.length;i++) {
				tempArray.push(master[slave[i]]);
			}
		}
	}
	return tempArray;
}

/**
 * Function to determine if two arrays are equal. 
 * @param {Array} first the first array
 * @param {Array} second the second array
 * @returns {Boolean} the two arrays are equal if they have the same length, and elements
 */
function isEqual(first, second) {
	if (first.length != second.length) {
		return false;
	}
	for (var i =0;i<first.length;i++) {
		if (first[i] != second[i]) {
			return false;
		}
	}
	return true;
}

/**
 * Function for returning the indices of non-zero values of an array 
 * @param {Array} array the array to search through
 * @returns {Array} an array of indices of all non-zero elements in array
 */
function find(array) {
	var tempArray = [];
	for (var i =0;i<array.length;i++) {
		if (array[i] != 0) {
			tempArray.push(i);
		}
	}
	return tempArray;
}

/**
 * Function for generating a unique array as well as indexing array. 
 * If only a unique array is desired use $.unique(A).
 * @param {Array} A the array to work with
 * @returns {Array} [C IA IC] C is the unique array and is sorted.
 * IA is such that C = index(A, IA, false)
 * IC is such that A = index(C, IC, false)
 */
function unique(A) {
	var set = new Set();
	var C = [];
	var IA = [];
	var IC = [];
	for (var i=0;i<A.length;i++) {
		if (! set.contains(A[i])) {
			set.insert(A[i]);
		}
	}
	C = set.toArray();
	C = C.sort();
	for (var i = 0;i<C.length;i++) {
		IA.push(A.indexOf(C[i]));
	}
	for (var i =0;i<A.length;i++) {
		IC.push(C.indexOf(A[i]));
	}

	return [C, IA, IC];
}

/**
 * Function for generating an array of all of a given field from an array of objects.
 * @param {Array} array the array of objects
 * @param {String} field the field name. 
 * @returns {Array} an array such that the zero'th index == array[0].field
 */
function gatherFields(array, field) {
	var tempArray = new Array(array.length);
	for (var i=0;i<tempArray.length;i++) {
		tempArray[i] = eval("array[i]." + field);
	}
	return tempArray;
}

/**
 * Function for determining where array[i] == val
 * @param {Array} array the array to search through
 * @param {Any} val the value to search for
 * @returns {Array} a logical array 1 where array[i] == val, 0 where not.
 */
function equals(array, val) {
	var temp = zeros(array.length);
	for (var i = 0;i< array.length;i++) {
		if (array[i] === val) {
			temp[i] = 1;
		}
	}
	return temp;
}

/**
 * Function to generate an array of NaNs.
 * @param {Number} length the length of the array
 * @returns {Array} and array of NaNs
 */
function nan(length) {
	return fillArray(NaN, length);
}

/**
 * Function to element wise add two arrays or an array with a scalar. 
 * Both first and second can be scalars or arrays.
 * @param {Array|Number} first the first item.
 * @param {Array|Number} second the second item.
 * @param {Array} index the indexing array defaults to ones
 * @returns {Array} the added array
 */
function add(first, second, index) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array add, dimensions don't agree";
		}
		if (index === undefined) {
			index = ones(first.length);
		}
		return jQuery.map(first, function(n, i) {
			if (index[i]) {
				return n + second[i];
			} else {
				return n;
			}
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		if (index === undefined) {
			index = ones(first.length);
		}
		return jQuery.map(first, function(n, i) {
			if (index[i]) {
				return n + second;
			} else {
				return n;
			}
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		if (index === undefined) {
			index = ones(second.length);
		}
		return jQuery.map(second, function(n, i) {
			if (index[i]) {
				return n + first;
			} else {
				return n;
			}		});
	} else {
		return [first + second];
	}
}

/**
 * Function to selement wise subtract two arrays or an array with a scalar.
 * Both first and second can be scalars or arrays.
 * @param {Array|Number} first the first item.
 * @param {Array|Number} second the second item.
 * @param {Array} index indexing array, defaults to ones
 * @returns {Array} the subtracted array where if one is an array and one is not,
 *  the scalar is always subtracted from each element of the array.
 */
function subtract(first, second, index) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array add, dimensions don't agree";
		}
		if (index === undefined) {
			index = ones(first.length);
		}
		return jQuery.map(first, function(n, i) {
			if (index[i]) {
				return n - second[i];
			} else {
				return n;
			}
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		if (index === undefined) {
			index = ones(first.length);
		}
		return jQuery.map(first, function(n, i) {
			if (index[i]) {
				return n - second;
			} else {
				return n;
			}
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		if (index === undefined) {
			index = ones(second.length);
		}
		return jQuery.map(second, function(n, i) {
			if (index[i]) {
				return n - first;
			} else {
				return n;
			}		});
	} else {
		return [first - second];
	}
}

/**
 * Function to element wise multiple any combination of two arrays and / or scalars.
 * @param {Array|Number} first the first item.
 * @param {Array|Number} second the second item.
 * @returns {Array} the multiplied array.
 */
function multiply(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array multiply, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n * second[i];
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n * second;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return n * first;
		});
	} else {
		return [first * second];
	}
}

function exp(first,second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array multiply, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return Math.pow(n, second[i]);
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return Math.pow(n, second);
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return Math.pow(n, first);
		});
	} else {
		return Math.pow(first,second);
	}

}

/**
 * Function to element wise to divide any combination of two arrays / scalars
 * @param {Array|Number} first the first item.
 * @param {Array|Number} second the second item.
 * @returns {Array} the divided array. if a scalar is involved, each element of the array is divided by the scalar. 
 */
function divide(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array divide, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n / second[i];
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n / second;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return n / first;
		});
	} else {
		return [first / second];
	}
}

/**
 * Function to element wise to divide any combination of two arrays / scalars
 * @param {Array|Number} first the first item.
 * @param {Array|Number} second the second item.
 * @returns {Array} the divided array. if a scalar is involved, each element of the array is divided by the scalar. 
 */
function mod(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array divide, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n % second[i];
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n % second;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return n % first;
		});
	} else {
		return [first % second];
	}
}

/**
 * Function to floor a scalar or array.
 * @param {Array|Number} val the value to floor, can be an array or scalar
 * @returns {Number|Array} if a number was given, the floor is returned.
 * if an array was given, an array of floored values is returned. 
 */
function floor(val) {
	if ($.isArray(val)) {
		return jQuery.map(val, function(n, i) {
			return Math.floor(n);
		});
	} else {
		return Math.floor(val);
	}
}

/**
 * Function to determine if the given val is Infinite. If an array is given it works element wise through the array.
 * @param {Array|Number} val the value to check. can be a Number or Array.
 * @returns {Number|Array} Number if Number is given, returns 1 for infinite, 0 for not. If array was given, Array is returned
 * with element wise bits checking for infinity.
 */
function isinf(val) {
	if ($.isArray(val)) {
		return jQuery.map(val, function(n,i) {
			if (isFinite(n)) {
				return 0;
			}
			return 1;
		});
	} else {
		return isFinite(val) ? 0 : 1;
	}
}

/**
 * Function to determine if the given val is NaN If an array is given it works element wise through the array.
 * @param {Array|Number} val the value to check. can be a Number or an Array.
 * @returns {Number|Array} Number if Number is given, Array if Array is given. 1 means NaN, 0 means not.
 */
function isnan(val) {
	if ($.isArray(val)) {
		return jQuery.map(val, function(n,i) {
			return isNaN(n) ? 1 : 0;
		});
	}
	return isNaN(val) ? 1 : 0;
}

/**
 * Function to calculate an element bit wise or. works with logical inputs. Inputs can be Arrays or Numbers.
 * @param {Array|Number} first the first input
 * @param {Array|Number} second the second input
 * @returns {Array} returns an array of element bit wise ors of the inputs. 
 */
function or(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array or, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n | second[i];
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n | second;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return n | first;
		});
	} else {
		return [first | second];
	}
}

/**
 * Function to calculate an element bit wise and. works with logical inputs. Inputs can be Arrays or Numbers.
 * @param {Array|Number} first the first input
 * @param {Array|Number} second the second input
 * @returns {Array} returns an array of element bit wise ands of the inputs. 
 */
function and(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array or, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n & second[i];
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n & second;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return n & first;
		});
	} else {
		return [first & second];
	}
}

/**
 * Function to calculate an element bit wise xor. works with logical inputs. Inputs can be Arrays or Numbers.
 * @param {Array|Number} first the first input
 * @param {Array|Number} second the second input
 * @returns {Array} returns an array of element bit wise xors of the inputs. 
 */
function xor(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array or, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return !(n & second[i]) & (n | second[i]);
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return !(n & second[i]) & (n | second[i]);
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return !(n & second[i]) & (n | second[i]);
		});
	} else {
		return [!(n & second[i]) & (n | second[i])];
	}
}

/**
 * Function to generate a logical array from element wise checking greater than between first and second.
 * @param {Array|Number} first the first item. can be a Number or Array
 * @param {Array|Number} second the second item. can be a Number or Array
 * @returns {Array} returns a logical array. where 1 means first > second for each element of first/second
 */
function greaterThan(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array or, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n > second[i] ? 1 : 0;
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n > second ? 1 : 0;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return first > n ? 1 : 0;
		});
	} else {
		return first > second ? [1] : [0];
	}
}

/**
 * Function to generate a logical array from element wise checking less than between first and second.
 * @param {Array|Number} first the first item. can be a Number or Array
 * @param {Array|Number} second the second item. can be a Number or Array
 * @returns {Array} returns a logical array. where 1 means first < second for each element of first/second
 */
function lessThan(first, second) {
	if ($.isArray(first) && $.isArray(second)) {
		if (first.length != second.length) {
			throw "array or, dimensions don't agree";
		}
		return jQuery.map(first, function(n, i) {
			return n < second[i] ? 1 : 0;
		});
	} else if ($.isArray(first) && ! $.isArray(second)) {
		return jQuery.map(first, function(n, i) {
			return n < second ? 1 : 0;
		});
	} else if (! $.isArray(first) && $.isArray(second)) {
		return jQuery.map(second, function(n, i) {
			return first < n ? 1 : 0;
		});
	} else {
		return first < second ? [1] : [0];
	}
}

/**
 * Determines the mean of the given array.
 * @param {Array} array the given array
 * @returns {Number} the mean value
 */
function mean(array) {
	if (array.length == 0) {
		return 0;
	}
	var sum = 0, count = 0;
	for (var i =0 ;i<array.length;i++) {
		sum += array[i];
		count++;
	}
	return sum / count;
	
}

/**
 * Function for generating a random integer.
 * @param {Object} task the task object from which to grab random numbers
 * @param {Number} low the low bound. inclusive
 * @param {Number} high the high bound, exclusive
 * @returns {Number} random integer between low and high
 */
function randInt(task, low, high) {
	return Math.round(rand(task) * (high - low - 1)) + low;
}

/**
 * Generate a random permutation from 0 - length
 * @param {Object} task the task object to grab random numbers from
 * @param {Number} length the length of the permutation, excludes length
 * @returns {Array} a random permutation from 0-length
 */
function randPerm(task, length) {
	var array = jglMakeArray(0, 1, length);
	var randy;
	for (var i = 0;i<array.length - 1;i++) {
		randy = randInt(task, i, array.length);
		var temp = array[randy];
		array[randy] = array[i];
		array[i] = temp;
	}
	return array;
}

/**
 * Generates size of given value
 * @param {Array|Number} val the value to determine size of
 * @returns {Number} the length of val if val is an array, 1 if not. 0 if null
 */
function size(val) {
	if ($.isArray(val)) {
		return val.length;
	} else if (val != undefined && val != null) {
		return 1;
	} else {
		return 0;
	}
}

/**
 * Determines the product of the given array
 * @param {Array} array the array to determine the product of
 * @returns {Number} the product
 */
function prod(array) {
	if ($.isArray(array)) {
		var product = 1;
		for (var i = 0;i<array.length;i++) {
			product *= array[i];
		}
		return product;
	}
	return 0;
}

/**
 * Generates and returns the not of the given value
 * @param {Array|Number} array the given value
 * @returns {Number|Array} for every element returns 0 if element, 1 otherwise 
 */
function not(array) {
	if (! $.isArray(array)) {
		return array ? 1 : 0;
	} else {
		var temp = new Array(array.length);
		for (var i = 0;i < array.length; i++) {
			temp[i] = array[i] ? 0 : 1;
		}
		return temp;
	}
}

/**
 * Generates a sin array of the given array.
 * @param {Array} array the array to sin
 * @returns {Array} an element wise sin array of the given array
 */
function sin(array) {
	return jQuery.map(array, function(n,i) {
		return Math.sin(n);
	});
}

/**
 * Generates a cos array of the given array.
 * @param {Array} array the array to cos
 * @returns {Array} an element wise cos array of the given array
 */
function cos(array) {
	return jQuery.map(array, function(n,i) {
		return Math.cos(n);
	});
}

/**
 * Determine if a value is numeric. 
 * @param {Array|Number} val the value to check
 * @returns {Boolean} true if single element is numeric or if all elements in
 * an array or numeric
 */
function isNumeric(val) {
	if ($.isArray(val)) {
		for (var i=0;i<val.length;i++) {
			if (! $.isNumeric(val[i])) {
				return false;
			}
		}
		return true;
	}else {
		return $.isNumeric(val);
	}
}

/**
 * Function to change only certain elements of an array.
 * @param {Array} array the array to change (original values)
 * @param {Array} values an array of new values
 * @param {Array} indexer a logical array that indicates which values in array to change
 * @returns {Array} The new changed array
 */
function change(array, values, indexer) {
	var places = find(indexer);
	if (places.length != values.length) {
		throw "change: array lengths dont match";
	}
	
	for (var i =0 ;i<places.length;i++) {
		array[places[i]] = values[i];
	}
	
	return array;
}

/**
 * Function that is in charge of ticking the screen.
 * This is the function that is called every frame, i.e. every 17 miliseconds.
 * Here, the screenUpdate callback is called, and the screen is flushed, assuming
 * myscreen.flushMode is > 0. Additional, it keeps track of dropped frames. Now,
 * since JavaScript does not have as much control as mgl does, a dropped frame is 
 * when it takes too long for tickScreen to get called again, i.e. the interval is
 * not running fast enough. It is entirely disconnected from the actual drawing on the screen.
 * @memberof module:jglTask
 */
function tickScreen() {
	
	for (var i=0;i<task.length;i++) {
		var temp = task[i][tnum].callback.screenUpdate(task[i][tnum], myscreen);
		task[i][tnum] = temp[0];
		myscreen = temp[1];
	}
	
	//TODO: skipped a bunch of volume stuff
	switch (myscreen.flushMode) {
	case 0:
		jglFlush();
		break;
	case 1:
		jglFlush();
		myscreen.flushMode = -1;
		break;
	case 2:
		jglNoFlushWait();
		break;
	case 3:
		jglFlushAndWait();
		break;
	default:
		myscreen.fliptime = Infinity;
	}


	if (myscreen.checkForDroppedFrames && myscreen.flushMode >= 0) {
		var fliptime = jglGetSecs();
		

		if ((fliptime - myscreen.fliptime) > myscreen.dropThreshold*myscreen.frametime) {
			myscreen.dropcount++;
		}
		if (myscreen.fliptime != Infinity) {
			myscreen.totalflip += (fliptime - myscreen.fliptime);
			myscreen.totaltick++;
		}
		myscreen.fliptime = fliptime;
	}
	myscreen.tick++;


	if (jglGetKeys().indexOf('esc') > -1) {
		myscreen.userHitEsc = 1;
		finishExp();
	}
	

}/**
 * Function to write to a trace.
 * @param {Number} data for response positive values are keyCodes, negative are mouse presses
 * @param {Number} tracenum the trace to write to
 * @param {Number} force NOT USED defaults to 0
 * @param {Number} eventTime the time the event occured defaults to the current time
 * @memberof module:jglTask
 */
function writeTrace(data, tracenum, force, eventTime) {
	if (force === undefined) {
		force = 0;
	}
	if (eventTime === undefined) {
		eventTime = jglGetSecs();
	}
	
	if ((tracenum > 0)) {
		myscreen.events.tracenum[myscreen.events.n] = tracenum;
		myscreen.events.data[myscreen.events.n] = data;
		myscreen.events.ticknum[myscreen.events.n] = myscreen.tick;
		myscreen.events.time[myscreen.events.n] = eventTime;
		myscreen.events.force[myscreen.events.n] = force;
		myscreen.events.n++;
	}
	
 }