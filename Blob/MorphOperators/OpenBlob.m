function oRemovedIndices = OpenBlob(aBlob, aMask, aImData)
% Applies morphological opening to the binary region of a Blob object.
%
% Inputs:
% aBlob - Blob object.
% aMask - Neighborhood of the structuring element used for opening.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% aRemovedIncies - Indices of removed pixels (in the frame of the large
%                  image).
%
% See also:
% OpenAllBlobs, OpenAllBlobsSwitch, CloseBlob, ConvexBlob
%
% TODO: Split blobs with multiple components.

originalIm = aBlob.image;

% The opening operation is implemented as dilation followed by erosion, and
% therefore the image needs to be padded before the opening operator is
% applied to give the correct results at the borders of the image.

% Pad the image.
padding = floor(size(aMask)/2);
if aImData.GetDim == 3 && length(padding) == 2
    % A 3D structuring element with a single z-plane has a size with only 2
    % elements.
    padding = [padding 0];
end
paddedIm = padarray(aBlob.image, padding);

% Close the image.
openedIm = imopen(paddedIm, aMask);

% Remove the padding
if aImData.GetDim() == 2
    aBlob.image = openedIm(...
        padding(1)+1:end-padding(1),...
        padding(2)+1:end-padding(2));
else
    aBlob.image = openedIm(...
        padding(1)+1:end-padding(1),...
        padding(2)+1:end-padding(2),...
        padding(3)+1:end-padding(3));
end

% Compute indices of removed pixels.
if nargout > 0
    bb = aBlob.boundingBox;
    removedPixels = originalIm & ~aBlob.image;
    % The (:) operator after removedPixels is necessary if removedPixels is
    % a row vector, as oRemovedIndices would otherwise be a row vector.
    if aImData.GetDim() == 2
        [y, x] = ind2sub(size(removedPixels), find(removedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        oRemovedIndices = sub2ind(aImData.GetSize(), imY, imX);
    else
        [y, x, z] = ind2sub(size(removedPixels), find(removedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        imZ = z + bb(3) - 0.5;
        oRemovedIndices = sub2ind(aImData.GetSize(), imY, imX, imZ);
    end
end

CropBlobZeros(aBlob)
end