% initRandomization.m
%
%        $Id:$ 
%      usage: [parameter alreadyInitialized] = initRandomization(parameter)
%         by: justin gardner
%       date: 03/01/10
%    purpose: function that initializes the parameters for randomization
%             routines blockRandomization and uniformRandomization.
%
%             parameter is a structure that has fields for each
%             paramter that you have (e.g. parameter.myparam1 parameter.myparam2 etc.)
%
%             this function then adds fields that are used by the randomization routine
%             line parameter.n_ which contains the number of parameters etc. All
%             the fields added here end in _
%
%             alreadyInitialized is whether the parameter structure already had been initialized
%
function [parameter alreadyInitialized] = initRandomization(parameter)

% check arguments
if ~any(nargin == [1])
  help initRandomization
  return
end

% init alreadyInitialized
alreadyInitialized = 0;

% check if this routine has been run before
if isfield(parameter,'n_')
  disp(sprintf('(initRanomization) Re-initialized parameters'));
  alreadyInitialized = 1;
  % clear old fields
  parameter.names_ = {};
  parameter.n_ = [];
  parameter.size_ = [];
  parameter.totalN_ = [];
end

% get parameter names now
names = fieldnames(parameter);

% cycle through looking for parameters
n = 0;
for i = 1:length(names)
  % if it ends in underscore it is a reserved variable
  if isempty(regexp(names{i},'_$'))
    n = n+1;
    parameter.names_{n} = names{i};
  end
end

% number of parameters
parameter.n_ = length(parameter.names_);

% calculate sizes and check for column vectors
for i = 1:parameter.n_
  paramsize = eval(sprintf('size(parameter.%s)',parameter.names_{i}));
  % check for column vectors
  if (paramsize(1) > 1) && (paramsize(2) == 1)
    disp(sprintf('Parameter %s is a column vector',parameter.names_{i}));
  end
  parameter.size_(i,:) = eval(sprintf('size(parameter.%s)',parameter.names_{i}));
end

% get total number of parameters
parameter.totalN_ = prod(parameter.size_(:,2));

