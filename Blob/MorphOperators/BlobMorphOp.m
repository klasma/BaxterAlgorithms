function oBlobs = BlobMorphOp(aBlobs, aOperator, aEllipseSize, aImData)
% Applies a morphological operator to the binary masks of a set of blobs.
%
% Inputs:
% aBlobs - Array of blobs that the morphological operators will be applied
%          to.
% aOperator - The morphological operator to be applied. This can be
%             'close', 'convexhull', or 'open'. The convex hull is not
%             computed using a structuring element and therefore the input
%             aEllipseSize has no effect.
% aEllipseSize - Radius of the structuring element in the xy-plane. For 3D
%                data, the structuring element will be a ball with this
%                radius in the imaged volume, but in the discretized image
%                it may be an ellipsoid if the distance between z-planes is
%                not the same as the voxel width.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oBlobs - Array of blobs where the morphological operation has been
%          applied. The objects in aBlobs are altered, so depending on the
%          operator, oBlobs might be identical to aBlobs when the function
%          has been executed.
%
% See also:
% Blob, CloseAllBlobs, ConvexAllBlobs, OpenAllBlobs

oBlobs = aBlobs;

% Determine the semi-axes of the structuring element.
if length(aEllipseSize) > 1
    if aImData.GetDim() == 3
        semiAxes = aEllipseSize;
    else
        % The user can input a 3 element vector, but in that case only the
        % first two elements are used.
        semiAxes = aEllipseSize(1:2);
    end
else
    if aImData.GetDim() == 3
        semiAxes = aEllipseSize * [ones(1,2) 1/aImData.voxelHeight];
    else
        semiAxes = aEllipseSize * ones(1,2);
    end
end

mask = Ellipse(semiAxes);  % Structuring element.

switch aOperator
    case 'close'
        CloseAllBlobs(oBlobs, mask, aImData)
    case 'convexhull'
        ConvexAllBlobs(oBlobs, aImData)
    case 'open'
        oBlobs = OpenAllBlobs(oBlobs, mask, aImData);
    otherwise
        error('Unknown morphological operator for cell segmentation masks.')
end
end