% mglCameraLoadData.m
%
%      usage: mglCameraLoadData(filename)
%         by: justin gardner
%       date: 10/29/19
%    purpose: Fucntion to load data file that is stored by mglCameraThread('save');
%
function retval = mglCameraLoadData(filename)

% default return argument
retval = [];

% check arguments
if ~any(nargin == [1])
  help mglCameraLoadData
  return
end

% check for valid filename
if ~isfile(filename)
  disp(sprintf('(mglCameraLoadData) Could not open file: %s',filename));
  return
end
  
% load the file
fid = fopen(filename,'r');
if fid == -1
  disp(sprintf('(mglCameraLoadData) Could not open file: %s',filename));
  return
end

% read the header
numBytes = fread(fid,1,'uint8');
headerVersion = fread(fid,1,'uint8');

% check version
if (headerVersion ~= 1)
  disp(sprintf('(mglCameraLoadData) Header version is not valid: %i',headerVersion));
  return
end

% check that we have enough bytes
if numBytes ~= 14
  disp(sprintf('(mglCameraLoadData) Header reports invalid number of bytes: %i',numBytes));
  return
end

% load the size of the data
imageSize = fread(fid,3,'uint32');
disp(sprintf('(mglCameraLooadData) Found %i images of size %i x %i',imageSize(3),imageSize(1),imageSize(2)));

% read the file
retval = fread(fid,prod(imageSize),'uint8=>uint8');
if isempty(retval) || (prod(size(retval)) ~= prod(imageSize))
  retval = [];
  disp(sprintf('(mglCameraLooadData) Could not read data from file: %s',filename));
  return
end

% close file
fclose(fid);

% reformat and return
retval = reshape(retval,imageSize(1),imageSize(2),imageSize(3));

  

  