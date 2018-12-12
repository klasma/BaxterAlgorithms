function ConvexAllBlobs(aBlobs, aImData)
% Replaces the binary regions of a set of Blobs by their convex hulls.
%
% If an added pixel would be in the binary regions of more than one blob,
% it is not included in any of the blobs. No pixels are however removed
% from the original regions. The function can handle both 2D and 3D blobs.
%
% First, the blob regions are replaced by their convex hulls. Then
% conflicting pixels which are present in multiple blob regions are
% removed.
%
% Inputs:
% aBlobs - An array of Blobs objects for which the binary regions should be
%          replaced by their convex hulls.
% aImData - ImageData object of the image sequence.
%
% See also:
% CloseAllBlobs, ConvexBlob

labels = ReconstructSegmentsBlob(aBlobs, aImData.GetSize());
takenPixels = labels > 0;
newTakenPixels = false(aImData.imageHeight, aImData.imageWidth, aImData.numZ);

for i = 1:length(aBlobs)
    addedIndices = ConvexBlob(aBlobs(i), aImData);
    
    % Remove conflicting pixels from the current blob.
    conflictPixels = takenPixels(addedIndices);
    conflictIndices = addedIndices(conflictPixels);
    RemoveBlobPixels(aBlobs(i), conflictIndices, aImData)
    
    % Remove conflicting pixels from previous blobs.
    newConflictPixels = newTakenPixels(addedIndices);
    newConflictIndices = addedIndices(newConflictPixels);
    for j = 1:length(newConflictIndices)
        conflictLabel = labels(newConflictIndices(j));
        if conflictLabel ~= 0
            RemoveBlobPixels(aBlobs(conflictLabel), newConflictIndices(j), aImData)
            labels(newConflictIndices(j)) = 0;
        end
    end
    
    % Add the pixels which were correctly added to the current blob to the
    % label- and taken-images
    okPixels = ~takenPixels(addedIndices);
    okIndices = addedIndices(okPixels);
    labels(okIndices) = i;
    takenPixels(okIndices) = 1;
    newTakenPixels(okIndices) = 1;
end

MoveBlobCentroids(aBlobs)
end