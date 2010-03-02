% blockRandomization.m
%
%      usage: blockRandomization()
%         by: justin gardner
%       date: 01/22/07
%    purpose: function that decides order of parameters,
%             it needs to set block.parameter with relevant
%             parameters and what they will be set to.
%             e.g. block will end up looking like:
%             block.parameter.parameter1 = [3 2 1 2 1 3];
%             block.parameter.parameter2 = [0 90 40 90 40 0];
%             also, sets the number of trials (e.g.)
%             block.trialn = 6;
%
%             setting task.random = 0; sets no randomzation
%             random = 1, complete randomization
%             random = 2, interleaved randomization
% 
%             remember this function can only affect the
%             block, it cannot change task or myscreen
%
%             This functions work by first initializing the parameters (using initRandomization)
%             this is done in the case where there is only one input to the function
%             On subsequent calls there will be two input arguments, the (already init) parameter
%             structure and a previous block of parameter (which can be empty). 
%             The routine then returns a randomized set of parameters in the format noted above
%           
% 
function retval = blockRandomization(parameter,previousParamIndexes)

% check for init case
if nargin == 1
  % init parameters
  parameter = initRandomization(parameter);
  if ~isfield(parameter,'doRandom_'),parameter.doRandom_=1;end
  retval = parameter;
  return
end

% get a randomperm for use for total randomization
completeRandperm = randperm(parameter.totalN_);
% create a randomization of the parameters
innersize = 1;
for paramnum = 1:parameter.n_
  paramIndexes{paramnum} = [];
  for rownum = 1:parameter.size_(paramnum,1)
    lastcol = 0;
    for paramreps = 1:(parameter.totalN_/parameter.size_(paramnum,2))/innersize
      % if we need to randomize, then do it here so that
      % arrays with multiple rows have different randomizations
      if parameter.doRandom_ > 0
	thisparamIndexes = randperm(parameter.size_(paramnum,2));
      else
	thisparamIndexes = 1:parameter.size_(paramnum,2);
      end
      % spread it out over inner dimensions
      thisparamIndexes = thisparamIndexes*repmat(eye(length(thisparamIndexes)),1,innersize);
      thisparamIndexes = reshape(reshape(thisparamIndexes,length(thisparamIndexes)/innersize,innersize)',1,length(thisparamIndexes));
      % stick into array appropriately
      paramIndexes{paramnum}(rownum,lastcol+1:lastcol+length(thisparamIndexes)) = thisparamIndexes;
      lastcol = lastcol+length(thisparamIndexes);
    end
  end
  % need to convert it
  for rownum = 1:parameter.size_(paramnum,1)
    % and then convert the numbers into proper subscripts to
    % actually get the proper stimulus values
    paramIndexes{paramnum}(rownum,:) = (paramIndexes{paramnum}(rownum,:)-1)*parameter.size_(paramnum,1)+rownum;
    % if we complete randomization then do it here
    if parameter.doRandom_ == 1
      paramIndexes{paramnum}(rownum,:) = paramIndexes{paramnum}(rownum,completeRandperm);
    end
  end
  % update the size of the inner dimensions
  innersize = innersize*parameter.size_(paramnum,2);
end

% now go and set this blocks parameters appropriately
for paramnum = 1:parameter.n_
  eval(sprintf('block.parameter.%s = parameter.%s(paramIndexes{paramnum});',parameter.names_{paramnum},parameter.names_{paramnum}));
end  

block.trialn = parameter.totalN_;

retval = block;