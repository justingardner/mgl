clear;
clc;

mglMakeSocket();

%%
mglSetParam('verbose', 1);

socketFile = '/Users/benjaminheasly/test.socket';
delete(socketFile);

serverInfo = mglSocketCreateServer(socketFile);
clientInfo = mglSocketCreateClient(socketFile);
serverInfo = mglSocketAcceptConnection(serverInfo);

clientSent = mglSocketWrite(clientInfo, eye(4));
serverWaiting = mglSocketDataWaiting(serverInfo);
serverRead = mglSocketRead(serverInfo, 'double', 4, 4);
disp(serverRead)

serverSent = mglSocketWrite(serverInfo, uint16(1:10));
clientWaiting = mglSocketDataWaiting(clientInfo);
clientRead = mglSocketRead(clientInfo, 'uint16', 1, 10);
disp(clientRead)

serverInfo = mglSocketClose(serverInfo);
clientInfo = mglSocketClose(clientInfo);
