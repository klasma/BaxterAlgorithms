function oBlobSeq = RemovePointBlobs(aBlobSeq)
% Selects blobs which are not point-blobs.
%
% A point blob is a blob which has no pixel region associated with it. Such
% a blob is defined entirely by its centroid, and cannot be used to train
% classifiers for cell counts and other parameters.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains an array with the blobs in
%            image t.
%
% Outputs:
% oBlobSeq - Cell array of blobs, where the point-blobs have been removed.
%
% See also:
% Blob

oBlobSeq = cell(size(aBlobSeq));
for t = 1:length(aBlobSeq)
    for i = 1:length(aBlobSeq{t})
        if ~any(isnan(aBlobSeq{t}(i).boundingBox))
            oBlobSeq{t} = [oBlobSeq{t} aBlobSeq{t}(i)];
        end
    end
end
end