============================================================================
task: A set of functions that handle basic structures of experiments
============================================================================

****************************************************************************
How to get started
****************************************************************************
1.1 A quick overview
1.2 How to setup experimental parameters
1.3 What if I have a group of parameters
1.4 What if I have parameters that are not single numbers
============================================================================
1.1 A quick overview
============================================================================
The structure for these experiments involves three main variables:

myscreen: Hold information about the screen parameters like resolution, etc.
task: Holds information about the block/trial/segment structure of the experiment
stimulus: Holds strucutres associated with the stimulus.

To create and run an experiment, your program will do the following:

1) Initialize the screen using initScreen
2) Create callback functions that will be called at various times in the experiment
   like at the beginning of a trial or when the subject responds with a keypress
   or before each display refresh.
3) Set up the task variable which holds your task structure and initialize the
   task with initTask
4) Initialize the stimulus (e.g. create bitmaps or setup parameters)
5) Create a display loop which calls updateTask to update your task, and tickScreen
   to refresh the display.

A simple example experiment is in this directory can be run:

>> testExperiment

============================================================================
1.2 How to setup experimental parameters
============================================================================

For your experiment you can choose what parameters you have and what values
they can take on. You do this by adding parameters (of your choosing) into
the parameter part of a task variable:

task.parameter.myParameter1 = [1 3 5 10];
task.parameter.myParameter2 = [-1 1];

You can add any number of parameters that you want. updateTask will chose
a value on each trial and put those values into the thistrial structure:

task.thistrial.myParameter

would equal the setting on that particular trial. In each block every combination
of parameters will be presented. You can randomize the order of the parameters by
setting:

task.random = 1;

============================================================================
1.3 What if I have a group of parameters
============================================================================

Then you could do something like

task.parameter.groupNum = [1 2 3];
task.group{1}.myParamater1 = 1;
task.group{1}.myParamater2 = -1;
task.group{2}.myParamater1 = 1;
task.group{2}.myParamater2 = -1;
task.group{3}.myParamater1 = 0;
task.group{3}.myParamater2 = 4;

On each trial, you get the parameters by doing
task.thistrial.thisgroup = task.group{task.thistrial.groupNum};

============================================================================
1.4 What if I have parameters that are not single numbers
============================================================================

Again, do something like the above (1.3)

task.parameter.stringNum = [1 2 3];
task.strings = {'string1','string2','string3'}

and get the appropriate string on each trial by doing:

task.thistrial.thisstring = task.strings{task.thistrial.stringNum};
