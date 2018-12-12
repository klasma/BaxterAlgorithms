function oBlobSeq = FalseBlobs(aBlobSeq, aCells)
% Finds all blobs in an image sequence that are not associated with a cell.
%
% Inputs:
% aBlobSeq - Cell array with blob objects. Cell t contains an array with
%            all blobs in frame t.
% aCells - The biological cells of the image sequence.
%
% Outputs:
% oBlobSeq - Cell array with the blobs objects that are not associated with
%            any biological cell. The cell array has the same format as
%            aBlobSeq.
%
% See also:
% Blob, Cell, Cells2Blobs

oBlobSeq = cell(size(aBlobSeq));
cellCount = CountCells(aBlobSeq, aCells);
for t = 1:length(aBlobSeq)
    % Take the blobs with 0 cells associated with them.
    oBlobSeq{t} = aBlobSeq{t}(cellCount{t} == 0);
end
end