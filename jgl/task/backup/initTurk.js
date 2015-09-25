/**
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
}