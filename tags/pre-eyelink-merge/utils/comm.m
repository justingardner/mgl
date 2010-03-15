function y = comm( op, port, data)

%COMM -- Serial port interface (a MEX file)
%  COMM( 'open', PORT, CONFIG ) opens comm port number PORT for reading and
%    writing. The CONFIG string specifies the basic serial port (baud rate, 
%    parity, #data bits, #stop bits) in standard DOS format. CONFIG defaults 
%    to '19200,n,8,1'.
%
%  STR = COMM( 'readl', PORT, EOL ) reads one line of ASCII text from PORT
%    and returns the line in the string array STR. If a complete line is 
%    not available, STR is empty. If supplied, EOL defines the End-of-Line 
%    character which remains in effect until changed. On open, the EOL 
%    character is the ASCII line-feed (0xA). Non-blocking.
%   
%  DATA = COMM( 'read', PORT, N ) reads upto N bytes from PORT and returns 
%    the uint8 array in DATA. If no data is available, DATA is empty. If N is
%    not specified, all available bytes are returned. Non-blocking.
%   
%  COMM( 'write', PORT, DATA ) writes contents of the matrix DATA to PORT. 
%    The matrix DATA can be of class "double" or "char".
%   
%  COMM( 'purge', PORT ) purges read and write buffers for the PORT.
%	
%  COMM( 'hshake', PORT, HSHAKE ) set hardware 'h' and/or software 's' hand-
%    shaking. 'n' sets handshaking to none.
%	
%  COMM( 'break', PORT ) sends a break.
%	
%  COMM( 'close', PORT ) closes the PORT. 
%
%  COMM( 'status', PORT ) prints some status info. 

% $Id$


disp(sprintf('(comm) Is not compiled on this platform. You will need to download a complied version from the MathWorks site or use a version of Matlab that supports this functions (32 bit intel/G4 matlab)'));
disp(sprintf('http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file'));
keyboard