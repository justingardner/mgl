/**
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
}