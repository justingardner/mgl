% initTask - initializes task for stimuli programs
%
%      usage: [ task myscreen ] = initTask( task, myscreen, startSegmentCallback, ...
%			 screenUpdateCallback, <trialResponseCallback>, ...
%			 <startTrialCallback>, <endTrialCallback>, <startBlockCallback>,...
%                        <randCallback>);
%        $Id$
%         by: justin gardner
%       date: 2006-04-27
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%     inputs: task, myscreen
%  callbacks:
%     -- function handles for callback functions --
%
%    [task myscreen] =
%      startSegmentCallback(task,myscreen)
%    Gets called at the beginning of each trial segment. The
%    variable settings for the trial are available in
%    task.thistrial (Mandatory)
%
%    [task myscreen] = screenUpdateCallback(task,myscreen)
%    Gets called on every display tick. Responsible for drawing the
%    stimulus to the screen for stimuli that are update every frame
%    (Mandatory)
%
%    [task myscreen] = trialResponseCallback(task,myscreen)
%    Gets called if getResponse is set in the trial segment 
%    and the subject hits a response key. 
%
%    [task myscreen] = endTrialCallback(task,myscreen)
%    Gets called at end of trial
%
%    [task myscreen] = startBlockCallback(task,myscreen)
%    Gets called at beginning of block
%
%    block = randCallback(paramaters,block,previousBlock,task);
%    gets called at beginning of block to randomize parameters
%
%    outputs: task
%    purpose: initializes task for stimuli programs - you need to
%    write functions (and provide function handles to them) to
%    handle new tasks that you want to implement.
%
% 
function [task myscreen] = initTask(task, myscreen, startSegmentCallback, ...
    screenUpdateCallback, trialResponseCallback,...
    startTrialCallback, endTrialCallback, startBlockCallback,...
    randCallback);

    if ~any(nargin == [4:10])
        help initTask;
        return
    end

    if nargout ~= 2
        disp(sprintf('(initTask) You must accept the return variables task & myscreen from initTask'));
        help initTask;
    end

    if ~isfield(task,'verbose')
        task.verbose = 1;
    end

    % check for capitalization errors
    knownFieldnames = ...
    {'verbose', ...
    'parameter', ...
    'seglen', ...
    'segmin', ...
    'segmax', ...
    'segquant', ...
    'synchToVol', ...
    'writeTrace', ...
    'getResponse', ...
    'numBlocks', ...
    'numTrials', ...
    'waitForBacktick', ...
    'random', ...
    'timeInTicks', ...
    'timeInVols', ...
    'segmentTrace', ...
    'responseTrace', ...
    'phaseTrace', ...
    'parameterCode', ...
    'private', ...
    'randVars', ...
    'userVars', ...
    'fudgeLastVolume'};

    taskFieldnames = fieldnames(task);
    for i = 1:length(taskFieldnames)
        matches = find(strcmp(upper(taskFieldnames{i}),upper(knownFieldnames)));
        if  matches &	~any(strcmp(taskFieldnames{i},knownFieldnames))
            disp(sprintf('(initTask) task.%s is miscapitalized. Changed to task.%s.', ...
            taskFieldnames{i},knownFieldnames{matches}));
            fieldval = eval(sprintf('task.%s',taskFieldnames{i}));
            task = rmfield(task,taskFieldnames{i});
            eval(sprintf('task.%s = fieldval;',knownFieldnames{matches}));
        elseif isempty(matches)
            disp(sprintf('Unknown task field: task.%s',taskFieldnames{i}));
        end
    end

    % check for parameters
    if ~isfield(task,'parameter')
        task.parameter.default = 1;
    end

    % set up trial and block numbers
    task.blocknum = 0;
    task.thistrial.thisseg = inf;

    % find out how many segments we have and
    % check to see if they are specified correctly
    if isfield(task,'seglen')
        if isfield(task,'segmin') || isfield(task,'segmax')
            disp(sprintf('(initTask) Found both seglen field and segmin/segmax. Using seglen'));
        end
        task.segmin = task.seglen;
        task.segmax = task.seglen;
    end

    if ~isfield(task,'segmin') || ~isfield(task,'segmax')
        error(sprintf('(initTask) Must specify task.segmin and task.segmax'));
        return
    end

    % look for seqment length quantization pramater, if it 
    % is not set, default to 0. what this does is if you
    % randomize times between segmin and segmax, it will
    % give you a value that is quantized to this value.
    % for example say we have;
    % segmin = 1, segmax =5, segquant = 1.5
    % then the random values that are possible are 1, 2.5, and 4
    % if it is set to 0 then all random values  between 1 and 5 are possible
    if ~isfield(task,'segquant') 
        task.segquant = zeros(1,length(task.segmin));
    end

    if ~isfield(task,'synchToVol')
        task.synchToVol = zeros(1,length(task.segmin));
    end

    % just warn if user has a writeTrace field. It is no longer necessary
    if isfield(task,'writeTrace') || isfield(task,'writetrace')
        disp(sprintf(['(initTask) There is no longer any need to use' ...
            ' writeTrace. All variable settings are correctly stored in the task' ...
            ' variables and can be extracted after the experiment using' ...
            ' getTaskParameters. The passed in writeTrace field will be ignored']));
    end

    task.numsegs = length(task.segmin);
    if length(task.segmin) ~= length(task.segmax)
        error(sprintf('(initTask) task.segmin and task.segmax not of same length\n'));
        return
    end
    if any((task.segmax - task.segmin) < 0)
        error(sprintf('(initTask) task.segmin not smaller than task.segmax\n'));
        return
    end

    % keep the task randstate. Note that initScreen initializes the
    % state of the random generator to a random value (set by clock)
    % each time, guaranteeing a different random sequence. 
    % Note that the updateTask code switches the rand state
    % back and forth between the blockState / trialState at
    % the appropriate times to make sure that *if* the randstate
    % set by initScreen is set the same as a previous run, we
    % get exactly the same sequence of random numbers for
    % the blocks and trials (regardless of what the user is
    % doing inside their callbacks -- which will have a different
    % rand number state).
    % set the randstate type
    task.randstate.type = myscreen.randstate.type;
    % init the random sequence for this task
    task.randstate.state = floor((2^32-1)*rand);
    % initialize the block randomization sequence. This is used so that
    % you can always guarantee the same parameter sequence
    task.randstate.blockState = floor((2^32-1)*rand);
    % initialize the trial randomization sequence. This is used so that
    % you can always guarantee the same segment lengths
    task.randstate.trialState = floor((2^32-1)*rand);

    % set the random state
    randstate = rand(myscreen.randstate.type);
    rand(task.randstate.type,task.randstate.state);

    % here we deal with randVars (see wiki for how to use randVars). The randVars
    % are independent random variables from parameters. Note that this code allows
    % two different ways of setting them up (either as block or uniform). But it
    % is written in a way to be extensible. (look at the functions blockRandomization
    % and uniformRandomization). All the variable values are precomputed, so you 
    % have to specify how long to precompute them for. 
    randTypes = {'block','uniform'};
    % compute stuff for random variables
    task.randVars.n_ = 0;
    % default to computing a length of 250
    if ~isfield(task.randVars,'len_')
        task.randVars.len_ = 250;
    end
    % check the variable names for known randomization types
    randVarNames = fieldnames(task.randVars);
    originalNames = {};shortNames = {};
    for i = 1:length(randVarNames)
        % if we got one, then first initialize the randomization procedure
        if any(strcmp(randVarNames{i},randTypes))
            vars = [];
            disp(sprintf('Computing randVars with %sRandomization.m',randVarNames{i}));
            % we first loop over the length of the array, this is so
            % that, in the case of block, for example, we can have
            % randVars.block{1...n} so that we can have groups of blocked params
            % if the variable is not already a cell array then make a
            % cell array
            thisRandVar = {};
            if ~iscell(eval(sprintf('task.randVars.%s',randVarNames{i})))
                thisRandVar{1} = eval(sprintf('task.randVars.%s',randVarNames{i}));
                thisIsCell = 0;
            else
                thisRandVar = eval(sprintf('task.randVars.%s',randVarNames{i}));
                thisIsCell = 1;
            end
            for varNum = 1:length(thisRandVar)

                eval(sprintf('vars = %sRandomization(thisRandVar{varNum});',randVarNames{i}));
                % compute blocks of trials until we have enough
                varBlock = [];totalTrials = 0;
                % init variables
                for vnum = 1:vars.n_
                    eval(sprintf('task.randVars.%s = [];',vars.names_{vnum}));
                    % now get original names
                    if thisIsCell
                        shortNames{end+1} = vars.names_{vnum};
                        originalNames{end+1} = sprintf('task.randVars.%s{%i}.%s', ...
                            randVarNames{i},varNum,vars.names_{vnum});
                    else
                        shortNames{end+1} = vars.names_{vnum};
                        originalNames{end+1} = sprintf('task.randVars.%s.%s', ...
                            randVarNames{i},vars.names_{vnum});
                    end
                end
                % now keep calculating blocks of the randvars until we have enough
                while totalTrials < task.randVars.len_
                    eval(sprintf('varBlock = %sRandomization(vars,varBlock);', ...
                        randVarNames{i}));
                    totalTrials = totalTrials+varBlock.trialn;
                    for vnum = 1:vars.n_
                        eval(sprintf('task.randVars.%s = [task.randVars.%s varBlock.parameter.%s];', ...
                            vars.names_{vnum},vars.names_{vnum},vars.names_{vnum}));
                    end
                end
            end
        end
    end

    % now go through all of our variables and make a list of names
    % and store how long they are
    randVarNames = fieldnames(task.randVars);
    for i = 1:length(randVarNames)
        % check if it is a random variable
        if ~any(strcmp(randVarNames{i},randTypes)) && isempty(regexp(randVarNames{i},'_$'))
            task.randVars.n_ = task.randVars.n_+1;
            task.randVars.names_{task.randVars.n_} = randVarNames{i};
            task.randVars.varlen_(task.randVars.n_) = ...
                eval(sprintf('length(task.randVars.%s)',randVarNames{i}));
            if any(strcmp(randVarNames{i},shortNames))
                task.randVars.originalName_{task.randVars.n_} = ...
                    originalNames{find(strcmp(randVarNames{i},shortNames))};
            else
                task.randVars.originalName_{task.randVars.n_} = ...
                    sprintf('task.randVars.%s',randVarNames{i});
            end      
        end
    end

    % check get response
    if ~isfield(task,'getResponse')
        task.getResponse = [];
    end
    for i = (length(task.getResponse)+1):task.numsegs
        task.getResponse(i) = 0;
    end

    % run infinite number of blocks if not specified
    if ~isfield(task,'numBlocks')
        task.numBlocks = inf;
    end

    % run infinite number of trials if not specified
    if ~isfield(task,'numTrials')
        task.numTrials = inf;
    end

    % check for waitForBacktick setting
    if ~isfield(task,'waitForBacktick')
        task.waitForBacktick = 0;
    end

    % check for random
    if ~isfield(task,'random')
        task.random =  0;
    end
    task.parameter.doRandom_ = task.random;

    % check for time in ticks
    if ~isfield(task,'timeInTicks')
        task.timeInTicks = 0;
    end
    % check for time in vols
    if ~isfield(task,'timeInVols')
        task.timeInVols = 0;
    end

    % check for both
    if task.timeInTicks && task.timeInVols
        disp(sprintf('(initTask) Time is both ticks and vols, setting to vols'));
        task.timeInTicks = 0;
    end

    % set how many total trials we have run (trialnumTotal is there for
    % compatibility, but doesn't get set anymore)
    task.trialnum = 1;
    task.trialnumTotal = 0;

    % update, how many tasks we have seen
    myscreen.numTasks = myscreen.numTasks+1;

    % now set the segment trace
    %% NOTE: Should this be generalized to simply use addTraces for
    %%       all tasks including the first task? What code is dependent
    %%       on the explicit numbering for a single task? Note then the
    %%       duplicate check for the existance of the field would be
    %%       unnecessary.
    if ~isfield(task,'segmentTrace')
        if myscreen.numTasks == 1
            task.segmentTrace = 2;
        else
            [task myscreen] = addTraces(task, myscreen, 'segment');
        end
    end
    if ~isfield(task,'responseTrace')
        if myscreen.numTasks == 1
            task.responseTrace = 3;
        else
            [task myscreen] = addTraces(task, myscreen, 'response');
        end
    end
    if ~isfield(task,'phaseTrace')
        if myscreen.numTasks == 1
            task.phaseTrace = 4;
        else
            [task myscreen] = addTraces(task, myscreen, 'phase');
        end
    end

    % write out starting phase
    myscreen = writeTrace(1,task.phaseTrace,myscreen);

    % set function handles
    if exist('startSegmentCallback','var') && ~isempty(startSegmentCallback)
        task.callback.startSegment = startSegmentCallback;
    end
    if exist('trialResponseCallback','var') && ~isempty(trialResponseCallback)
        task.callback.trialResponse = trialResponseCallback;
    end
    if exist('screenUpdateCallback','var') && ~isempty(screenUpdateCallback)
        task.callback.screenUpdate = screenUpdateCallback;
    end
    if exist('endTrialCallback','var') && ~isempty(endTrialCallback)
        task.callback.endTrial = endTrialCallback;
    end
    if exist('startTrialCallback','var') && ~isempty(startTrialCallback)
        task.callback.startTrial = startTrialCallback;
    end
    if exist('startBlockCallback','var') && ~isempty(startBlockCallback)
        task.callback.startBlock = startBlockCallback;
    end
    if exist('randCallback','var') && ~isempty(randCallback)
        task.callback.rand = randCallback;
    else
        task.callback.rand = @blockRandomization;
    end

    % initialize the parameters
    task.parameter = feval(task.callback.rand,task.parameter);

    % get calling name
    if ~isfield(task,'taskFilename')
        [st,i] = dbstack;
        task.taskFilename = st(min(i+1,length(st))).file;
    end
    % if we can find the file (we should be able to)
    % load the task listing into the task variables
    % so that we have a record of what *exactly*
    % was run
    ftask = fopen(which(task.taskFilename),'r');
    if (ftask ~= -1)
        task.taskFileListing = fread(ftask,inf,'*char')';
        fclose(ftask);
    end

    % init thistrial
    task.thistrial = [];

    % init the time discrepancy to 0
    task.timeDiscrepancy = 0;

    % there are situations in which for the trial in the sequence
    % we are waiting for a volume to end the trial, but will never
    % get one since the scan is over. Yet, we still want to end the
    % trial to end the experiment, so we are going to have fudge
    % on the last volume. Default is not to, the user can turn this off
    if ~isfield(task,'fudgeLastVolume')
        task.fudgeLastVolume = 0;
    end

    % remember the status of the random number generator
    % and reset it to what it was before this call
    task.randstate.state = rand(task.randstate.type);
    rand(myscreen.randstate.type,randstate);

    % set the debug mode to stop on error
    dbstop if error

end
