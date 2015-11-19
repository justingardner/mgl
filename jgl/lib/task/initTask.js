/**
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
}