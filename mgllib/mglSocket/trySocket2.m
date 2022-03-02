clear;
clc;

mglMakeSocket();

%%
mglSetParam('verbose', 1);

socketFile = '/tmp/test.socket';
delete(socketFile);

serverInfo = mglSocketCreateServer(socketFile);
clientInfo = mglSocketCreateClient(socketFile);
serverInfo = mglSocketAcceptConnection(serverInfo);

n = 2049;
data = zeros(1, n, 'single');

clientSent = mglSocketWrite(clientInfo, data);
serverWaiting = mglSocketDataWaiting(serverInfo);
serverRead = mglSocketRead(serverInfo, 'single', 1, n);

serverInfo = mglSocketClose(serverInfo);
clientInfo = mglSocketClose(clientInfo);
