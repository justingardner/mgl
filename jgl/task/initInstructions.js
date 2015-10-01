/**
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
}