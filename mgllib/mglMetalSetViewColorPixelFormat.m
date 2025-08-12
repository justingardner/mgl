% mglMetalSetViewColorPixelFormat: Set the color pixel format of the mglMetal view.
%
%        $Id$
%      usage: mglMetalSetViewColorPixelFormat(formatIndex)
%         by: Ben Heasly
%       date: 04/25/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Sets a non-default color pixel format for the mglMetal view, frame buffer, and pipeline states.
%
%             This is experimental!
%
%             The MTKView used by the mglMetal app allows us to specify a
%             color pixel format for rendering.  On wide color gammut
%             displays, this might allow us to show finer-grained colors.
%
%             Here are the view formats supportred in macOS 10.15+.
%             MGL gives each one an arbitrary "format index" which you can
%             use when calling this function.
%              - 0: MTLPixelFormatBGRA8Unorm (default)
%              - 1: MTLPixelFormatBGRA8Unorm_sRGB
%              - 2: MTLPixelFormatRGBA16Float
%              - 3: MTLPixelFormatRGB10A2Unorm
%              - 4: MTLPixelFormatBGR10A2Unorm (recommended?)
%
%             Here are some related Apple docs:
%              - MTKView property: https://developer.apple.com/documentation/metalkit/mtkview/1535940-colorpixelformat
%              - List of formats: https://developer.apple.com/documentation/quartzcore/cametallayer/1478155-pixelformat
%
%             The docs recommend MTLPixelFormatBGR10A2Unorm in particular:
%
%             "On devices with a wide color display, use this format
%             instead of MTLPixelFormatBGRA8Unorm to reduce banding
%             artifacts in your displayed content."
%
%      usage:
%
%             % Choose a non-default color pixel format.
%             mglOpen();
%             mglMetalSetViewColorPixelFormat(4);
%
%             % Restore the default format (no arg).
%             mglOpen();
%             mglMetalSetViewColorPixelFormat();
function results = mglMetalSetViewColorPixelFormat(formatIndex, socketInfo)

results = [];

if nargin < 1
    formatIndex = 0;
end

if nargin < 2 || isempty(socketInfo)
  socketInfo =  mglGetParam('activeSockets');
  % no open mgl window, return
  if isempty(socketInfo)
    disp(sprintf('(%s) No open mgl window',mfilename));
    return
  end
end

if numel(socketInfo) > 1
    fprintf('(mglMetalSetViewColorPixelFormat) Setting color pixel format for %d mglMetal windows.\n', numel(socketInfo));
    fprintf('(mglMetalSetViewColorPixelFormat) If you want to set the pixel format for one window only, first use mglMirrorActivate to activate a single window.\n');
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglSetViewColorPixelFormat);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(formatIndex));
results = mglReadCommandResults(socketInfo, ackTime);

