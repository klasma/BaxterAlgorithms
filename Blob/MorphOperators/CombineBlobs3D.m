function oBlob = CombineBlobs3D(aBlob_a, aBlob_b, varargin)
% Combines a number of 3D-blobs into a single blob.
%
% The function adds pixels between the blobs, to replace pixels that might
% have been lost in the watershed algorithm. To replace only pixels that
% the watershed algorithm would remove, pixels are only added if they are
% 6-connected with one blob and 26-connected with the other.
%
% Inputs:
% aBlob_a - Blob that the other blobs will be merged into.
% aBlob_b - Array with one or more blobs that will be merged into aBlob_a.
%
% Property/Value inputs:
% FillCracks - If this is set to false, the adding of pixels between the
%              blobs is turned off.
%
% Outputs:
% oBlob - The same as aBlob_a. This output is redundant, because the
%         function alters aBlob_a.
%
% See also:
% CombineBlobs, Blob

aFillCracks = GetArgs({'FillCracks'}, {true}, true, varargin);

oBlob = aBlob_a;

% Merge the blobs recursively if there are more than two blobs to merge.
if length(aBlob_b) > 1
    for bIndex = 1:length(aBlob_b)
        oBlob = CombineBlobs3D(oBlob, aBlob_b(bIndex));
    end
    return
end

% Voxel intervals that the old blobs occupy.
[y1a, y2a, x1a, x2a, z1a, z2a] = aBlob_a.GetBoundaryCoordinates();
[y1b, y2b, x1b, x2b, z1b, z2b] = aBlob_b.GetBoundaryCoordinates();

% Voxel intervals that the new blob will occupy.
y1c = min(y1a,y1b);
x1c = min(x1a,x1b);
z1c = min(z1a,z1b);
y2c = max(y2a,y2b);
x2c = max(x2a,x2b);
z2c = max(z2a,z2b);

% The number of voxels in each dimension for the old and the new blobs.

yNa = y2a - y1a + 1;
xNa = x2a - x1a + 1;
zNa = z2a - z1a + 1;

yNb = y2b - y1b + 1;
xNb = x2b - x1b + 1;
zNb = z2b - z1b + 1;

yNc = y2c - y1c + 1;
xNc = x2c - x1c + 1;
zNc = z2c - z1c + 1;

% Padded image of the first blob.
im_ca = zeros(yNc, xNc, zNc);
offsetXa = max(0,x1a-x1b);
offsetYa = max(0,y1a-y1b);
offsetZa = max(0,z1a-z1b);
im_ca((1:yNa)+offsetYa, (1:xNa)+offsetXa, (1:zNa)+offsetZa) = aBlob_a.image;

% Padded image of the second blob.
im_cb = zeros(yNc, xNc, zNc);
offsetXb = max(0,x1b-x1a);
offsetYb = max(0,y1b-y1a);
offsetZb = max(0,z1b-z1a);
im_cb((1:yNb)+offsetYb, (1:xNb)+offsetXb, (1:zNb)+offsetZb) = aBlob_b.image;

% Combine the two blobs and the pixels between them into a merged blob.
oBlob.boundingBox = [[x1c y1c z1c]-0.5 xNc yNc zNc];
if aFillCracks
    % Pixels between the two blobs. If im_ca or im_cb is a logical column
    % vector, imdilate causes a segfault (im MATLAB 2015b). Therefore im_ca
    % and im_cb are defined as double arrays.
    mergePixels1 = imdilate(im_ca, ones(3,3,3)) &...
        imdilate(im_cb, Ellipse([1 1 1]));
    mergePixels2 = imdilate(im_cb, ones(3,3,3)) &...
        imdilate(im_ca,  Ellipse([1 1 1]));
    oBlob.image = im_ca | im_cb | mergePixels1 | mergePixels2;
else
    oBlob.image = im_ca | im_cb;
end
oBlob.regionProps = struct();
oBlob.features = struct();

% Recompute the centroid.
[x, y, z] = oBlob.GetPixelCoordinates();
xmean = mean(x);
ymean = mean(y);
zmean = mean(z);
oBlob.centroid = [xmean ymean zmean];
end