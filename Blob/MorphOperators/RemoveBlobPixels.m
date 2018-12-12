function RemoveBlobPixels(aBlob, aImIndices, aImData)
% Removes a set of pixels from a Blob.
%
% The blob is modified, so there is no need for an output.
%
% Inputs:
% aBlob - Blob object.
% aImIndices - Indices of the pixels to be removed, in the frame of the
%              whole image.
% aImData - ImageData object of the image sequence.

if aImData.GetDim() == 2
    bb = aBlob.boundingBox;
    % x- and y-coordinates in the whole image.
    [imY,imX] = ind2sub(aImData.GetSize(), aImIndices);
    % x- and y-coordinates in the boundingbox of the blob.
    x = imX - bb(1) + 0.5;
    y = imY - bb(2) + 0.5;
    outside = x < 1 | x > bb(3) | y < 1 | y > bb(4);
    x(outside) = [];
    y(outside) = [];
    % Pixel indices in the boundingbox of the blob.
    indices = sub2ind(size(aBlob.image), y, x);
    
    aBlob.image(indices) = false;
else
    bb = aBlob.boundingBox;
    % x-, y- and z-coordinates in the whole image.
    [imY,imX,imZ] = ind2sub(aImData.GetSize(), aImIndices);
    % x-, y-, and z-coordinates in the boundingbox of the blob.
    x = imX - bb(1) + 0.5;
    y = imY - bb(2) + 0.5;
    z = imZ - bb(3) + 0.5;
    outside = x < 1 | x > bb(4) | y < 1 | y > bb(5) | z < 1 | z > bb(6);
    x(outside) = [];
    y(outside) = [];
    z(outside) = [];
    % Pixel indices in the boundingbox of the blob.
    indices = sub2ind(size(aBlob.image), y, x, z);
    
    aBlob.image(indices) = false;
end

CropBlobZeros(aBlob)
MoveBlobCentroids(aBlob)
end