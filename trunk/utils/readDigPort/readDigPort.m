% readDigPort.m
%
%        $Id$
%      usage: readDigPort
%         by: justin gardner
%       date: 09/21/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: read the National Instruments board digital input.
%             this reads form "port1" on the board. 
%
%             Note that
%             in the distribution, readDigPort is not compiled.
%             It always returns 0. To use it to read your NI card, you
%             will need to mex readDigPort.c, this requires
%             you to install the NI-DAQmx Base Frameworks from:
%             http://sine.ni.com/nips/cds/view/p/lang/en/nid/14480
function retval = readDigPort(portNum)

retval = 0;
