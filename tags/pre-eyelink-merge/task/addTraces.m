% addTrace - initializes task for stimuli programs
%
%      usage: [ task myscreen ] = addTraces( task, myscreen, tracename, [tracename,] [location]);
%        $Id: $
%         by: eric dewitt
%       date: 2009-01-25
%  copyright: (c) 2009 Eric DeWitt (GPL see mgl/COPYING)
%     inputs: task, myscreen, tracename(s)
%    purpose: adds a named trace to the structure specified (defaults to the task)
%
%      usage: addTrace provides a method for safely adding a new trace to either
%             the myscreen structure or a task/phase structure. You can specify one or
%             more trace names which will be added to the myscreen.traceNames struct and
%             added to the specified location with a 'Trace' post-fix. You may sepecify
%             more than one trace at a time, but you may not name a trace myscreen or
%             task--these are reserved words which specify the attachment location of
%             trace.
%
%
%   e.g.
% [task{1}{1} myscreen] = addTraces( task{1}{1}, myscreen, 'myvariable', 'myscreen');
% [task{2} myscreen] = addTraces( task{2}, myscreen, 'myvar', 'myothervar');
%
function [task myscreen] = addTraces( task, myscreen, varargin )
    
    reserved = {'task', 'myscreen'};
    
    if nargin < 3
        help addTraces
        return
    end
    % number of args without the manditory arguments
    nargs = nargin - 2;
    
    % check for use of reserved words as a trace name
    if nargin == 3 & ~isempty(strmatch(varargin{nargs}, reserved))
        % no traces specified
        help addTraces
    elseif isempty(strmatch(varargin{nargs}, reserved, 'exact'))
        % last elements is a trace
        location = 'task';
    else
        % it is a location
        location = varargin{nargs};
        nargs = nargs - 1;
    end
    
    % for each trace passed in
    for nArg = 1:nargs
        
        % get the trace name and it's candidate number
        tracename = varargin{nArg};
        tracenum = myscreen.numTraces + 1;
    
        % add a variable to the specified location
        switch location
            case {'task'}
                if isfield(task, tracename)
                    error(['Attempt to add duplicate trace: ' tracename]);
                end
                task.([tracename 'Trace']) = myscreen.numTraces;
            case {'myscreen'}
                if isfield(myscreen, tracename)
                    error(['Attempt to add duplicate trace: ' tracename]);
                end
                myscreen.([tracename 'Trace']) = myscreen.numTraces;
            otherwise
                error('You can only add a trace to myscreen or a task.\n');
        end
        
        % increment the nymber of traces and the legacy number of traces
        myscreen.numTraces = tracenum;
        if isfield(myscreen, 'stimtrace'), myscreen.stimtrace = tracenum; end
            
        % add the trace name to myscreen
        myscreen.traceNames{myscreen.numTraces} = tracename;
        
    end
    
end