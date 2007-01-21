% mglSetGammaTable.m
%
%        $Id$
%      usage: mglSetGammaTable()
%         by: justin gardner
%       date: 05/27/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set the gamma table
%             set gamma with a function using 9 arguments:
%
%             mglSetGammaTable(redMin,redMax,regGamma,greenMin,greenMax,greenGamma,blueMin,blueMax,blueGamma);
%        
%             for example:
%             mglSetGammaTable(0,1,0.8,0,1,0.9,0,1,0.75);
%             or with a vector of length 9:
%             mglSetGammaTable([0 1 0.8 0 1 0.9 0 1 0.75]);
%
%             or set with a single table for all there colors
%      
%             gammaTable = (0:1/255:1).^0.8;
%             mglSetGammaTable(gammaTable);
%
%             or set all three colors with differnet tables
%
%             redGammaTable = (0:1/255:1).^0.8;
%             greenGammaTable = (0:1/255:1).^0.9;
%             blueGammaTable = (0:1/255:1).^0.75;
%             mglSetGammaTable(redGammaTable,greenGammaTable,blueGammaTable);
%            
%             can also be called with an 3xn table
%
%             gammaTable(1,:) = (0:1/255:1).^0.8;
%             gammaTable(2,:) = (0:1/255:1).^0.9;
%             gammaTable(3,:) = (0:1/255:1).^0.75;
%             mglSetGammaTable(gammaTable);
%
%             can also be called with the structure returned
%             by mglGetGammaTable
%             mglSetGammaTable(mglGetGammaTable);
%
%             Note that the gamma table will be restored to
%             the original after mglClose;