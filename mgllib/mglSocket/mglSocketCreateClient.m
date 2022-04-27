% mglSocketCreateClient: Create a socket and connect to an address.
%
%        $Id$
%      usage: socket = mglSocketCreateClient(address, [pollMilliseconds, maxConnections])
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Open a local/unix socket and connect to the given address.
%      usage: socket = mglSocketCreateClient(address, [pollMilliseconds])
%             address -- string path to a file to connect to as a socket
%                        address, where a server is bound and listening.
%             pollMilliseconds -- how long to poll the socket for waiting
%                                 data, when subsequently calling
%                                 mglSocketDataWaiting().  Optional,
%                                 defaults to 10.
%
%             Returns a struct of info about the opened socket, including
%             the given parameters above, and relevant system socket file
%             descriptors.
%
% % Create a client and server that can talk over sockets.
% socketFile = '/tmp/test.socket';
% if isfile(socketFile)
%     delete(socketFile);
% end
%
% server = mglSocketCreateServer(socketFile);
% client = mglSocketCreateClient(socketFile);
% server = mglSocketAcceptConnection(server);
% 
% % Send some data, then we see it waiting.
% mglSocketWrite(server, 42.42);
% clientHasDataWaiting = mglSocketDataWaiting(client)
%
% mglSocketClose(client)
% mglSocketClose(server)
%
