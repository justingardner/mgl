% mglSocketDataWaiting: Check if data is available to read on a socket.
%
%        $Id$
%      usage: isDataWaiting = mglSocketDataWaiting(s)
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Checks if bytes are available to read from one or more
%             sockets opened by mglSocketCreateClient()
%             or mglSocketCreateServer().
%      usage: isDataWaiting = mglSocketDataWaiting(s)
%             s -- a socket info struct returned from
%                  mglSocketCreateClient() or mglSocketCreateServer().
%                  s can also be a struct array of these.
%
%             Returns whether or not bytes are available to read from the
%             given socket or sockets:
%                 1.0 means bytes are available
%                 0.0 means zero bytes available
%                 -1.0 means some error occurred for this socket.
%             When s is an mxn struct array, the return array has size mxn.
%
%             This check will poll the given socket or sockets for up to
%             some number of miliseconds before returning false.  The
%             polling time comes from s.pollMilliseconds and can be
%             specified when calling mglSocketCreateClient() or
%             mglSocketCreateServer().
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
% % At first, no data waiting.
% dataAtFirst = mglSocketDataWaiting(server)
%
% % Once we send some data, then we see it waiting.
% mglSocketWrite(client, 42.42);
% dataAfterSend = mglSocketDataWaiting(server)
%
% mglSocketClose(client)
% mglSocketClose(server)
%
