function [oBlobs, oRemovedIndices] = OpenAllBlobs(aBlobs, aMask, aImData)
% Applies morphological opening to the binary regions of a set of blobs.
%
% The function will remove blobs for which all pixels disappear in the
% opening.
%
% Inputs:
% aBlobs - Array of Blob objects to which morphological opening will be
%          applied.
% aMask - Neighborhood of the structuring element used for morphological
%         opening. This input can be a cell array with the same size as
%         aBlobs, allowing a separate structuring element to be used for
%         each blob in aBlobs.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oBlobs - Blob objects where morphological opening has been applied.
% oRemovedPixels - Indices of all pixels which have been removed from the
%                  blobs.
%
% See also:
% CloseAllBlobs, OpenBlob, Blob

oBlobs = aBlobs;

oRemovedIndices = [];

for i = 1:length(aBlobs)
    if iscell(aMask)
        mask = aMask{i};
    else
        mask = aMask;
    end
    
    removedIndices = OpenBlob(aBlobs(i), mask, aImData);
    oRemovedIndices = [oRemovedIndices; removedIndices]; %#ok<AGROW>
end

% Remove blobs without pixels.
hasPixels = arrayfun(@(x)any(x.image(:)), oBlobs);
oBlobs = oBlobs(hasPixels);

MoveBlobCentroids(oBlobs)
end