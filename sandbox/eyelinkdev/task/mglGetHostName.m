% mglGetHostName.m
%
%      usage: mglGetHostName()
%         by: justin gardner
%       date: 07/18/09
%    purpose: Gets the name of the computer that we are running on
%
function hostname = mglGetHostName()

retval = '';
% check arguments
if ~any(nargin == [0])
  help mglGetHostName
  return
end

[retval hostname] = system('hostname');
% sometimes there is more than one line (errors from csh startup)
% so need to strip those off
hostname = strread(hostname,'%s','delimiter','\n');
hostname = hostname{end};
if (retval == 0)
  % get it again
  [retval hostname2] = system('hostname');
  hostname2 = strread(hostname2,'%s','delimiter','\n');
  hostname2 = hostname2{end};
  if (retval == 0)
    % find the matching last characers
    % this is necessary, because matlab's system command
    % picks up stray key strokes being written into
    % the terminal but puts those at the beginning of
    % what is returned by stysem. so we run the
    % command twice and find the matching end part of
    % the string to get the hostrname
    minlen = min(length(hostname),length(hostname2));
    for k = 0:minlen
      if (k < minlen)
	if hostname(length(hostname)-k) ~= hostname2(length(hostname2)-k)
	  break
	end
      end
    end
    if (k > 0)
      hostname = hostname(length(hostname)-k+1:length(hostname));
      hostname = lower(hostname);
      hostname = hostname(find(((hostname <= 'z') & (hostname >= 'a')) | '.'));
    else
      hostname = 'unknown';
    end
  else
    hostname = 'unknown';
  end
else
  hostname = 'unknown';
end

