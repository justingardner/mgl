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
function block = blockRandomization(parameter,block,previousBlock,task)

% check arguments
if ~any(nargin == [4])
  help blockRandomization
  return
end

% get a randomperm for use for total randomization
completeRandperm = randperm(parameter.totalN);
% create a randomization of the parameters
innersize = 1;
for paramnum = 1:parameter.n
  paramnums = [];
  for rownum = 1:parameter.size(paramnum,1)
    lastcol = 0;
    for paramreps = 1:(parameter.totalN/parameter.size(paramnum,2))/innersize
      % if we need to randomize, then do it here so that
      % arrays with multiple rows have different randomizations
      if task.random > 0
	thisparamnums = randperm(parameter.size(paramnum,2));
      else
	thisparamnums = 1:parameter.size(paramnum,2);
      end
      % spread it out over inner dimensions
      thisparamnums = thisparamnums*repmat(eye(length(thisparamnums)),1,innersize);
      thisparamnums = reshape(reshape(thisparamnums,length(thisparamnums)/innersize,innersize)',1,length(thisparamnums));
      % stick into array appropriately
      paramnums(rownum,lastcol+1:lastcol+length(thisparamnums)) = thisparamnums;
      lastcol = lastcol+length(thisparamnums);
    end
  end
  % need to convert it
  for rownum = 1:parameter.size(paramnum,1)
    % and then convert the numbers into proper subscripts to
    % actually get the proper stimulus values
    paramnums(rownum,:) = (paramnums(rownum,:)-1)*parameter.size(paramnum,1)+rownum;
    % if we complete randomization then do it here
    if task.random == 1
      paramnums(rownum,:) = paramnums(rownum,completeRandperm);
    end
  end
  % now go and set this blocks parameters appropriately
  eval(sprintf('block.parameter.%s = parameter.%s(paramnums);',parameter.names{paramnum},parameter.names{paramnum}));
  
  % update the size of the inner dimensions
  innersize = innersize*parameter.size(paramnum,2);
end

block.trialn = parameter.totalN;
