% uniformRandomization.m
%
%      usage: uniformRandomization()
%         by: justin gardner
%       date: 01/22/07
%    purpose: function that decides order of parameters,
% 
function retval = uniformRandomization(parameter,previousParamIndexes)

%%%%%%%%%%%%%%%%%%%%%%
% do init
%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
  parameter = initRandomization(parameter);
  % set the block length (that is how many trials to compute out for)
  if ~isfield(parameter,'blocklen_')
    % get the length of the parameter with the largest number of unique values
    maxParameterSize = 0;
    if isfield(parameter,'size_') && ~isempty(parameter.size_)
      maxParameterSize = max(parameter.size_(:));
    end
    % make the block default to 250 (just an arbitraty number, meant
    % to be large) If there are more parameter values than 250, then
    % make it at least as long as the maximum parameter size so that
    % we sample all possible values of the parameter
    parameter.blocklen_ = max(250,maxParameterSize);
  end
  retval = parameter;
  return
end

%%%%%%%%%%%%%%%%%%%%%%
% calculate a block
%%%%%%%%%%%%%%%%%%%%%%
block.trialn = parameter.blocklen_;
for i = 1:parameter.n_
  % get a sequence of the parameter values
  eval(sprintf('sequence = repmat(parameter.%s,1,ceil(parameter.blocklen_/parameter.size_(i)));',parameter.names_{i}));
  % and set it in the block to a random permutation.
  eval(sprintf('block.parameter.%s = sequence(randperm(parameter.blocklen_));',parameter.names_{i}));
end
retval = block;
