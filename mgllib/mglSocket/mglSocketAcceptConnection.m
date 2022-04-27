% mglSocketAcceptConnection: As a server, accept a pending client connection.
%
%        $Id$
%      usage: s = mglSocketAcceptConnection(s)
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Accept a pending client connection, at a bound server socket.
%      usage: s = mglSocketAcceptConnection(s)
%             s -- a socket info struct returned from
%                  mglSocketCreateServer()
%
%             Accepts an incoming socket connection from a client.  The
%             given s should be a socket info struct that was previously
%             created using mglSocketCreateServer().  Such sockets are
%             bound to addresses and listening for incoming connections.
%
%             Clients can then request connections to the bound socket, as
%             with mglSocketCreateClient().  The operating system will
%             queue up these pending connections in the background.  The
%             value of maxConnections passed to mglSocketCreateServer()
%             determines how many pending connections are allowed before
%             new ones get dropped.
%
%             After accepting a pending connection, this returns an updated
%             version of the socket info struct s, with a new system socket
%             descriptor for the server side of the connection.
%
%             Often in MGL we don't need to use this server functionality.
%             The mglMetal app usually socket connections on its end.
%             This is included here in Matlab so that we can test
%             the Matlab socket code right here in one place.
%
%
% % Bind an address as a server.
% socketFile = '/tmp/test.socket';
% if isfile(socketFile)
%     delete(socketFile);
% end
% server = mglSocketCreateServer(socketFile);
%
% % Connect to the same address as a client.
% client = mglSocketCreateClient(socketFile);
%
% % Accept the client's pending connection, now able to read and write.
% server = mglSocketAcceptConnection(server)
% 
% % Clean up!
% mglSocketClose(client);
% mglSocketClose(server);
%
