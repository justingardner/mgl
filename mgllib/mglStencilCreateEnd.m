% mglStencilCreateEnd
%
%        $Id$
%      usage: mglStencilCreateEnd
%         by: justin gardner
%       date: 05/26/2006
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Ends drawing to stencil
%
%       e.g.:
%mglOpen;
%mglScreenCoordinates;
%
%%Draw an oval stencil
%mglStencilCreateBegin(1);
%mglFillOval(300,400,[100 100]);
%mglStencilCreateEnd;
%mglClearScreen;
%
%% now draw some dots, masked by the oval stencil
%mglStencilSelect(1);
%mglPoints2(rand(1,5000)*500,rand(1,5000)*500);
%mglFlush;
%mglStencilSelect(0);