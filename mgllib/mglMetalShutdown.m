% mglMetalShutdown: Shutdown any running mglMetal applications
%
%        $Id$
%      usage: mglMetalShutdown
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Shutsdown any running mglMetal applications. Returns true if
%             there were mglMetal applications to shutdown
%      usage: mglMetalShutdown()
function tf = mglMetalShutdown

% get psid
[tf, psid] = mglMetalIsRunning;
if ~tf
  fprintf('(mglMetalShutdown) No mglMetal process is running\n');
  return
end

% shutdown
fprintf(sprintf('(mglMetalShutdown) Shutting down mglMetal process: %i',psid),0);
system(sprintf('kill -9 %i',psid));

% isRunning
while(mglMetalIsRunning)
  fprintf('.',0);
end
fprintf('\n',0);
