function [oBlobSeq, oNumMerged] =...
    MergeOverlappingFP(aCells, aBlobSeq, aMergeThreshold, aDeltaT)
% Merges false positives into cells based on overlap in adjacent frames.
%
% This function can put together parts of a cell which appear to be
% disconnected in an image. This can for example be used to connect the
% cell body to cell extensions that have stretched out so far that the
% extensions are segmented as a separate objects in some frames. The
% regions are connected by merging false positive blobs into cells if they
% overlap enough with a cell region in an adjacent frame. The overlap is
% measured as a fraction of the whole false positive blob. The blob segment
% is merged with the segment of the cell in the frame of the blob. Pixels
% that are closer than 2*sqrt(2) pixels to both of the merged segments are
% be added to the merged region, as they might have been removed by a
% watershed transform. After the function has finished, new blobs can meet
% the merging threshold, so it can be a good idea to call the function
% repeatedly until oNumMerged is 0. The function has been used on the MSC
% dataset of the Cell Tracking Challenges, but it is not very robust and is
% therefore probably not very useful in practice.
%
% Inputs:
% aCells - Array of Cell objects.
% aBlobSeq - Cell array with false positive blobs, which do not belong to
%            a cell track. Cell t contains blobs from frame t.
% aMergeThreshold - Threshold on how much of the blob must overlap with a
%                   cell segment for the blob to be merged.
% aDeltaT - The number of prior and following frames to look for
%           overlapping cells in. This is normally set to 1, so that the
%           overlaps are measured in the previous and next frame. The blobs
%           are merged into the cell with the largest overlap.
%
% Outputs:
% oBlobSeq - Remaining blobs that were not merged into cells.
% oNumMerged - The number of blobs that were merged into cells.
%
% See also:
% MergeFPWatersheds, MergeFPWatersheds3D, MergeBrokenBlobs

oBlobSeq = aBlobSeq;

% Create cell arrays with overlaps and corresponding cell indices. Each
% cell contains an array with one element for each blob in the
% corresponding frame.
overlaps = cell(size(oBlobSeq));
maxIndex = cell(size(oBlobSeq));
for t = 1:length(oBlobSeq)
    overlaps{t} = zeros(size(oBlobSeq{t}));
    maxIndex{t} = zeros(size(oBlobSeq{t}));
end

% Find the maximum overlap for each blob.
for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    for t = c.firstFrame:c.lastFrame
        b = c.GetBlob(t);
        
        % Multiple time shifts.
        for td = max(t-aDeltaT, c.firstFrame) : min(t+aDeltaT, c.lastFrame)
            if td == t
                % Blobs can not overlap in the same frame.
                continue
            end
            for bIndex = 1:length(oBlobSeq{td})
                olap = Overlap(b, oBlobSeq{td}(bIndex)) /...
                    sum(oBlobSeq{td}(bIndex).image(:));
                if olap > overlaps{td}(bIndex)
                    overlaps{td}(bIndex) = olap;
                    maxIndex{td}(bIndex) = cIndex;
                end
            end
        end
    end
end

% Merge the blobs that overlap enough whith the cells.
oNumMerged = 0;
for t = 1:length(oBlobSeq)
    deleteBlobs = false(size(oBlobSeq{t}));
    for bIndex = 1:length(oBlobSeq{t})
        if overlaps{t}(bIndex) > aMergeThreshold
            b = oBlobSeq{t}(bIndex);
            cellBlob = aCells(maxIndex{t}(bIndex)).GetBlob(t);
            % This region can contain many cells, but it has to be altered
            % too.
            if length(b.boundingBox) == 4  % 2D
                CombineBlobs(cellBlob.super, b);
                CombineBlobs(cellBlob, b);
            else  % 3D
                CombineBlobs3D(cellBlob.super, b);
                CombineBlobs3D(cellBlob, b);
            end
            deleteBlobs(bIndex) = true;
            oNumMerged = oNumMerged + 1;
        end
    end
    oBlobSeq{t}(deleteBlobs) = [];
end
end