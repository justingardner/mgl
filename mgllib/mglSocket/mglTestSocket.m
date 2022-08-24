% mglTestSocket.m
%
%        $Id: mglTestSocket.m
%      usage: mglTestSocket(socketFile='/tmp/test.socket')
%         by: Benjamin Heasly
%       date: 03/02/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test socket connectivity, read, write, data integrity.
%      usage:
%             % It should be a one-liner to run these tests:
%             mglTestSocket()
%
%             % You want to rebuild the socket functions first.
%             mglMakeSocket()
%             mglTestSocket()
%
function mglTestSocket(socketFile)

if nargin < 1
    socketFile = '/tmp/test.socket';
end

if isfile(socketFile)
    delete(socketFile);
end

disp("Testing sockets...")

% Set up a server and bind the socketFile.
server = mglSocketCreateServer(socketFile);
serverCleanup = onCleanup(@() mglSocketClose(server));
disp("Created server:")
disp(server)
assert(strcmp(server.address, socketFile), 'Server address should be %s but it was %s.', socketFile, server.address);
assert(server.boundSocketDescriptor >= 0, 'Server boundSocketDescriptor should be non-negative but it was %d', server.boundSocketDescriptor);

% Set up a client connected to the server;
client = mglSocketCreateClient(socketFile);
clientCleanup = onCleanup(@() mglSocketClose(client));
disp("Created client:")
disp(client)
assert(strcmp(client.address, socketFile), 'Client address should be %s but it was %s.', socketFile, client.address);
assert(client.connectionSocketDescriptor >= 0, 'Client connectionSocketDescriptor should be non-negative but it was %d', client.connectionSocketDescriptor);

% Complete the server side of the connection.
server = mglSocketAcceptConnection(server);
serverCleanup2 = onCleanup(@() mglSocketClose(server));
disp("Server accepted connection from client:")
disp(server)
assert(server.connectionSocketDescriptor >= 0, 'Server connectionSocketDescriptor should be non-negative but it was %d', server.connectionSocketDescriptor);

% Send and receive supported types in both directions.
assertReceivedIntegrity(client, server, 'uint16');
assertReceivedIntegrity(client, server, 'uint32');
assertReceivedIntegrity(client, server, 'single');
assertReceivedIntegrity(client, server, 'double');

assertReceivedIntegrity(server, client, 'uint16');
assertReceivedIntegrity(server, client, 'uint32');
assertReceivedIntegrity(server, client, 'single');
assertReceivedIntegrity(server, client, 'double');

disp("...Sockets tests passed OK!")

% Send and receive a bunch of random data and check received integrity.
%
% A point about testing data size:
%
% In testing I (BSH) found the OS exerted backpressure and blocked the
% sender (ie Matlab froze) when writing any more than 8192 bytes at once.
% This is problably the macOS Unix socket buffer size.
% 
% This should only be an issue for testing, where we're trying to read and
% write from a single thread/process.  In "real life" the receiver could be
% reading concurrently from its own process, allowing the sender to keep on
% writing.
function assertReceivedIntegrity(sender, receiver, typeName)
elements = 8192 / 8;
rows = randi(32);
columns = randi(32);
slices = floor(elements / (rows * columns));
if (strcmp(typeName, 'uint16') || strcmp(typeName, 'uint32'))
    originalData = randi(2^16-1, [rows, columns, slices], typeName);
else
    originalData = rand([rows, columns, slices], typeName);
end

fprintf('Sending %d x %d x %d %s data...', rows, columns, slices, typeName);

timer = tic();
byteCount = mglSocketWrite(sender, originalData);
dataWaiting = mglSocketDataWaiting(receiver);
receivedData = mglSocketRead(receiver, typeName, rows, columns, slices);
duration = toc(timer);

assert(byteCount > 0, 'Sent byte count should be positive but it was %d.', byteCount);
assert(dataWaiting, 'Receiver should see data waiting but it did not.');
assert(isequal(receivedData, originalData), 'Received data was not equal to original data.\nReceived:\n%s\nOriginal:\n%s', num2str(receivedData), num2str(originalData));
assert(~mglSocketDataWaiting(receiver), 'Receiver should no longer have data waiting, but it does.');

fprintf('OK (%d bytes %f seconds)\n', byteCount, duration);
