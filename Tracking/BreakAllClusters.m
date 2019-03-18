function BreakAllClusters(aCells, aBlobSeq, aImData)
% Breaks clusters into individual cell regions in all frames.
%
% BreakAllClusters breaks the blobs of cell clusters into fragments so that
% each cell gets its own blob. The clusters are broken using k-means
% clustering of the coordinates of the pixels/voxels, with random seeding.
% The resulting fragments are assigned to the cells in the clusters so that
% the sum of the squared distances to the cell positions in the following
% frame is minimized. The frames are processed in reverse order, so that
% the positions in the following frame are known to be final when the
% assignments are made. The function is meant to be used instead of
% BipartiteMatch for image sequences where bipartite matching cannot be
% performed.
%
% Inputs:
% aCells  - Cells for which the blobs should be updated. It is important
%           that either all or none of the cells in a blob are included, so
%           that the blobs are broken into the correct number of fragments.
% aBlobs  - Cell array with one cell per frame, where each cell contains an
%           array of blobs that have been segmented in the corresponding
%           frame.
% aImData - ImageData object for the image sequence.
%
% See also:
% BreakClusters, KMeansSplit, BipartiteMatch, BipartiteMatch_correction,
% ViterbiTrackLinking, Cell, Blob

for t = aImData.sequenceLength : -1 : 1
    fprintf('Breaking clusters in frame %d\n', t)
    BreakClusters(aCells, aBlobSeq{t}, t, aImData)
end