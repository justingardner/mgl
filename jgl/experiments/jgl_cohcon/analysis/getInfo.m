function info = getInfo(fname)

load(fullfile('~/proj/cohcon_mturk/mat',fname));
date =  datestr(myscreen.startTime/86400+datenum(1970,1,1),'yyyy.mm.dd');

wid = strrep(myscreen.workerID,'=','');

trials = length(jglData.responses);

noresp = jglData.responses==0;
norr = mean(noresp);

pay = 0.25;
if trials > 100 % only true if they make it through both of the task runs
    bonus = 1.25;
else
    bonus = 0;
end

comment = jglData.postSurvey.comments;

info.wid = wid;
info.date = date;
info.pay = pay;
info.trials = trials;
info.bonus = bonus;
info.tpay = pay + bonus;
info.comment = comment;
info.norr = norr;