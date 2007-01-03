============================================================================
task: A set of functions that handle basic structures of experiments
============================================================================

todo:
explain writeTrace
explain blockLen and trialLen
explain multiple phase tasks
explain how save works
explain where variables are stored
deal with subject responses
-have each task decide on which trace to use from myscreen
-automatic saving of trial and segment info
-gamma tables for monitors downstairs
-use read/writeDigPort to control tracker
-send syncing information to eye tracker

=== A quick overview ===

The structure for these experiments involves three main variables:

myscreen: Hold information about the screen parameters like resolution, etc.
task: Holds info about the block/trial/segment structure of the experiment
stimulus: Holds strucutres associated with the stimulus.

To create and run an experiment, your program will do the following:

* Initialize the screen using initScreen
* Create callback functions that will run at various times in the experiment like at the beginning of a trial or when the subject responds with a keypress or before each display refresh.
* Set up the task variable which holds your task structure and initialize the task with initTask
* Initialize the stimulus (e.g. create bitmaps or setup parameters)
* Create a display loop which calls updateTask to update your task,
    and tickScreen to refresh the display.

A simple example experiment is in this directory can be run:

 >> testExperiment

The code for this experiment serves as the basic help information
for how to use this code. This file contains some extra details.

=== How to setup experimental parameters ===

For your experiment you can choose what parameters you have and what values they can take on. You do this by adding parameters (of your choosing) into the parameter part of a task variable:

 task.parameter.myParameter1 = [1 3 5 10];
 task.parameter.myParameter2 = [-1 1];

You can add any number of parameters that you want. updateTask will chose a value on each trial and put those values into the thistrial structure:

 task.thistrial.myParameter1
 task.thistrial.myParameter2

would equal the setting on that particular trial. In each block every combination of parameters will be presented. You can randomize the order of the parameters by setting:

 task.random = 1;

=== What if I have a group of parameters ===

Then you could do something like

 task.parameter.groupNum = [1 2 3];
 task.group{1}.myParamater1 = 1;
 task.group{1}.myParamater2 = -1;
 task.group{2}.myParamater1 = 1;
 task.group{2}.myParamater2 = -1;
 task.group{3}.myParamater1 = 0;
 task.group{3}.myParamater2 = 4;

On each trial, you get the parameters by doing task.thistrial.thisgroup = task.group{task.thistrial.groupNum};

=== What if I have parameters that are not single numbers ===

Again, do something like the above (1.3)

 task.parameter.stringNum = [1 2 3];
 task.strings = {'string1','string2','string3'}

and get the appropriate string on each trial by doing:

 task.thistrial.thisstring = task.strings{task.thistrial.stringNum};

=== How to setup segment times ===
Each trial can be divided into multiple segments where different things happen, like for instance you might have a stimulus segment and response segment that you want to have occur for 1.3 and 2.4 seconds respectively:

 task.seglen = [1.3 2.4];

At the beginning of each segment the callback startSegment will be called and you can find out which segment is being run by looking at:

 task.thistrial.thisseg

=== How to randomize the length of segments ===

If you want to randomize the length of segments over a uniform distribution, like for instance when you want the first segment to be exactly 1.3 seconds and the second segments to be randomized over the interval 2-2.5 seconds:

 task.segmin = [1.3 2];
 task.segmax = [1.3 2.5];

In this case, do not specify task.seglen.

If you want the second interval to be randomized over the interval 2-2.5 seconds in intervals of 0.1 seconds (i.e. you want it to be  either 2,2.1,2.2,2.3,2.4 or 2.5:

 task.segmin = [1.3 2];
 task.segmax = [1.3 2.5];
 task.segquant = [0 0.1];

=== Keeping time in seconds, volumes or refreshes ===

Trial segments can keep time in either seconds (default), volumes or monitor refreshes.

To change timing to use volumes:

 task.timeInVols = 1;

To change timing to use monitor refreshes:

 task.timeInTicks = 1;

With timeInVols or timeInTicks, your segment times should now be integer values that specify time in Vols or monitor refreshes (e.g.):

 task.seglen = [3 2];

Note, that the defualt (time in seconds) adjusts for segment overruns that might occur when you drop monitor frames, but the  timeInTicks will not and is therefore usually less accurate.

=== How do I use callbacks ===

Callbacks are the way that you control what happens on different portions of the trial and what gets drawn to the screen. The most important callback is the drawStimulusCallback to define one, you define a function:

 function [task myscreen] = drawStimulusCallback(task, myscreen)
 % do your draw functions in here.

The other mandatory callback is the one that is called at the beginning of each segment:

 function [task myscreen] = startSegmentCallback(task, myscreen)

Then you need to set this as your drawStimulus callback when you call initTask:

 task = initTask(task,myscreen,@startSegmentCallback,@drawStimulusCallback);

The other callbacks that are available (optional) are explained in the help for initTask. You can omit any callback by either not specifying it as an argument to initTask or setting it to [].


