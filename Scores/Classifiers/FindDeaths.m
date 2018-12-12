function oDeaths = FindDeaths(aBlobSeq, aCells)
% Finds blobs where cells die, in cell arrays of blobs.
%
% Inputs:
% aBlobSeq - Cell array where cell i contains blobs that were created
%            through segmentation of frame i. The blobs should be
%            super-blobs of the blobs associated with the cells in aCells.
% aCells - Array of Cell objects for which death events will be detected.
%          The super-blobs of the blobs associated with these cells should
%          be in aBlobSeq.
%
% Outputs:
% oDeaths - Cell array with the same size as aBlobSeq. Every cell contains
%           a binary array which represents death events in blobs. If
%           oDeaths{i}(j) is true, it means that a cell dies in the blob
%           aBlobSeq{i}(j).
%
% See also:
% FindSplints, DataSet

    % Create a cell array containing false-arrays of the correct sizes.
    oDeaths = cell(length(aBlobSeq), 1);
    for t = 1:length(aBlobSeq)
        oDeaths{t} = false(1,length(aBlobSeq{t}));
    end
    
    % Change the false values to true for blobs where cells die.
    for i = 1:length(aCells)
        c = aCells(i);
        if c.isCell && c.died
            bool = aBlobSeq{c.lastFrame} == c.blob(end).super;
            oDeaths{c.lastFrame}(bool) = true;
        end
    end
end