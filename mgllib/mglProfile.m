% mglProfile Profile how long something takes in mgl
%
%      usage: mglProfile
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Profile how long something takes in mgl.
%      usage: % turn on profiling
%             mglProfile('on');
%             % start profiling
%             mglProfile('start');
%             % do stuff you want to profileEndTime
%             ...
%             % stop profiling and print how long it took
%             mglProfile('stop');
%             % turn off profiling
%             mglProfile('off');
%
function mglProfile(command,profileName)

global mgl

if strcmp(command,'on')
    % turn profiling on
    mglProfile('start');
    mglSocketWrite(mgl.s, mgl.command.mglProfileon);
    mglSetParam('profile',true);
    mglProfile('end','mglProfileOn');
elseif strcmp(command,'off')
    % turn profiling off
    mglSocketWrite(mgl.s, mgl.command.mglProfileoff);
    mglSetParam('profile',false);
elseif strcmp(command,'start')
    mgl.profileStartTime = mglGetSecs;
elseif strcmp(command,'stop')
    if ~mgl.profile, return, end

    % get the end time
    profileEndTime = mglSocketRead(mgl.s, 'double');

    % and display it
    disp(sprintf('(mglProfile) Profile time for %s is: %f ms',profileName,(profileEndTime-mgl.profileStartTime)*1000));
end
