function oBlobs = CropBlobs(aBlobs, aX1, aX2, aY1, aY2, aZ1, aZ2)
% Crops out blobs and parts of blobs that are inside a sub-volume.
%
% Inputs:
% aBlobs - Array of blobs to crop.
% aX1 - Smallest x-value (horizontal dimension).
% aX2 - Largest x-value (horizontal dimension).
% aY1 - Smallest y-value (vertical dimension).
% aY2 - Largest y-value (vertical dimension).
% aZ1 - Smallest z-value (depth dimension in 3D data).
% aZ2 - Smallest z-value (depth dimension in 3D data).
%
% Outputs:
% oBlobs - Array with cropped blobs. Blobs which are completely outside the
%          cropping boundingbox are removed. The blob objects are cloned
%          before they are modified and returned, so aBlobs are not
%          changed.
%
% See also:
% CropCells

oBlobs = [];

for i = 1:length(aBlobs)
    [y1, y2, x1, x2, z1, z2] = aBlobs(i).GetBoundaryCoordinates();
    [h, w, d] = size(aBlobs(i).image);
    
    % The number of pixels to cut on each side of the image.
    dx1 = max(aX1-x1,0);
    dx2 = max(x2-aX2,0);
    dy1 = max(aY1-y1,0);
    dy2 = max(y2-aY2,0);
    dz1 = max(aZ1-z1,0);
    dz2 = max(z2-aZ2,0);
    
    if dx1 < w && dx2 < w && dy1 < h && dy2 < h && dz1 < d && dz2 < d
        b = aBlobs(i).Clone();
        if dx1 ~= 0 || dx2 ~= 0 || dy1 ~= 0 || dy2 ~= 0 || dz1 ~= 0 || dz2 ~= 0
            % The blob needs to be cropped.
            b.image = b.image(1+dy1:end-dy2, 1+dx1:end-dx2, 1+dz1:end-dz2);
            if length(b.boundingBox) == 4  % 2D blob
                b.boundingBox = b.boundingBox + [dx1 dy1 -dx1-dx2 -dy1-dy2];
            else  % 3D blob
                b.boundingBox = b.boundingBox +...
                    [dx1 dy1 dz1 -dx1-dx2 -dy1-dy2 -dz1-dz2];
            end
        end
        oBlobs = [oBlobs b]; %#ok<AGROW>
    end
end
end