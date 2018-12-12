function [oBlobSeq, varargout] = SortBlobs(aBlobSeq, varargin)
% Sorts blobs based on their y-coordinates.
%
% The function takes a cell array where each cell contains an array of
% blobs. The function will sort the blobs in each cell array based on their
% z-coordinates. If multiple blobs have the same z-coordinate, they will be
% sorted based on their y-coordinates and then on the x-coordinates. The
% function can also be used to apply the orderings of the blob arrays to
% other arrays with the same dimensions as the blob arrays.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains blobs created through
%            segmentation of frame t.
% varargin - Cell arrays with the same length as aBlobSeq. Each element of
%            the cell arrays should contain an array of the same length as
%            the corresponding blob array in aBlobSeq. The arrays may
%            contain elements of any type.
%
% Outputs:
% oBlobSeq - Cell array where each cell contains an ordered blob array.
% varargout - Cell arrays where the cells contain the array elements from
%             varargin, placed in the same orders as the blobs in oBlobSeq.
%
% See also:
% Blob

% Allocate a cell array for the output blobs.
oBlobSeq = cell(size(aBlobSeq));

% Allocate cell arrays for the other outputs.
varargout = cell(size(varargin));
for i = 1:length(varargin)
    varargout{i} = cell(size(varargin{i}));
end

for t = 1:length(aBlobSeq);
    if isempty(aBlobSeq{t})
        continue
    end
    
    % Matrix where the first column contains x-coordinates and the second
    % column contains y-coordinates.
    val = cat(1, aBlobSeq{t}.centroid);
    
    % First sort the blobs based on they x-coordinates and then perform a
    % new sort on the y-coordinates. The sorting function will maintain the
    % order of elements with the same value and thereby blobs with the same
    % y-coordinate will be in the right order from the first sort. For 3D
    % data, a third sort is done on the z-coordiante.
    [~, orderX] = sort(val(:,1));
    [~, orderY] = sort(val(orderX,2));
    if size(val,2) == 2
        order = orderX(orderY);
    else
        [~, orderZ] = sort(val(orderX(orderY),3));
        order = orderX(orderY(orderZ));
    end
    
    % Apply the order to the blobs.
    oBlobSeq{t} = aBlobSeq{t}(order);
    
    % Apply the order to the other inputs.
    for i = 1:length(varargin)
        varargout{i}{t} = varargin{i}{t}(order);
    end
end
end