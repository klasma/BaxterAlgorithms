function CropBlobZeros(aBlobs)
% Removes rows, columns and z-planes with zeros from the sides of blobs.
%
% This function crops the binary images of blobs, so that there are no
% rows, columns or z-planes with only zeros on the sides of the images. The
% boundingboxes of the blobs are adjusted accordingly. The operation
% corresponds to making the boundingbox around the blob as small as
% possible. This may be necessary after morphological processing of the
% blobs or after segmentation editing in ManualCorrectionPlayer. If the
% input blobs do not have any pixels that are 1 in the binary images, the
% blobs will be turned into point blobs, which corresponds to setting the
% image to NaN and the boundingbox to a 1x4 NaN-array for 2D blobs and a
% 1x6 NaN-array for 3D blobs.
%
% aBlobs - Array of Blob objects to crop. Edits are made to the Blob
%          objects, so there is no need for an output.
%
% See also:
% Blob

for i = 1:length(aBlobs)
    b = aBlobs(i);
    if length(b.boundingBox) == 4  % 2D
        im = b.image;
        bb = b.boundingBox;
        
        anyX = any(im,1);
        anyY = any(im,2);
        
        x1 = find(anyX,1,'first');
        
        if isempty(x1)
            % Turn the blob into a point blob if it has no pixels.
            b.image = nan;
            b.boundingBox = nan(size(bb));
            continue
        end
        
        x2 = find(anyX,1,'last');
        y1 = find(anyY,1,'first');
        y2 = find(anyY,1,'last');
        
        b.image = im(y1:y2, x1:x2);
        b.boundingBox = [bb(1)+x1-1 bb(2)+y1-1 ...
            size(b.image,2) size(b.image,1)];
    else  % 3D
        im = b.image;
        bb = b.boundingBox;
        
        anyX = any(any(im,1),3);
        anyY = any(any(im,2),3);
        anyZ = any(any(im,1),2);
        
        x1 = find(anyX,1,'first');
        
        if isempty(x1)
            % Turn the blob into a point blob if it has no pixels.
            b.image = nan;
            b.boundingBox = nan(size(bb));
            continue
        end
        
        x2 = find(anyX,1,'last');
        y1 = find(anyY,1,'first');
        y2 = find(anyY,1,'last');
        z1 = find(anyZ,1,'first');
        z2 = find(anyZ,1,'last');
        
        b.image = im(y1:y2, x1:x2, z1:z2);
        b.boundingBox = [bb(1)+x1-1 bb(2)+y1-1 bb(3)+z1-1 ...
            size(b.image,2) size(b.image,1) size(b.image,3)];
    end
end
end