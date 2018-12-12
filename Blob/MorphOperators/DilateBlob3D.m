function oBlob = DilateBlob3D(aImData, aBlob, aMask)
% Applies the imdilate operation to the image of a 3D Blob object.
%
% The function returns a copy of the Blob object where the image has been
% dilated. The original object is not altered.
%
% Inputs:
% aImData - Image data object associated with the image sequence.
% aBlob - Blob object where the image needs to be dilated.
% aMask - Binary dilation pattern.
%
% Outputs:
% oBlob - New blob object where the image has been dilated.
%
% See also:
% CombineBlobs, Blob

% Make a copy of the blob so that the original is not altered.
oBlob = aBlob.Clone();
[y1, y2, x1, x2, z1, z2] = oBlob.GetBoundaryCoordinates();
im = oBlob.image;

% The number of pixel prior and after the current pixel that will be
% affected in the different image dimensions. The imdilate operation will
% affect more pixels after the current pixel than before if the width of
% the dilation mask is an even number.
floorthick =  floor((size(aMask)-1)/2);
ceilthick = ceil((size(aMask)-1)/2);

% Compute how much to pad.

padAbove = min(y1-1, floorthick(1));
padBelow = min(aImData.imageHeight-y2, ceilthick(1));

padLeft = min(x1-1, floorthick(2));
padRight = min(aImData.imageWidth-x2, ceilthick(2));

padUnder = min(z1-1, floorthick(3));
padOver = min(aImData.numZ-z2, ceilthick(3));

% Change boundingbox.
bb = oBlob.boundingBox;
oBlob.boundingBox = bb +...
    [-padLeft -padAbove -padUnder...
    padLeft+padRight padAbove+padBelow padUnder+padOver];

% Dilate image.
im = padarray(im, [padAbove padLeft padUnder], 'pre');  % Pad left, above and under.
im = padarray(im, [padBelow padRight padOver], 'post');  % Pad right, below and over.
oBlob.image = imdilate(im, aMask);
end