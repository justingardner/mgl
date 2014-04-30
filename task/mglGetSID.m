% mglGetSID.m
%
%        $Id:$ 
%      usage: mglGetSID()
%         by: justin gardner
%       date: 04/30/14
%    purpose: Gets whatever SID has been set by mglSetSID
%
function sid = mglGetSID()

% check arguments
if ~any(nargin == [0])
  help mglGetSID
  return
end

% get default interval for which sid is valid
validInterval = mglGetParam('sidValidIntervalInHours');
if isempty(validInterval)
  validInterval = 1;
end

% set if there is an SID and what time it was set
sid = mglGetParam('sid');
if ~isempty(sid)
  validUntil = mglGetParam('sidValidUntil');
  if (now > validUntil)
    disp(sprintf('(mglGetParam) SID set to %s is no longer valid since it has not been reset for %f hours. If you want to allow sids to be valid for longer, then mglSet sidValidIntervalInHours',sid,validInterval));
    sid = [];
    mglSetParam('sid',[]);
  else
    % still valid, make it valid for another interval
    nowvec = datevec(now);
    nowvec(4) = nowvec(4)+floor(validInterval);
    nowvec(5) = round(nowvec(5)+(validInterval-floor(validInterval))*60);
    validUntil = datenum(datestr(nowvec));
    mglSetParam('sidValidUntil',validUntil);
  end
end

