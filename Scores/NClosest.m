function [oRows, oCols, oVals] = NClosest(aA, aN)
% Finds the N nearest neighbors of all cells from a distance matrix.
%
% In the distance matrix, the rows correspond to cells in frame t and
% columns correspond to cells in frame t+1. The values in the matrix are
% the distances between the corresponding cell pairs. The function NClosest
% finds the N lowest values on all rows and columns in the distance matrix
% and returns the corresponding row and column indices. Matrix elements
% that have the lowest value in both a row and a column are not duplicated.
%
% Inputs:
% aA - Distance matrix.
% aN - The number of neighbors to include for each cell.
%
% Outputs:
% aRows - Column vector with row indices.
% aCols - Column vector with column indices.
% aVals - Column vector with distance matrix values.
%
% See also:
% MigrationScores_generic, ViterbiTrackLinking, MinSquareDist

% Binary matrix indicating what elements from aA should be returned.
mask = false(size(aA));

% Add the aN lowest values in each column.
[~, index1] = sort(aA,1);
numRows = min(aN, size(aA,1));
r = index1(1:numRows,:);
c = repmat(1:size(index1,2),numRows,1);
mask(sub2ind(size(mask),r(:),c(:))) = true;

% Add the aN lowest values in each row.
[~, index2] = sort(aA,2);
numCols = min(aN, size(aA,2));
r = repmat((1:size(index2,1))',1,numCols);
c = index2(:,1:numCols);
mask(sub2ind(size(mask),r(:),c(:))) = true;

% Generate output.
[oRows, oCols] = find(mask);
oVals = aA(sub2ind(size(aA), oRows, oCols));
end