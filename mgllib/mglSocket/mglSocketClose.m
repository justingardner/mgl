% mglSocketClose: Close a socket.
%
%        $Id$
%      usage: s = mglSocketClose(s)
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Close a local/unix socket.
%      usage: s = mglSocketClose(s)
%             s -- a socket info struct returned from
%                  mglSocketCreateClient() or mglSocketCreateServer()
%
%             Returns an updated version of the given socket info struct,
%             with the system socket file descriptors updated to -1 to
%             indicate the sockets are closed.
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
% % Close them!
% mglSocketClose(client)
% mglSocketClose(server)
%
