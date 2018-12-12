function IndexBlobs(aBlobSeq)
% Sets the indices of blobs to their positions in arrays.
%
% The function can be used to make sure that the indices of blobs in an
% image are unique and that no indices are missing.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains an array of blobs that were
%            created through segmentation of image t.
%
% See also:
% SortBlobs, Blob

for t = 1:length(aBlobSeq)
    for i = 1:length(aBlobSeq{t})
        aBlobSeq{t}(i).index = i;
    end
end
end