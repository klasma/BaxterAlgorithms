function CropExtrapolatedPixels(aSeqPath)
% Removes extrapolated pixels, caused by stabilization, from image borders.
%
% When an image sequence is stabilized using StabilizeLK, pixels values
% outside the field of view are extrapolated using the values of the
% closest pixels inside the field of view. This gives striped image
% borders, which can cause problems in the segmentation step. This function
% crops away all extrapolated pixels, and the corresponding pixels in the
% other images of the image sequence. This produces an image sequence
% without extrapolated pixels, where all images have the same size. The
% un-cropped image sequence is replaced by the cropped image sequence.
%
% Inputs:
% aSeqPath - Full path of the image sequence to be cropped.
%
% See also:
% StabilizeLK, StabilizatinoGUI

imData = ImageData(aSeqPath);
tifs = GetNames(aSeqPath, 'tif');

% Find the smallest and the largest shifts applied in each dimension during
% stabilization.
shifts = ReadStabilizationLog(aSeqPath);
maxXshift = max(shifts(:,1));
minXshift = min(shifts(:,1));
maxYshift = max(shifts(:,2));
minYshift = min(shifts(:,2));

% Compute the boundingbox that should be cropped out of each image.
x1 = 1 + ceil(max(0, -minXshift));
x2 = imData.imageWidth - ceil(max(0, maxXshift));
y1 = 1 + ceil(max(0, -minYshift));
y2 = imData.imageHeight - ceil(max(0, maxYshift));

% Read the un-cropped images, crop them, and replace the un-cropped images.
for t = 1:length(tifs)
    tifPath = fullfile(aSeqPath, tifs{t});
    im = imread(tifPath);
    im = im(y1:y2,x1:x2);
    imwrite(im,tifPath, 'Compression', 'lzw')
end
end