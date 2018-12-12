function oBlob = DilateBlob(aImData, aBlob, aMask)
% Applies the imdilate operation to the image of a 2D Blob object.
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
% CombineBlobs3D, Blob

% Make a copy of the blob so that the original is not altered.
oBlob = aBlob.Clone();
bb = oBlob.boundingBox;
im = oBlob.image;

% Compute how much to pad.
padLeft = min(bb(1)-0.5, floor((size(aMask,2)-1)/2));
padRight = min(aImData.imageWidth-(bb(1)+bb(3)-0.5), ceil((size(aMask,2)-1)/2));
padOver = min(bb(2)-0.5, floor((size(aMask,1)-1)/2));
padUnder = min(aImData.imageHeight-(bb(2)+bb(4)-0.5), ceil((size(aMask,1)-1)/2));

% Change boundingbox.
bb = oBlob.boundingBox;
oBlob.boundingBox = bb + [-padLeft -padOver padLeft+padRight padOver+padUnder];

% Dilate image.
im = padarray(im, [padOver padLeft], 'pre');  % Pad left and over.
im = padarray(im, [padUnder padRight], 'post');  % Pad right and under.
oBlob.image = imdilate(im, aMask);
end