function [oBlobSeq, oCount] = Cells2Blobs(aCells, aImData, varargin)
% Creates a cell array with blob objects from a vector of cells.
%
% The output blobs can either be the actual cell blobs or the segmented
% blobs where clustered cells may be associated with the same blob. The
% function can also count the number of cells that are contained within
% each blob.
%
% Inputs:
% aCells - Array of cells to take blobs from.
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% Sub - If this parameter is set to true, the cell blobs, where clusters
%       have been broken, are returned. Otherwise, the original blobs from
%       the segmentation are returned.
%
% Outputs:
% oBlobSeq - Cell array with blobs from the cells in aCell. There is an
%            element for each time-point, which contains an array of blobs
%            from that time-point.
% oCounts - Cell array with cell counts for all blobs. If the blob is a
%           false positive, the cell count is 0. The cell array has the
%           same structure as oBlobSeq and instead of arrays with blob
%           objects, the elements contain double arrays with the
%           corresponding cell counts.
%
% See also:
% Blob, Cell, SegmentSequence

% Get property/value inputs.
aSub = GetArgs({'Sub'}, {false}, true, varargin);

oBlobSeq = cell(aImData.sequenceLength, 1);
oCount = cell(aImData.sequenceLength, 1);

if isempty(aCells)
    return
end

for i = 1:length(aCells)
    ce = aCells(i);
    
    if ~aSub
        superBlobs = [ce.blob.super];
    else
        superBlobs = [ce.blob];
    end
    
    for frame = ce.firstFrame : ce.lastFrame
        b = superBlobs(frame - ce.firstFrame + 1); % faster than GetBlob
        index = find(oBlobSeq{frame} == b);
        if isempty(index)
            % The blob has not been added to the output.
            oBlobSeq{frame} = [oBlobSeq{frame} b];
            if ce.isCell
                oCount{frame} = [oCount{frame} 1];
            else
                oCount{frame} = [oCount{frame} 0];
            end
        elseif ce.isCell
            % The blob has been added to the output. We only need to
            % increase the count.
            oCount{frame}(index) = oCount{frame}(index) + 1;
        end
    end
end

% Ensures that the blobs are in the same order no matter how they are
% created.
[oBlobSeq, oCount] = SortBlobs(oBlobSeq, oCount);
end