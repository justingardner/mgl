function info = getAllInfo()%% getAllInfo

files = dir(fullfile(pwd,'mat/*.mat'));

info = {};
for fi = 1:length(files)
    info{fi} = getInfo(files(fi).name);
    
end