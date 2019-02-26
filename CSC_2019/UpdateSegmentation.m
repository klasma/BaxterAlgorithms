function UpdateSegmentation(aCells, aImData)
% Break clusters in all images without changing assignments.
%
% This function is equivalent to BipartiteMatch, when no assignments are
% changed. This function is only meant for development.
%
% Inputs:
% aCells - Array of Cell objects where multiple cells can be assigned to
%          the same outline (a cluster).
% aImData - ImageData object associated with the image sequence.
%
% See also:
% BipartiteMatch, BreakClusters, Cell, Blob
%
% Comments are up to date.

if isempty(aCells)
    return
end

blobSeq = Cells2Blobs(aCells, aImData);  % Blobs from segmentation.
for t = 1 : aImData.sequenceLength
    fprintf('Breaking clusters in frame %d / %d.\n',...
        t, aImData.sequenceLength)
    BreakClusters(aCells, blobSeq{t}, t, aImData)
end
end