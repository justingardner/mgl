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
function retval = mglSetGammaTable(varargin)

retval = false;

% if we are passed in a table to set, then
% make sure the table length is the right size
% **note** that we should really do this for all
% kinds of inputs to this function, but don't think
% anyone uses any other form
if (nargin == 1) && isnumeric(varargin{1})
  % first get gamma table size
  tableSize = mglPrivateSetGammaTable;
  if isempty(tableSize),return,end
  % check table size
  inputSize = size(varargin{1},1);
  if inputSize ~= tableSize
    disp(sprintf('(mglSetGammaTable) Size of input table (%i) does not match hardwware gamma table size (%i). Interpolating using nearest neighbors - this should make the gamma table act as expected for an %i bit display',inputSize,tableSize,log2(inputSize)));
    multiple = tableSize/inputSize;
    % try to interpolate here
    for iDim = 1:size(varargin{1},2)
      if multiple > 1
	% input table smaller than hardware table
	interpTable(1:tableSize,iDim) = interp1(1:multiple:tableSize,varargin{1}(:,iDim),(1:tableSize)-multiple/2,'nearest','extrap');
      else
	% input table bigger than hardware table
	interpTable(1:tableSize,iDim) = interp1(1:inputSize,varargin{1}(:,iDim),(1:(1/multiple):inputSize),'nearest','extrap');
%	interpTable(1:tableSize,iDim) = interp1(multiple:multiple:tableSize,varargin{1}(:,iDim),(1:tableSize)-multiple/2,'linear','extrap');
      end
    end
    % clamp values to between 0 and 1
    interpTable(interpTable<0) = 0;
    interpTable(interpTable>1) = 1;
    % set table back
    varargin{1} = interpTable;
  end
end

% just call mglPrivateSetGammaTable which actually does everything
retval = mglPrivateSetGammaTable(varargin{:});
