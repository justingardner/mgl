info = getAllInfo;

wid = {}; dates = {}; pays = {};

disp('-------');
disp('PAYINFO');
disp('-------');
sub = 0;
% Formatting:
% WorkerID | Date | Payment
for fi = 1:length(files)
    cinfo = info{fi};
    wid{end+1} = cinfo.wid;
    dates{end+1} =  cinfo.date;
    pays{end+1} = cinfo.tpay;
    sub = sub + cinfo.tpay;
%     disp(sprintf('%s | %s | %0.2f',wid,date,pay));
end
for i = 1:length(wid)
    disp(wid{i});
end
for i = 1:length(dates)
    disp(dates{i});
end
for i = 1:length(pays)
    disp(sprintf('%1.2f',pays{i}));
end
disp('----');

disp(sprintf('Subtotal: %0.2f\nAmazon Fee: %0.2f\nGrand Total %0.2f',sub,sub*.2,sub+sub*.2));