% readDigPort.m
%
%        $Id$
%      usage: readDigPort(<portNum>)
%         by: justin gardner
%       date: 09/21/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: read the National Instruments board digital input.
%             portNum defaults to 1, to read from Dev1/port1.
%             The first time you read it needs to open the port to 
%             the NI device which can take some time. Subsequent calls
%             will be faster. Note that you can only open one port at
%             a time, so if you need to read from two different ports
%             it will always be closing and reopening the ports which 
%             will cause a performance hit (consider rewriting the code
%             to keep multiple ports open if you need this). Also,
%             if you want to switch between reading and writing on
%             a single port, you will need to manually close the port
%             in between read/write calls by setting portNum = -1 (see below).
%
%             portNum can also be set to:
%               -1 : closes any open port
%               -2 : displays which port (if any) is open.
%
%             Note that:
%             in the distribution, readDigPort is not compiled.
%             It always returns 0. To use it to read your NI card, you
%             will need to mex readDigPort.c, this requires
%             you to install the NI-DAQmx Base Frameworks from:
%             http://sine.ni.com/nips/cds/view/p/lang/en/nid/14480
function retval = readDigPort(portNum)

retval = 0;
