% mglSocketRead: Read data from an opened socket.
%
%        $Id$
%      usage: data = mglSocketRead(s, typeName, [rows, columns, slices])
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Reads data from a socket that was opened by
%             mglSocketCreateClient() or mglSocketCreateServer().
%             Converts raw byte data to a Matlab matrix of the given type
%             and dimensions.
%      usage: data = mglSocketRead(s, typeName, rows, columns, slices)
%             s -- a socket info struct returned from
%                  mglSocketCreateClient() or mglSocketCreateServer()
%             typeName -- a supported Matlab numeric type name, one of:
%                         'uint16', 'uint32', 'double', 'single'.
%             rows -- number of matrix rows, defaults to 1
%             columns -- number of matrix columns, defaults to 1
%             slices -- number of matrix/array/image slices, defaults to 1
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
