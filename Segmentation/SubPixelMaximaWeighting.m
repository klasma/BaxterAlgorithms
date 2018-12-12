function [oX, oY] = SubPixelMaximaWeighting(aIm, aX, aY)
% Doing sub-pixel positioning by computing the weighted pixel centroid.
%
% The function computes the weighted centroid of a 3x3 region around local
% maxima in an image. This can be used for sub-pixel positioning of
% detected particles in an image. If a local maxima is on the border of the
% image, only the dimension which is not limited by the border will be
% given sub-pixel accuracy.
%
% Inputs:
% aIm - Double image.
% aX - Vector with x-coordinates of the local maxima.
% aY - Vector with y-coordinates of the local maxima.
%
% Outputs:
% oX - Vector of x-coordinates with sub-pixel accuracy.
% oY - Vector of y-coordinates with sub-pixel accuracy.
%
% See also:
% SubPixelMaximaWeighting3D, Segment_generic

% Allocate memory.
oX = nan(size(aX));
oY = nan(size(aY));

[yMax, xMax] = size(aIm);

for i = 1:length(aX)
    % Coordinates of neighborhood around local maxima.
    x1 = max(aX(i)-1, 1);
    x2 = min(aX(i)+1, xMax);
    y1 = max(aY(i)-1, 1);
    y2 = min(aY(i)+1, yMax);
    
    % Cut out the neighborhood and normalize it to sum to 1.
    patchI = aIm(y1:y2, x1:x2);
    patchI = patchI / sum(patchI(:));
    
    % Compute x- and y-coordinates in of the neighborhood pixels.
    [patchX, patchY] = meshgrid(x1:x2, y1:y2);
    
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
end
end