function generateMat(filename)
    xDoc = xmlread(strcat('./xmls/', filename));
    xRoot = xDoc.getDocumentElement;
    xData = parseXML(xRoot);
    clear xDoc xRoot;
    fieldNames = fields(xData);
    for i=1:length(fieldNames)
        eval(sprintf('%s = xData.%s;', fieldNames{i}, fieldNames{i}));
    end
    fileName = strcat(myscreen.uniqueId,'.mat');
    clear xData i fieldNames;
    
    save(fileName);

end

