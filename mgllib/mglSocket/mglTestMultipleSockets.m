% mglTestMultipleSockets.m
%
%        $Id: mglTestMultipleSockets.m
%      usage: mglTestMultipleSockets(socketCount=3, socketDir='/tmp')
%         by: Benjamin Heasly
%       date: 08/24/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test socket connectivity, read, write, data integrity.
%      usage:
%             % It should be a one-liner to run these tests:
%             mglTestMultipleSockets()
%
%             % You want to rebuild the socket functions first.
%             mglMakeSocket()
%             mglTestMultipleSockets()
%
function mglTestMultipleSockets(socketCount, socketDir)

if nargin < 1
    socketCount = 3;
end

if nargin < 2
    socketDir = '/tmp';
end

socketFiles = cell(1, socketCount);
for ii = 1:socketCount
    socketFiles{ii} = fullfile(socketDir, sprintf('test-%d.socket', ii));
    if isfile(socketFiles{ii})
        delete(socketFiles{ii});
    end
end

fprintf('Testing %d sockets at once\n', socketCount);

% Set up a server to bind each socketFile.
serverCell = cell(1, socketCount);
serverCleanups = cell(1, socketCount);
for ii = 1:socketCount
    serverCell{ii} = mglSocketCreateServer(socketFiles{ii});
    serverCleanups{ii} = onCleanup(@() mglSocketClose(serverCell{ii}));
    disp("Created server:")
    disp(serverCell{ii})
    assert(strcmp(serverCell{ii}.address, socketFiles{ii}), 'Server address should be %s but it was %s.', socketFiles{ii}, serverCell{ii}.address);
    assert(serverCell{ii}.boundSocketDescriptor >= 0, 'Server boundSocketDescriptor should be non-negative but it was %d', serverCell{ii}.boundSocketDescriptor);
end

% Set up a client connected to each server;
clientCell = cell(1, socketCount);
clientCleanups = cell(1, socketCount);
for ii = 1:socketCount
    clientCell{ii} = mglSocketCreateClient(socketFiles{ii});
    clientCleanups{ii} = onCleanup(@() mglSocketClose(clientCell{ii}));
    disp("Created client:")
    disp(clientCell{ii})
    assert(strcmp(clientCell{ii}.address, socketFiles{ii}), 'Client address should be %s but it was %s.', socketFiles{ii}, clientCell{ii}.address);
    assert(clientCell{ii}.connectionSocketDescriptor >= 0, 'Client connectionSocketDescriptor should be non-negative but it was %d', clientCell{ii}.connectionSocketDescriptor);
end
clients = [clientCell{:}];

% Complete the server side of each connection.
serverCleanups2 = cell(1, socketCount);
for ii = 1:socketCount
    serverCell{ii} = mglSocketAcceptConnection(serverCell{ii});
    serverCleanups2{ii} = onCleanup(@() mglSocketClose(serverCell{ii}));
    disp("Server accepted connection from client:")
    disp(serverCell{ii})
    assert(serverCell{ii}.connectionSocketDescriptor >= 0, 'Server connectionSocketDescriptor should be non-negative but it was %d', serverCell{ii}.connectionSocketDescriptor);
end
servers = [serverCell{:}];

% Send some random data from all clients to all servers.
rows = 5;
columns = 3;
slices = 2;
originalData = rand([rows, columns, slices], 'double');

fprintf('Sending %d x %d x %d doubles on %d sockets\n', rows, columns, slices, socketCount);

byteCount = zeros(1, socketCount);
receivedData = zeros([rows, columns, slices, socketCount]);

timer = tic();

% TODO: push the loop into the mex-function.
for ii = 1:socketCount
    byteCount(ii) = mglSocketWrite(clients(ii), originalData);
end

dataWaiting1 = mglSocketDataWaiting(servers);

% TODO: push the loop into the mex-function.
for ii = 1:socketCount
    receivedData(:, :, :, ii) = mglSocketRead(servers(ii), 'double', rows, columns, slices);
end

dataWaiting2 = mglSocketDataWaiting(servers);

duration = toc(timer);

assert(all(byteCount > 0), 'All sent byte counts should be positive but at least one was not: %s', num2str(byteCount));
assert(all(dataWaiting1 == 1), 'All servers should see data waiting after write but at least one did not: %s', num2str(dataWaiting1));
for ii = 1:socketCount
    assert(isequal(receivedData(:, :, :, ii), originalData), 'Received data for socket %d was not equal to original data.\nReceived:\n%s\nOriginal:\n%s', ii, num2str(receivedData), num2str(originalData));
end
assert(all(dataWaiting2 == 0), 'Not any servers should see data waiting after read but at least one did: %s', num2str(dataWaiting2));

fprintf('OK (%f seconds)\n', duration);
