/**
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
}