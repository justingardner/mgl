% mglFLush: Swaps front and back buffer
%
%      usage: mglFlush
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Swaps front and back buffer of screen
%      usage: mglFlush;
%       e.g.: mglOpen;
%             mglClearScreen([1 0 0]);
%             mglFlush;
%             mglClearScreen([0 1 0]);
%             mglFlush;
%             mglFlush;
%             mglFlush;
function mglFlush

global mgl

% write flush comnand and wait for return value.
mglSocketWrite(mgl.s, mgl.command.mglFlush);
mglSocketRead(mgl.s, 'double');
