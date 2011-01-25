% mglEyelinkIsConnected - Checks the connection to the EyeLink computer.
%
%     program: mglEyelinkIsConnected.m
%          by: Christopher Broussard
%        date: 01/22/10
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: Checks the connection to the EyeLink computer.
%
%       Usage: connectionStatus = mglEyelinkIsConnected;
%
%              connectionStatus will be one of the following values:
%              0 if link closed.
%              -1 if simulating connection.
%              1 for normal connection. 
%              2 for broadcast connection (NEW for v2.1 and later).