function oImage = ReconstructSegmentsBlob(aBlobs, aSize)
% Generates an image where the pixel values are the indices of blobs.
%
% The background gets the value 0. If multiple blobs share the same pixel,
% the blob with the highest index will label the pixel.
%
% Inputs:
% aBlobs - Array of blob objects.
% aSize - The size of the output image in the format [width height depth]
%         or [width height] for 2D data.
%
% Outputs:
% oImage - Image with labels.
%
% See also:
% ReconstructSegments

oImage = zeros(aSize);

for i = 1:length(aBlobs)
    bb = aBlobs(i).boundingBox;
    if ~any(isnan(bb))
        im = aBlobs(i).image;
        
        if size(oImage,3) == 1  % 2D data.
            x1 = bb(1) + 0.5;
            x2 = bb(1) + bb(3) - 0.5;
            y1 = bb(2) + 0.5;
            y2 = bb(2) + bb(4) - 0.5;
            
            oImage(y1:y2, x1:x2) = max(oImage(y1:y2 , x1:x2), im*i);
            
        else  % 3D data.
            x1 = bb(1) + 0.5;
            x2 = bb(1) + bb(4) - 0.5;
            y1 = bb(2) + 0.5;
            y2 = bb(2) + bb(5) - 0.5;
            z1 = bb(3) + 0.5;
            z2 = bb(3) + bb(6) - 0.5;
            
            oImage(y1:y2, x1:x2, z1:z2) = max(oImage(y1:y2, x1:x2, z1:z2), im*i);
        end
    end
end
end