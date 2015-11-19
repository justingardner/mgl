info = getAllInfo;

for i = 1:length(info)
    cinfo = info{i};
    
    disp(sprintf('%s: %s',cinfo.date,cinfo.comment));
end