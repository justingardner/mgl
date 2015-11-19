%% Code quickly checks the MAT files to see if we should pay bonuses

info = getAllInfo;

for i = 1:length(info)
    cinfo = info{i};
    
    disp(sprintf('%s: %s, pay = %1.2f + %1.2f; response rate: %0.2f',cinfo.date,cinfo.wid,cinfo.pay,cinfo.bonus,1-cinfo.norr));
end