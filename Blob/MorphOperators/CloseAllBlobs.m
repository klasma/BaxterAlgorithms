function CloseAllBlobs(aBlobs, aMask, aImData)
% Applies morphological closing to the binary regions of a set of Blobs.
%
% If an added pixel would be in the binary regions of more than one blob,
% it is not included in any of the blobs. No pixels are however removed
% from the original regions. The function can handle both 2D and 3D blobs.
%
% First, the blob regions are closed using the normal a morphological
% closing operator. Then conflicting pixels which are present in multiple
% blob regions are removed.
%
% Inputs:
% aBlobs - An array of Blobs objects for which the binary regions should be
%          closed.
% aMask - The neighborhood of the structuring element which will be used by
%         the morphological closing operation.
% aImData - ImageData object of the image sequence.
%
% See also:
% ConvexAllBlobs, CloseBlob

% Label image which will be updated as the blob regions are closed.
labels = ReconstructSegmentsBlob(aBlobs, aImData.GetSize());
% Pixels which are taken by blobs. This matrix is updated as blob regions
% are closed.
takenImage = labels > 0;
% Pixels which are taken by blobs, but which were not taken by blobs before
% the closing operations were performed. The matrix is updated as blob
% regions are closed.
newtakenImage = false(aImData.imageHeight, aImData.imageWidth, aImData.numZ);

for i = 1:length(aBlobs)
    addedIndices = CloseBlob(aBlobs(i), aMask, aImData);
    
    % Remove conflicting pixels from the current blob.
    conflictIndices = addedIndices(takenImage(addedIndices));
    RemoveBlobPixels(aBlobs(i), conflictIndices, aImData)
    
    % Remove conflicting pixels from previous blobs.
    newConflictIndices = addedIndices(newtakenImage(addedIndices));
    for j = 1:length(newConflictIndices)
        conflictLabel = labels(newConflictIndices(j));
        if conflictLabel ~= 0
            RemoveBlobPixels(aBlobs(conflictLabel), newConflictIndices(j), aImData)
            labels(newConflictIndices(j)) = 0;
        end
    end
    
    % Add the pixels which were correctly added to the current blob to the
    % label- and taken-images
    okPixels = ~takenImage(addedIndices);
    okIndices = addedIndices(okPixels);
    labels(okIndices) = i;
    takenImage(okIndices) = 1;
    newtakenImage(okIndices) = 1;
end

MoveBlobCentroids(aBlobs)
end