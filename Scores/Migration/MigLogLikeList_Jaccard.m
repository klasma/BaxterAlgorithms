function oList = MigLogLikeList_Jaccard(aBlobSeq)
% Computes migration probabilities using the Jaccard similarity index.
%
% The probability of migration between two blobs is assumed to be the
% Jaccard similarity index of the two blob regions. Only migrations with a
% probability above 0.1 are included in the returned list, and the
% probabilities are thresholded at 0.99. This function can be used to
% compute migration probabilities when the displacements are so small that
% the outlines of a cell always overlap in consecutive images.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains a vector with all Blob
%            objects created through segmentation of frame t.
%
% Outputs:
% oList - N x 5 matrix, where N is the number of returned migrations.
%         The elements of the matrix are:
%    oList(:,1) - Frame count of the first detection in the migration.
%    oList(:,2) - The index of the detection in image oList(:,1).
%    oList(:,3) - The index of the detection in image oList(:,1)+1.
%    oList(:,4) - Log probability of the migration NOT occurring.
%    oList(:,5) - Log probability of the migration occurring.
%
% See also:
% MigrationScores_generic

MIN_PROB = 0.1;
MAX_PROB = 0.99;

oList = [];
for t = 1:length(aBlobSeq)-1
    for i = 1:length(aBlobSeq{t})
        b1 = aBlobSeq{t}(i);
        for j = 1:length(aBlobSeq{t+1})
            b2 = aBlobSeq{t+1}(j);
            jac = Jaccard(b1, b2);
            if jac > MIN_PROB
                p1 = min(jac, MAX_PROB);
                p0 = 1 - p1;
                oList = [oList; t i j log(p0) log(p1)]; %#ok<AGROW>
            end
        end
    end
end