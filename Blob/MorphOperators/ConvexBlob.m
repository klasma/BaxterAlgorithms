function oAddedIndices = ConvexBlob(aBlob, aImData)
% Replaces the binary region of a Blob by its convex hull.
%
% Inputs:
% aBlob - The blob object to be modified.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oAddedIndices - Indices in the whole microscope image, of the pixels
%                 which were added to the binary region of the blob.
%
% See also:
% ConvexAllBlobs, CloseBlob, OpenBlob

% Compute the convex hull.
if aImData.GetDim == 2
    convexIm = bwconvhull(aBlob.image);
else
    convexIm = BwConvHull3D(aBlob.image);
end

% Compute indices of added pixels.
if nargout > 0
    bb = aBlob.boundingBox;
    addedPixels = convexIm & ~aBlob.image;
    % The (:) operator after addedPixels is necessary if addedPixels is a
    % row vector, as oAddedIndices would otherwise be a row vector.
    if aImData.GetDim() == 2
        [y, x] = ind2sub(size(addedPixels), find(addedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        oAddedIndices = sub2ind(...
            [aImData.imageHeight aImData.imageWidth],...
            imY, imX);
    else
        [y, x, z] = ind2sub(size(addedPixels), find(addedPixels(:)));
        imX = x + bb(1) - 0.5;
        imY = y + bb(2) - 0.5;
        imZ = z + bb(3) - 0.5;
        oAddedIndices = sub2ind(...
            [aImData.imageHeight aImData.imageWidth aImData.numZ],...
            imY, imX, imZ);
    end
end

% Replace the blob image. The old image is used to compute the indices of
% the added pixels, so this has to be done last.
aBlob.image = convexIm;
end