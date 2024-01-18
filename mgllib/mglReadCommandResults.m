% Read a uniform struct array of results from some Mgl Metal commands.
%
% Inputs:
%
%   socketInfo:     array of socket info structs as from
%                   mglSocketCreateClient() or mgl.activeSockets
%   ackTime:        optional array of ack times previously collected
%                   from from Mgl Metal, to include with other results.
%   setupTime:      optional array of setup times previously collected, to
%                   include with other results.
%   commandCount:   optional number of processed commands expected from Mgl
%                   Metal -- defaults to 1 but may be more following a
%                   command batch.
%
% Output:
%
%   results:        struct array with fields describing command results
%                   including: 
%                       - ackTime: an element of the given ackTime
%                       - setupTime: an element of the given setupTime
%                       - processedTime: completion timestamp reported by
%                         Mgl Metal, negative on error
%
%                   The results struct array will have one element per
%                   command and per socket, ie size will be
%                   [commandCount, numel(socketInfo)]
%
% This function only reads generic results that Mgl Metal returns for all
% commands, including command code, success or failure status, and several
% timestamps.
%
% This function does not read command-specific query results.  Individual
% commands that expect query results should read those first, before
% calling this function to read in the generic results.
%
% One goal of this function is to present Mgl Metal command results in a
% consistent format across different situations including single command
% executions, batches of commands, and connections to multiple Mgl Metal
% instances.
%
% Another goal is to make it easier to make changes in how Mgl Metal
% reports command results.  Instead of having to modify every Matlab
% function that talks to Mgl Metal, we should only have to modify this
% function to reflect the modified results in its struct array format.
function results = mglReadCommandResults(socketInfo, ackTime, setupTime, commandCount)

if nargin < 4 || isempty(commandCount)
    commandCount = 1;
end

if nargin < 3 || isempty(setupTime)
    setupTime = 0;
end

if nargin < 2 || isempty(ackTime)
    ackTime = 0;
end

% Read results one field at a time, across all commands and sockets.

% command code uint16
% status uint16
processedTime = mglSocketRead(socketInfo, 'double', commandCount);
% other timestamps

% Deal results to a struct array of size [commandCount, numel(socketInfo)].
% mglSocketRead represents socket index as the 4th matrix dimension, to
% accommodate results with up to 3 data dimensions.  Here we are
% expecting all scalar timestamps, so we can squeeze out any middle
% dimensions.
resultSize = [commandCount, numel(socketInfo)];
results = struct( ...
    'ackTime', sizeForStruct(ackTime, resultSize), ...
    'setupTime', sizeForStruct(setupTime, resultSize), ...
    'processedTime', sizeForStruct(processedTime, resultSize));

% Convert x to something we can pass to struct():
%   - a cell array of the expected size
%   - a scalar that can be automatically expanded
function x = sizeForStruct(x, resultSize)
if numel(x) == 1
    return
end
x = num2cell(reshape(x, resultSize));