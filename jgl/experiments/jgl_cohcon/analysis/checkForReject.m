function checkForReject(wid)

file = dir(sprintf('~/proj/cohcon_mturk/mat/%s*.mat',wid));

load(fullfile('~/proj/cohcon_mturk/mat/',file(1).name));

if sum(jglData.responses==0)>20
    disp(sprintf('Worker Failed to Respond to >20 trials'));
else
    disp('Fine');
end