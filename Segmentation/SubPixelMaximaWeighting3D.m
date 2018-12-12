function [oX, oY, oZ] = SubPixelMaximaWeighting3D(aIm, aX, aY, aZ)
% Doing 3D sub-pixel positioning by computing the weighted pixel centroid.
%
% The function computes the weighted centroid of a 3x3x3 region around
% local maxima in a z-stack. This can be used for sub-pixel positioning of
% detected particles in an image. If a local maxima is on the border of the
% z-stack, only the dimensions which are not limited by the border will be
% given sub-pixel accuracy.
%
% Inputs:
% aIm - Double image.
% aX - Vector with x-coordinates of the local maxima.
% aY - Vector with y-coordinates of the local maxima.
% aZ - Vector with z-coordinates of the local maxima.
%
% Outputs:
% oX - Vector of x-coordinates with sub-pixel accuracy.
% oY - Vector of y-coordinates with sub-pixel accuracy.
% oZ - Vector of z-coordinates with sub-pixel accuracy.
%
% See also:
% SubPixelMaximaWeighting, Segment_generic3D

% Allocate memory.
oX = nan(size(aX));
oY = nan(size(aY));
oZ = nan(size(aY));

[yMax, xMax, zMax] = size(aIm);

for i = 1:length(aX)
    % Coordinates of neighborhood around local maxima.
    x1 = max(aX(i)-1, 1);
    x2 = min(aX(i)+1, xMax);
    y1 = max(aY(i)-1, 1);
    y2 = min(aY(i)+1, yMax);
    z1 = max(aZ(i)-1, 1);
    z2 = min(aZ(i)+1, zMax);
    
    % Cut out the neighborhood and normalize it to sum to 1.
    patchI = aIm(y1:y2, x1:x2, z1:z2);
    patchI = patchI / sum(patchI(:));
    
    % Compute x-, y- and z-coordinates in of the neighborhood pixels.
    [patchX, patchY, patchZ] = meshgrid(x1:x2, y1:y2, z1:z2);
    
    oY(i) = patchY(:)' * patchI(:);
    
    if aX(i) == 1 || aX(i) == xMax
        % The pixel is on the edge of the x-interval, so the x-coordinate
        % is not updated.
        oX(i) = aX(i);
    else
        oX(i) = patchX(:)' * patchI(:);
    end
    
    if aY(i) == 1 || aY(i) == yMax
        % The pixel is on the edge of the y-interval, so the y-coordinate
        % is not updated.
        oY(i) = aY(i);
    else
        oY(i) = patchY(:)' * patchI(:);
    end
    
    if aZ(i) == 1 || aZ(i) == zMax
        % The pixel is on the edge of the z-interval, so the z-coordinate
        % is not updated.
        oZ(i) = aZ(i);
    else
        oZ(i) = patchZ(:)' * patchI(:);
    end
end
end