function oAddedIndices = CloseBlob(aBlob, aMask, aImData)
% Applies morphological closing to the binary region of a Blob.
%
% Inputs:
% aBlob - The blob object to be modified.
% aMask - Neighborhood of the structuring element used for closing.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oAddedIndices - Indices in the whole microscope image, of the pixels
%                 which were added to the binary region of the blob.
%
% See also:
% CloseAllBlobs, ConvexBlob, OpenBlob

% Pixels are left as zeros only if the structuring element can be placed
% INSIDE the image so that it overlaps with the pixels without touching
% pixels that are ones in the original image. This means that we need to
% pad the image so that pixels near the borders of the image are not
% automatically set to ones.

% Pad the image.
padding = floor(size(aMask)/2);
if aImData.GetDim == 3 && length(padding) == 2
    % A 3D structuring element with a single z-plane has a size with only 2
    % elements
    padding = [padding 0];
end
paddedIm = padarray(aBlob.image, padding);

% Close the image.
closedIm = imclose(paddedIm, aMask);

% Remove the padding
if aImData.GetDim() == 2
    closedIm = closedIm(...
        padding(1)+1:end-padding(1),...
        padding(2)+1:end-padding(2));
else
    closedIm = closedIm(...
        padding(1)+1:end-padding(1),...
        padding(2)+1:end-padding(2),...
        padding(3)+1:end-padding(3));
end

% Compute indices of added pixels.
if nargout > 0
    bb = aBlob.boundingBox;
    addedPixels = closedIm & ~aBlob.image;
    % The (:) operator after addedPixels is necessary if addedPixels is a
    % row vector, as oAddedIndices would otherwise be a row vector.
    if aImData.GetDim() == 2
        [y, x] = ind2sub(size(addedPixels), find(addedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        oAddedIndices = sub2ind(aImData.GetSize(), imY, imX);
    else
        [y, x, z] = ind2sub(size(addedPixels), find(addedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        imZ = z + bb(3) - 0.5;
        oAddedIndices = sub2ind(aImData.GetSize(), imY, imX, imZ);
    end
end

% Replace the blob image. The old image is used to compute the indices of
% the added pixels, so this has to be done last.
aBlob.image = closedIm;
end