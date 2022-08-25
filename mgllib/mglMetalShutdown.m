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

[tf, pids] = mglMetalIsRunning;
if ~tf
    fprintf('(mglMetalShutdown) No mglMetal process is running\n');
    return
end

% Shut down all matching processes found.
for pid = pids
    fprintf(sprintf('(mglMetalShutdown) Shutting down mglMetal process: %i', pid),0);
    system(sprintf('kill -9 %i', pid));
end

% Wait for the processes to actually stop.
while(mglMetalIsRunning)
    fprintf('.',0);
end
fprintf('\n',0);

% Clean up socket files, which have random names and could proliferate.
global mgl
if ~isempty(mgl) && isfield(mgl, 's') && isfile(mgl.s.address)
    delete(mgl.s.address);
end
