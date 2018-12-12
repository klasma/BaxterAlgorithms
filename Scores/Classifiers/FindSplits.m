function oSplits = FindSplits(aBlobSeq, aCells)
% Finds blobs where cells divide, in cell arrays of blobs.
%
% Inputs:
% aBlobSeq - Cell array where cell i contains blobs that were created
%            through segmentation of frame i. The blobs should be
%            super-blobs of the blobs associated with the cells in aCells.
% aCells - Array of Cell objects for which cell divisions (mitotic events)
%          will be detected. The super-blobs of the blobs associated with
%          these cells should be in aBlobSeq.
%
% Outputs:
% oSplits - Cell array with the same size as aBlobSeq. Every cell contains
%           a binary array which represents cell divisions in blobs. If
%           oSplits{i}(j) is true, it means that a cell divides in the blob
%           aBlobSeq{i}(j).
%
% See also:
% FindDeaths, DataSet

    % Create a cell array containing false-arrays of the correct sizes.
    oSplits = cell(length(aBlobSeq), 1);
    for t = 1:length(aBlobSeq)
        oSplits{t} = false(1,length(aBlobSeq{t}));
    end
    
    % Change the false values to true for blobs where cells divide.
    for i = 1:length(aCells)
        c = aCells(i);
        if c.isCell && c.divided
            bool = aBlobSeq{c.lastFrame} == c.blob(end).super;
            oSplits{c.lastFrame}(bool) = true;
        end
    end
end