% mglTextSet.m
%
%        $Id$
%      usage: mglTextSet(fontName,fontSize,fontColor,fontVFlip,fontHFlip,fontRotation,fontBold,fontItalic,fontUnderline,fontStrikeThrough)
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set text properties for mglText, to accept defaults
%             pass []
%       e.g.: mglTextSet('Helvetica');
%             mglTextSet([],50,[1 1 1]);
%             mglTextSet('Helvetica',32,[0 0.5 1 1],1,0,30,0,1,0,0)
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextSet('Helvetica',32,[0 0.5 1 1],0,0,0,0,0,0,0);
%mglTextDraw('Hello There',[0 0]);
%mglFlush;
function retval = mglTextSet(fontName,fontSize,fontColor,fontHFlip,fontVFlip,fontRotation,fontBold,fontItalic,fontUnderline,fontStrikeThrough)

% check arguments
if ~any(nargin == [1:10])
  help mglTextSet
  return
end

if exist('fontName') && ~isempty(fontName)
  mglSetParam('fontName',fontName);
end
if exist('fontSize') && ~isempty(fontSize)
  mglSetParam('fontSize',fontSize);
end
if exist('fontColor') && ~isempty(fontColor)
  mglSetParam('fontColor',fontColor);
end
if exist('fontVFlip') && ~isempty(fontVFlip)  
  mglSetParam('fontVFlip',fontVFlip);
end
if exist('fontHFlip') && ~isempty(fontHFlip)
  mglSetParam('fontHFlip',fontHFlip);
end
if exist('fontRotation') && ~isempty(fontRotation)
  mglSetParam('fontRotation',fontRotation);
end
if exist('fontBold') && ~isempty(fontBold)
  mglSetParam('fontBold',fontBold);
end
if exist('fontItalic') && ~isempty(fontItalic)
  mglSetParam('fontItalic',fontItalic);
end
if exist('fontUnderline') && ~isempty(fontUnderline)
  mglSetParam('fontUnderline',fontUnderline);
end
if exist('fontStrikeThrough') && ~isempty(fontStrikeThrough)
  mglSetParam('fontStrikeThrough',fontStrikeThrough);
end
  

