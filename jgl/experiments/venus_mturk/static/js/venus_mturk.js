// What do you need for your task? 
// 1. Program trial randomization

$(document).ready(function() {
	venus_mTurk();
});

function venus_mTurk() {

	// Set these params before running the task
	intensities = [0.01, 0.1, 0.3];  // Grating contrast intensities
	nIntensities = intensities.length; 
	nTrialsPerIntensity = 20; 		 // Number of times each contrast will be shown. Needs to be even number. 

	// Initialize screen object
	// Stores info about screen dimensions 
	// screen ppi and many other variables
	window.myscreen = initScreen();
	// --------
	// Temporary for debugging only DELETE
	myscreen.pow = 2.2;

	// List of instruction pages. These pages are not intended for 
	// collecting user data such as demographics, but  
	// These are presented in listed order
	// **Note:** There are two more pages - not listes here - that will load up before 
	// instructions comes up. First one is "ad.html" followed by "consent'html" 
	// which are both located under the folder "templates". Please edit them to match your experiment.  
	var instructionPages = [ // add as a list as many pages as you like
	"instructions/instruct-1.html",
	"instructions/instruct-2.html",
	"instructions/instruct-ready.html"
	];

	// Task is two dimensional. 1st dimension is task number and second is phase number
	// First, declare task as one dimensional array
	window.task = []; 
	// Then declare next dimension, which is phase of the task, 
    task[0] = []; // converts task into 2D array
	// and make that 2D array to be an object container
	// Second dimension is the phase of the task. For example, instruction pages can be one phase, collecting 
	// demographics another phase and presenting stimulus another phase. In essence, one task can 
	// contain a complete experiment. You can setup another task to follow the first task, if necessary. 
	// Essentially, you would want another task if different experiments are run one after another. Otherwise, 
	// jgl can absorb two different conditions within one task variable. For example, task[0][2] can be 
	// initialized with its own set of callback functions and task[0][5] can be set to run with callback 
	// functions that will serve another experimental condition. To understand callbacks, see later comments
	task[0][0] = {}; 

	// First phase of the task is to show instructions
	task[0][0] = initInstructions(instructionPages);  // WHAT DOES THIS DO actually? What kind of object does it create? 

	// Second phase of the task is to do Gamma calibration of the display. It has controls on it and we need to get back
	// the Gamma value. So it is a survey object. 
	task[0][1] = initSurvey(); // Creates survey object 
	task[0][1].html = "calibrate.html";

/**
	// Third phase is to collect demographics, which is, again, survey. 
	task[0][2] = initSurvey(); 
	task[0][2].html = 'surveyDemo.html';
	// Forth phase to learn about the monitor size and screen ratios using again a survey
	task[0][3] = initSurvey(); 
	task[0][3].html = 'surveyScreen.html';
*/
	expPhase = 2 // delete this during expt and use 4 
	// Fifth phase is the psychophysical task
	task[0][expPhase] = {};
	task[0][expPhase].segmin = [1, 0.5, 4]; 
	task[0][expPhase].segmax = [2, 0.5, 4];
    task[0][expPhase].segnames = ['ITI', 'stimulus', 'response'];  // ITI - inter-stimulus interval, stimulus - stimulus presentation interval, response - response collected
    task[0][expPhase].getResponse = [0, 1, 1];  // Collect responses during stimulus presentation and during response interval
    task[0][expPhase].usingScreen = 1;
    task[0][expPhase].html = "canvas.html"
     // Parameters for running the task
     // instead of randVar in mgl, using parameter to store 
     // manual randomization params
    task[0][expPhase].numTrials = nIntensities * nTrialsPerIntensity;
    task[0][expPhase].parameter = {};
    // Each intensity repeated nTrialsPerIntensity times
    task[0][expPhase].parameter.allTrials = jglRepmat(intensities, nTrialsPerIntensity); 
    //task[0][expPhase].parameter.inAllTrials = jglRepmat(jglMakeArray(0,1,nIntensities), nTrialsPerIntensity); 
    // Each contrast intensity needs to be presented to the left and right visual fields. -1: left, +1: right
    leftVfCode = ones(nIntensities);
    leftNRightVfCode = leftVfCode.concat(multiply(ones(nIntensities), -1));
    // Ensure that left and right visual field are presented once for each contrast intensity
    task[0][expPhase].parameter.visualField = jglRepmat(leftNRightVfCode, nTrialsPerIntensity/2);
    // Randomize stimulus presentation order
    task[0][expPhase].parameter.rndTrial = shuffle(jglMakeArray(0, 1, nTrialsPerIntensity * nIntensities));

    // Register callback functions that will be taking care of stimulus presentation
    task[0][expPhase] = initTask(task[0][expPhase], startSegmentCallback, updateScreenCallback);

	// TODO: Write exactly what this does 
	// * WHat does stimulus object initialize to
	// * Say that you can have have more than one 'stimulus' variable. E.g., another one can be 'face'
	// * Say that 'stimulus' will saved
	window.stimulus = {};
	initStimulus('stimulus');
    stimulus.leftVFCoord = [-6, 0]; //x and y stimulus position in the left visual field 
 	stimulus.rightVFCoord = [6, 0]; // right visual field stimulus coordinates    

	// This initializes PsiTurk object by calling PsiTurk() function and passing it 
	// required variables which are: uniqueID, condition, adServerloc, and counterbalance 
	// This function also passes list of all html files that will be shown by PsiTurk during 
	// the experiment, including all the instruction, demographics and task html files. 
	// This function also initializes jglData object which holds all mouse and keyboard responses 
	// for surveys and tasks organized by task, phase, block, segment number and time
	//debugger
	initTurk(); 


	// The above task needs to be initialized by telling it which callback functions 
	// Will be taking care of stimulus presentation

	// We now need to tell jgl to start a loop that will go through all the phases of the task
	startPhase(task[0]); 
}

