% mglSocketCreateServer: Create a socket and bind an address.
%
%        $Id$
%      usage: socket = mglSocketCreateServer(address, [pollMilliseconds, maxConnections])
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Open a local/unix socket and bind the given address.
%      usage: socket = mglSocketCreateServer(address, [pollMilliseconds, maxConnections])
%             address -- string path to a file to bind as the socket
%                        address where the server will listen.
%             pollMilliseconds -- how long to poll the socket for waiting
%                                 data, when subsequently calling
%                                 mglSocketDataWaiting().  Optional,
%                                 defaults to 10.
%             maxConnections -- how many pending client connections at the
%                               given address that the OS should hold on to
%                               while waiting for the server side to to
%                               accept, with mglSocketAcceptConnection().
%                               Optional, defaults to 500.
%
%             Returns a struct of info about the opened socket, including
%             the given parameters above, and relevant system socket file
%             descriptors.
%
%             Often in MGL we don't need to use this server functionality.
%             The mglMetal app usually binds and listens on a socket, on
%             its end.  This is included here in Matlab so that we can test
%             the Matlab socket code right here in one place.
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
% mglSocketWrite(client, 42.42);
% serverHasDataWaiting = mglSocketDataWaiting(server)
%
% mglSocketClose(client)
% mglSocketClose(server)
%
