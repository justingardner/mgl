function makeAllMats() 
    files = dir('./xmls/*.xml');
    for file=files'
        generateMat(file.name);
    end
end