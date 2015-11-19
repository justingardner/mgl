
function [mainData, fullHeader] = ccmt_2long(e)
main = e{1};

%%
% just to track trials
main.trialNum = 1:main.nTrials;

% First re-organize into a matrix, tracking the headers
fullHeader = { 'trial', ...
    'run', ... % runVars
    'task', 'lCon','rCon','lCoh', 'rCoh', 'correct', ... % rand items
    'conSide','cohSide','catch',... % param items
    'response'}; % main items


% For each item in the header (re-named) what is the corresponding data?
corrHeader = {'blockTrialNum'};
% These come AFTER all the corrData items. They are pulled from
% 'main.runVars'
runHeader = {'runNum'};
% 'main.randVars'
randHeader = {'task', 'lCon','rCon','lCoh', 'rCoh', 'correct'};
% these are pulled from main.parameter
pedHeader = {'conSide','cohSide','catch'};
% these are pulled from main
mainHeader = {'response'};

mainData = [];

% mainData(:,1) % COLUMN 1
for i = 1:length(corrHeader)
    mainData(:,end+1) = main.(corrHeader{i});
end

for i = 1:length(runHeader)
    mainData(:,end+1) = repmat(main.runVars.runNum,size(mainData,1),1);
end

for j = 1:length(randHeader)
    mainData(:,end+1) = main.randVars.(randHeader{j});
end

for k = 1:length(pedHeader)
    mainData(:,end+1) = main.parameter.(pedHeader{k});
end

for l = 1:length(mainHeader)
    mainData(:,end+1) = main.(mainHeader{l});
end

if size(mainData,2)~=length(fullHeader)
    error('Lengths are incorrect! Check your variables');
end

% Now write to mainFile
disp('Success');
