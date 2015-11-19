function generateMat(filename)
    xDoc = xmlread(strcat('./xmls/', filename));
    xRoot = xDoc.getDocumentElement;
    xData = parseXML(xRoot);
    clear xDoc xRoot;
    fieldNames = fields(xData);
    for i=1:length(fieldNames)
        eval(sprintf('%s = xData.%s;', fieldNames{i}, fieldNames{i}));
    end
    if ~isdir(fullfile(pwd,'mat')), mkdir(fullfile(pwd,'mat')); end
    date =  datestr(myscreen.startTime/86400+datenum(1970,1,1),'yyyy-mm-dd');

    fileName = fullfile(pwd,'mat',sprintf('%s_%s.mat',myscreen.uniqueId,date));
    clear xData i fieldNames;
    
    % reduce file sizes
    for ti = 1:length(task{1})
        task{1}{ti} = rmfield(task{1}{ti},'block');
    end
    save(fileName);

end

