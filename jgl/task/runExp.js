/*
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
}