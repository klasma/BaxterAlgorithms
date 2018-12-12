function oCount = CountCells(aBlobSeq, aCells)
% Counts the number of cells inside blobs.
%
% Inputs:
% aBlobSeq - Cell array of Blob arrays. The cell array has one cell per
%            time point and the cells contain top level blobs from the
%            original segmentation.
% aCells - Array of Cell objects.
%
% Outputs:
% oCount - Cell array of double arrays. The double arrays have the same
%          dimensions as the corresponding Blob arrays and give the number
%          of cells in all blobs.
%
% See also:
% Cell, Blob, Cells2Blobs

% Create cell array with zero matrices.
oCount = cell(size(aBlobSeq));
for bIndex = 1:length(aBlobSeq)
    oCount{bIndex} = zeros(size(aBlobSeq{bIndex}));
end

% Add to zero matrices.
for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    if c.isCell
        for t = c.firstFrame : c.lastFrame
            b = c.GetBlob(t).super;
            oCount{t}(aBlobSeq{t} == b) = oCount{t}(aBlobSeq{t} == b) + 1;
        end
    end
end
end