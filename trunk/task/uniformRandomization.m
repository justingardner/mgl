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
  % get parameter names now
  names = fieldnames(parameter);
  for i = 1:length(names)
    % if it ends in underscore it is a reserved variable
    n = 0;
    if isempty(regexp(names{i},'_$'))
      n = n+1;
      parameter.names_{n} = names{i};
    end
  end
  parameter.n_ = length(parameter.names_);
  for i = 1:parameter.n_
    paramsize = eval(sprintf('size(parameter.%s)',parameter.names_{i}));
    % check for column vectors
    if (paramsize(1) > 1) && (paramsize(2) == 1)
      eval(sprintf('parameter.%s=paramater.%s''',parameter.names_{i},paramater.names_{i}));
      parameter.size_(i) = paramsize(1);
    else
      parameter.size_(i) = paramsize(2);
    end
  end
  % set the block length
  if ~isfield(parameter,'blocklen_')
    parameter.blocklen_ = 250;
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