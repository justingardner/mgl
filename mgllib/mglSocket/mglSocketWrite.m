% mglSocketWrite: Write data to one or more opened socket.
%
%        $Id$
%      usage: byteCount = mglSocketWrite(s, data)
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Writes data to a socket that was opened by
%             mglSocketCreateClient() or mglSocketCreateServer(), or an
%             array of these.
%
%             Converts a given Matlab matrix of a supported type to raw
%             bytes for sending.
%
%      usage: byteCount = mglSocketWrite(s, data)
%             s -- a socket info struct returned from
%                  mglSocketCreateClient() or mglSocketCreateServer().
%                  s can also be a struct array of these.
%             data -- a numeric matrix of a supported type, must be one of:
%                     'uint16', 'uint32', 'double', 'single'.
%
%             Returns the number of bytes written to the socket, which
%             depends on the dimensions and type of the given data.
%             When s is an mxn struct array, the result also has size mxn.
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
% % Send and receive a double scalar between them.
% mglSocketWrite(client, 42.42);
% doubleScalar = mglSocketRead(server, 'double')
%
% % Send and receive a uint matrix between them.
% mglSocketWrite(client, randi(10, [2, 3, 5], 'uint32'));
% uintMatrix = mglSocketRead(server, 'uint32', 2, 3, 5)
%
% mglSocketClose(client)
% mglSocketClose(server)
%
