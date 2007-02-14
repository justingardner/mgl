% upDownStaircase.m
%
%        $Id$
%      usage: upDownStaircase()
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
%             >> s = upDownStaircase(1,3,thresh,stepsize,1)
%
%             to update the staricase, where response is 1 or 0
%             >> s = upDownStaircase(s,response)
%             
%
function s = upDownStaircase(varargin)

% two arguments, means an update
if (nargin == 2)
  % give names to the arguments
  s = varargin{1};
  response = varargin{2};
  % update number of trials
  s.n = s.n + 1;
  s.response(s.n) = response;
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
  s.type = 'upDownStaircasecase';
    
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
  % if this is a singleton, it gives the step size
  % of the upDownStaircasecase
  if (length(varargin{4}) == 1)
    s.stepsize = varargin{4};
    s.steptype = 'step';
    s.startStepSize = s.stepsize;
    if (nargin == 5) && varargin{5}==1
      s.reduceStepsizeOnReversals = 1;
    else
      s.reduceStepsizeOnReversals = 0;
    end
  else
    % otherwise, we must be given an array of fixed
    % values that can be tested
    s.fixed = varargin{4};
    s.steptype = 'fixed';
    % if the threshold isn't one of these fixed 
    % stimuli then set it to be that
    if ~sum(s.threshold == s.fixed)
      disp(sprintf('UHOH: Threshold %0.2f is not one of fixed',s.threshold));
      s.threshold = s.fixed(first(find(abs(s.fixed - s.threshold)==min(abs(s.fixed-s.threshold)))));
      disp(sprintf('      Threshold set to %0.2f',s.threshold));
    end
    % make sure that the fixed list is in order
    s.fixed = sort(unique(s.fixed));
    % remember where the threshold is
    s.fixedthreshold = find(s.threshold == s.fixed);
    % cant reduce stepsize
    s.reduceStepsizeOnReversals = 0;
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

if (stepdir == -1)
  s = stepdown(s);
else
  s = stepup(s);
end

% reset group number etc.
s.groupn = s.groupn+1;
s.group(s.groupn).n = 0;

% check if this is a reversal
if (isfield(s,'direction'))
  % if we have changed direction, then
  % this is a reversal
  if (s.direction ~= stepdir)
    s.reversaln = s.reversaln+1;
    % reduce step size if called for
    if s.reduceStepsizeOnReversals
      % see if this is the first reversal,
      % or a reversal that is 1,3,7,15 etc.
      % if so we will cut step size by two
      if (sum(dec2bin(s.reversaln+1)=='1')==1)
	s.stepsize = s.stepsize/2;
%	disp(sprintf('Reversal %i: stepsize = %0.8f',s.reversaln,s.stepsize));
      end
    end
    s.reversals(s.reversaln) = s.n;
  end
end

% keep track of direction we are in
s.direction = stepdir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% returns first element of input array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = first(x)

if (isempty(x))
  retval = [];
else
  retval = x(1);
end

