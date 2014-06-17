% upDownStaircase.m
%
%        $Id$
%      usage: upDownStaircase(nup,ndown,initialThreshold,stepsize,<stepRule=0>)
%         by: justin gardner
%       date: 06/20/05
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: implements a upDownStaircasecase 
% 
%       e.g.: to start a 1up-3down upDownStaircasecase with given step size
%             >> s = upDownStaircase(1,3,thresh,stepsize)
%             to start a 1up-3down upDownStaircasecase which only
%             allows the usage of signal strengths 3 4 and 5.
%             >> s = upDownStaircase(1,3,thresh,[3 4 5])
%
%             with a given stepsize, you can use the Levitt
%             rule which halves the stepsize after the 1st,3rd,7th,15th
%             reversal. the default is to keep the stepsize the same
%             >> s = upDownStaircase(1,3,thresh,stepsize,'levitt')
%             you can specify a minimum stepsize
%             >> s= upDownStaircase(1,3,thresh,[stepsize minStepsize],'levitt');
%
%             with a given stepsize, you can use the Pest Rules which are
%                1) halve the stepsize after each reversal
%                2) use the same stepsize for same direction, except
%                3) Double the stepsize on the third step in the same direction
%                4) If a reversal follows a doubling of step size, then double
%                   the stepsize on the fourth step in the same direction
%                5) Maximum stepsize (and minimum) should be specifed. Max should
%                   be atleast 8 to 16 times minimum stepsize
%             >> s = upDownStaircase(1,2,thresh,[initStepsize minStepsize maxStepsize],'pest');
%         
%             to update the staircase, where response is 1 or 0 for correct or incorrect
%             >> s = upDownStaircase(s,response)
%
%             s.threshold holds the current estimate of the threshold 
%             
%             you can set min and max values for the threshold by
%             setting (after you initialize the staircase):
%             s.minThreshold = 0; s.maxThreshold = 1000;
%             
function s = upDownStaircase(varargin)

if ((nargin == 1) || isstr(varargin{2}))
  % compute thresholds
  s = computeThreshold(varargin{1},{varargin{2:end}});
  return
% two arguments, means an update
elseif (nargin == 2)
  % give names to the arguments
  s = varargin{1};
  response = varargin{2};
  % update number of trials
  s.n = s.n + 1;
  s.response(s.n) = response; %correct or incorrect
  s.strength(s.n) = s.threshold;
  % update the response in this particular group
  s.group(s.groupn).n = s.group(s.groupn).n + 1;
  s.group(s.groupn).response(s.group(s.groupn).n) = response;
  % see if we need to go down
  if (sum(s.group(s.groupn).response) == s.downn)
    s = dostep(s,-1);
  % see if we need to go up
  elseif (sum(s.group(s.groupn).response == 0) == s.upn)
    s = dostep(s,1);
  end
elseif ((nargin == 4) || (nargin == 5))
  % set type
  s.type = 'upDownStaircase';
    
  % controls how many up, how many down
  s.upn = varargin{1};
  s.downn = varargin{2};
  
  % init the upDownStaircasecase parameters
  s.n = 0;
  s.threshold = varargin{3};
  s.response = [];
  s.group.response = [];
  s.group.n = 0;
  s.reversal = [];
  s.reversaln = 0;
  s.groupn = 1;
  % check for stepsize rule
  s.stepsizeRule = 0;
  if (nargin == 5) 
    if isequal(varargin{5},1) || isequal(lower(varargin{5}),'levitt')
      s.stepsizeRule = 1;
    elseif isequal(varargin{5},2) || isequal(lower(varargin{5}),'pest')
      s.stepsizeRule = 2;
      s.stepsBeforeDoubling = 2;
    end
  end
  % if this is a singleton, it gives the step size
  % of the upDownStaircasecase
  if (length(varargin{4}) == 1)
    s.stepsize = varargin{4};
    s.steptype = 'step';
    s.startStepSize = s.stepsize;
  % if we are using a stepsize changing algorithim
  elseif s.stepsizeRule > 0
    s.stepsize = varargin{4}(1);
    s.steptype = 'step';
    s.startStepSize = s.stepsize;
    % user specified minimum stepsize
    if length(varargin{4}) == 2
      s.minStepsize = varargin{4}(2);
    % user specified maximum stepsize
    elseif length(varargin{4}) == 3
      s.minStepsize = varargin{4}(2);
      s.maxStepsize = varargin{4}(3);
    else
      disp(sprintf('(upDownStaircase) When using rules, you can specify [initial <min> <max>] as your stepsizes only'));
      help upDownStaircase;
      return
    end
  else
    % otherwise, we must be given an array of fixed
    % values that can be tested
    s.fixed = varargin{4};
    s.steptype = 'fixed';
    % if the threshold isn't one of these fixed 
    % stimuli then set it to be that
    if ~sum(s.threshold == s.fixed)
      disp(sprintf('(upDownStaircase): Threshold %0.2f is not one of fixed',s.threshold));
      s.threshold = s.fixed(first(find(abs(s.fixed - s.threshold)==min(abs(s.fixed-s.threshold)))));
      disp(sprintf('                   Threshold set to %0.2f',s.threshold));
    end
    % make sure that the fixed list is in order
    s.fixed = sort(unique(s.fixed));
    % remember where the threshold is
    s.fixedthreshold = find(s.threshold == s.fixed);
    % cant reduce stepsize
    s.stepsizeRule = 0;
  end
  % set minmax
  s.minThreshold = -inf;
  s.maxThreshold = inf;
  % set minimum stepsize
  if ~isfield(s,'minStepsize')
    % for PEST, make this default to 1/8 the starting stepsize
    if s.stepsizeRule == 2
      s.minStepsize = s.stepsize/8;
    else
      s.minStepsize = -inf;
    end
  end
  % set maximum stepsize
  if ~isfield(s,'maxStepsize')
    % for PEST, make this default to 16 * minStepsize
    if s.stepsizeRule == 2
      s.maxStepsize = s.minStepsize*16;
    else
      s.maxStepsize = inf;
    end
  end