var updateScreenCallback = function(task, myscreen) {
	jglClearScreen(jglGammaCorr(128));

	// Inter-trial interval
	if (task.taskID == expPhase+1 && task.thistrial.thisseg == 0) {
		jglFixationCross(1, 0.1, '#ccaaff', [0,0]); 
		jglTextDraw('segment 1 ', 2.5,-2.75);
	}
	
	// Stimulus presentation segment
	if (task.taskID == expPhase+1 && task.thistrial.thisseg == 1) {
		jglFixationCross(1, 0.1, jglGammaCorrHex(0), [0,0]); 
		jglTextDraw('segment 2 ', 2.5,-2.75);
		// Stimulus intensity to be presented on current trial. This uses random order
		// stored in rndTrial
		var stimIntensity = task.parameter.allTrials[task.parameter.rndTrial[task.trialnum]];
		var contrastGammaCorr = jglGammaCorrHex(round(stimIntensity*255)); 
		var visualField = task.parameter.visualField[task.parameter.rndTrial[task.trialnum]];
		
		grating = jglMakeGrating(128,128,1,1,1,1); 


		//debugger
		// Add code to store presentedStim and presentedVF to variable "stimulus"
		// This will be saved to be later used for the data analysis

		// If left visual field
		if (visualField == -1) { 
			// How to call left or right visual field
			jglFillRect([stimulus.leftVFCoord[0]], [stimulus.leftVFCoord[1]], [2, 1], contrastGammaCorr); 
			//debugger
			//jglFillRect([-3], [0], [2, 1], '#ffffff'); 
			
			//jglFillRect(stimulus.leftVFCoord[0], stimulus.leftVFCoord[1], [2, 1], jglGammaCorrHex(255)); 
		} else {
			// If right visual field 
			//debugger
			jglFillRect([stimulus.rightVFCoord[0]], [stimulus.rightVFCoord[1]], [2, 1], contrastGammaCorr); 
		}

	}
	// Feedback segment
	if (task.taskID == expPhase+1 && task.thistrial.thisseg == 2) {
		jglFixationCross(1, 0.1, jglGammaCorrHex(0), [0,0]);
		jglTextDraw('segment 3', 2.5,-2.75);
 	}

	//window.stimulus = updateDots(window.stimulus, task, myscreen);
	jglTextSet('Arial',1,'#ff0000',0,0);
	jglTextDraw('trial: ' + task.trialnum,-6.5,-2.75);
	//jglFixationCross(1,0.1,200,[0,0]);
	return [task, myscreen];
}

var startSegmentCallback = function(task, myscreen) {
	// Is this the first segment (ITI)
	// debugger
	if (task.thistrial.thisseg == 0) {

	}
	return [task, myscreen]; 
}


// * @param {Number} width the width of the cross
//  * @param {Number} lineWidth the width of the lines of the cross
//  * @param {String} color the color in hex format
//  * @param {Array} origin the center point in [x,y]


// initTask(task, startSegmentCallback,
// 		screenUpdateCallback, trialResponseCallback,
// 		startTrialCallback, endTrialCallback, 
// 		startBlockCallback, randCallback)




