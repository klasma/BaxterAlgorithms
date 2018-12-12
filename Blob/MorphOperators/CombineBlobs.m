function oBlob = CombineBlobs(aBlob_a, aBlob_b, varargin)
% Combines a number of 2D-blobs into a single blob.
%
% The function adds pixels between the blobs, to replace pixels that might
% have been lost in the watershed algorithm. To replace only pixels that
% the watershed algorithm would remove, pixels are only added if they are
% 4-connected with one blob and 8-connected with the other. The adding of
% pixels can be turned off.
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
% CombineBlobs3D, Blob

aFillCracks = GetArgs({'FillCracks'}, {true}, true, varargin);

oBlob = aBlob_a;

% Merge the blobs recursively if there are more than two blobs to merge.
if length(aBlob_b) > 1
    for bIndex = 1:length(aBlob_b)
        oBlob = CombineBlobs(oBlob, aBlob_b(bIndex));
    end
    return
end

% Boudningbox of the first blob.
bb_a = aBlob_a.boundingBox;
x1_a = bb_a(1);
x2_a = bb_a(1) + bb_a(3);
y1_a = bb_a(2);
y2_a = bb_a(2) + bb_a(4);

% Boundingbox of the second blob.
bb_b = aBlob_b.boundingBox;
x1_b = bb_b(1);
x2_b = bb_b(1) + bb_b(3);
y1_b = bb_b(2);
y2_b = bb_b(2) + bb_b(4);

% Boundingbox of the merged blob
bb_c = zeros(1,4);
bb_c(1) = min(x1_a,x1_b);
bb_c(2) = min(y1_a,y1_b);
bb_c(3) = max(x2_a,x2_b) - bb_c(1);
bb_c(4) = max(y2_a,y2_b) - bb_c(2);
oBlob.boundingBox = bb_c;

% Padded image of the first blob.
im_ca = zeros(bb_c(4),bb_c(3));
offsetX_a = max(0,x1_a-x1_b);
offsetY_a = max(0,y1_a-y1_b);
im_ca((1:bb_a(4))+offsetY_a, (1:bb_a(3))+offsetX_a) = aBlob_a.image;

% Padded image of the second blob.
im_cb = zeros(bb_c(4),bb_c(3));
offsetX_b = max(0,x1_b-x1_a);
offsetY_b = max(0,y1_b-y1_a);
im_cb((1:bb_b(4))+offsetY_b, (1:bb_b(3))+offsetX_b) = aBlob_b.image;

if aFillCracks
    % Pixels between the two blobs. If im_ca or im_cb is a logical column
    % vector, imdilate causes a segfault (im MATLAB 2015b). Therefore im_ca
    % and im_cb are defined as double arrays.
    mergePixels1 = imdilate(im_ca, ones(3)) &...
        imdilate(im_cb, [0 1 0; 1 1 1; 0 1 0]);
    mergePixels2 = imdilate(im_cb, ones(3)) &...
        imdilate(im_ca, [0 1 0; 1 1 1; 0 1 0]);
    
    % Combine the two blobs and the pixels between them into a merged blob.
    mergeImage = im_ca | im_cb | mergePixels1 | mergePixels2;
else
    % Combine the two blobs.
    mergeImage = im_ca | im_cb;
end

oBlob.image = mergeImage;
oBlob.regionProps = struct();
oBlob.features = struct();

% Recompute the centroid.
[x, y] = oBlob.GetPixelCoordinates();
xmean = mean(x);
ymean = mean(y);
oBlob.centroid = [xmean ymean];
end