else
  help upDownStaircase;
  return
end



%%%%%%%%%%%%%%%%%%%%%
% step up threshold
%%%%%%%%%%%%%%%%%%%%%
function s = stepup(s)

if strcmp(s.steptype,'step')
  s.threshold = s.threshold+s.stepsize;
elseif strcmp(s.steptype,'fixed')
  s.fixedthreshold = min(s.fixedthreshold+1,length(s.fixed));
  s.threshold = s.fixed(s.fixedthreshold);
end

%%%%%%%%%%%%%%%%%%%%%
% step down threshold
%%%%%%%%%%%%%%%%%%%%%
function s = stepdown(s)

if strcmp(s.steptype,'step')
  s.threshold = s.threshold-s.stepsize;
elseif strcmp(s.steptype,'fixed')
  s.fixedthreshold = max(s.fixedthreshold-1,1);
  s.threshold = s.fixed(s.fixedthreshold);
end

%%%%%%%%%%%%%%%%%%%%%
% does a step
%%%%%%%%%%%%%%%%%%%%%
function s = dostep(s,stepdir)

% do the step (for pest we have to determine the stepsize first)
if s.stepsizeRule ~= 2
  % apply step
  if (stepdir == -1) s = stepdown(s);else s = stepup(s);end
end

% check if this is a reversal
if (isfield(s,'direction'))
  % if we have changed direction, then
  % this is a reversal
  if (s.direction ~= stepdir)
    s.reversaln = s.reversaln+1;
    % levitt rule
    if s.stepsizeRule == 1
      % see if this is the first reversal,
      % or a reversal that is 1,3,7,15 etc.
      % if so we will cut step size by two
      if (sum(dec2bin(s.reversaln+1)=='1')==1)
	s.stepsize = max(s.minStepsize,s.stepsize/2);
%	disp(sprintf('Reversal %i: stepsize = %0.8f',s.reversaln,s.stepsize));
      
      end
    % PEST rule
    elseif s.stepsizeRule == 2
      % half the step size
      s.stepsize = max(s.minStepsize,s.stepsize/2);
      % reset the same direction counter
      if s.stepsBeforeDoubling <= 0
	% if we have been doubling before this reversal, then
	% we need an extra step before doubling again (Rule #4)
	s.stepsBeforeDoubling = 3;
      else
	% otherwise 3 steps in a row in same direction before doubling
	s.stepsBeforeDoubling = 2;
      end
    end
    s.reversals(s.reversaln) = s.n;
  else
    % PEST rule same direction
    if s.stepsizeRule == 2
      s.stepsBeforeDoubling = s.stepsBeforeDoubling - 1;
      if (s.stepsBeforeDoubling <= 0)
	s.stepsize = min(s.maxStepsize,s.stepsize*2);
      end
    end
  end
end

% do the step (after applying pest rule
if s.stepsizeRule == 2
  % apply step
  if (stepdir == -1) s = stepdown(s);else s = stepup(s);end
end

% reset group number etc.
s.groupn = s.groupn+1;
s.group(s.groupn).n = 0;

% keep track of direction we are in
s.direction = stepdir;

% check for min
if s.threshold < s.minThreshold
  s.threshold = s.minThreshold;
end

% check for max
if s.threshold > s.maxThreshold
  s.threshold = s.maxThreshold;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% returns first element of input array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = first(x)

if (isempty(x))
  retval = [];
else
  retval = x(1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    commuteThreshold    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = computeThreshold(s,args)

getArgs(args,{'dispFig=0','maxIter=1000','dogoodnessoffit=0','dobootstrap=0'});

% compute the mean of last k reversals
if isfield(s,'reversals') && (length(s.reversals) > 0)
  % computes the mean of last reversals
  for i = 1:length(s.reversals)
    s.computedThresholds.meanOfReversals(i) = mean(s.strength(s.reversals(i:end)));
  end
  s.computedThresholds.meanOfReversals = fliplr(s.computedThresholds.meanOfReversals);
  s.computedThresholds.meanOfAllReversals = s.computedThresholds.meanOfReversals(end);
  % pointers to some common reversals to take
  for nReversals = [3 5 7]
    if length(s.reversals) >= nReversals 
      s.computedThresholds.(sprintf('meanOfLast%iReversals',nReversals)) = s.computedThresholds.meanOfReversals(nReversals);
    else
      s.computedThresholds.(sprintf('meanOfLast%iReversals',nReversals)) = nan;
    end
  end
end

% compute weibull fit
if exist('fitweibull') == 2
  s.computedThresholds.weibullFitParams = fitweibull(s.strength,...
    s.response,'dispfig',dispFig,'maxIter',maxIter,'dogoodnessoffit',...
    dogoodnessoffit,'dobootstrap',dobootstrap);
  s.computedThresholds.weibull = s.computedThresholds.weibullFitParams.fitparams(1);
end

