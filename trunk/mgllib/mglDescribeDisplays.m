% mglDescribeDisplays: Retrieves information about available displays and
% basic computer info.
%
%        $Id$
%      usage: mglDescribeDisplays
%         by: Christopher Broussard
%       date: 10/27/07
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Retrieves information about available displays.
%      usage: Get a list of all available displays as a struct array and
%		  returns basic computer information.
%
%		  % Example
%		  [displayInfo, computerInfo] = mglDescribeDisplays;
%
%		  % A displayInfo element has the following fields.
%		  isMain -- Indicates whether a display is the main display.
%		  isCaptured -- Indicates whether a display is captured.
%		  isStereo -- Indicates whether a display is running in stereo mode.
%		  refreshRate -- Refresh rate of the display.
%		  screenSizemm -- The width and height of a display in millimeters.
%		  screenSizepx -- The width and height of the display in pixels.
%		  bitsPerPixel -- The number of bits per pixel.
%		  bitsPerSample -- The number of pixels per pixel component.
%		  samplesPerPixel -- The number of color components used to represent a pixel.
%		  openGLacceleration -- Indicates if the display is using Quartz Extreme rendering.
%		  unitNumber -- The logical unit number of a display, i.e. I/O Kit device node ID.
%		  modelNumber -- The model number of a display monitor.
%		  serialNumber -- The serial number of a display' monitor.
%		  vendorNumber -- The vendor number of the display's monitor.
%		  gammaTableWidth -- The number of bits per component in the hardware gamma table.
%		  gammaTableLength -- The number of entries in the hardware gamma table.
%
%		  % computerInfo has the following fields.
%		  machineClass -- The machine class.
%		  machineModel -- The machine model.
%		  numCPUs -- The number of CPUs in the machine.
%		  physicalMemory -- The amount of physical memory in megabytes.
%		  hostName -- The network name of the machine.
%		  busFrequency -- The bus frequency in megahertz.
%		  cpuFrequency -- The CPU frequency in megahertz.
%		  OSType -- The OS type.
%		  OSRelease -- The release version of the OS.
%		  openGL -- A structure containing OpenGL information retrieved from Matlab.
%
%		  % As of Tiger, OS X only supports 8 bit frame buffers even if the
%		  % gamma table is capable of higher values.
%       e.g.:
%
% [displayInfo computerInfo] = mglDescribeDisplays
%
function [displayInfo, computerInfo] = mglDescribeDisplays

% Get display information.
[displayInfo computerInfo] = mglPrivateDescribeDisplays;

% Get the OpenGL information from Matlab. But only do this if
% the display is not open, since if it is open, it seems to cause
% some problems for the renderer - i.e. nothing draws after making the call
if nargout > 1
  if isequal(mglGetParam('displayNumber'),-1)
    computerInfo.openGL = opengl('data');
  else
    computerInfo.openGL = [];
  end
  [computerInfo.platform computerInfo.maxMatrixSize computerInfo.endian] = computer;
end