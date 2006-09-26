% writeDigPort.m
%
%        $Id$
%      usage: retval = writeDigPort(val);
%         by: justin gardner
%       date: 09/21/06
%    purpose: write an ouput to the National Instruments board
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%             this writes to "port2" on the board
%
%             Note that
%             in the distribution, writeDigPort is not compiled.
%             It always returns 0. To use it to read your NI card, you
%             will need to mex readDigPort.c, this requires
%             you to install the NI-DAQmx Base Frameworks from:
%             http://sine.ni.com/nips/cds/view/p/lang/en/nid/14480
function retval = writeDigPort(portNum)

retval = 0;

