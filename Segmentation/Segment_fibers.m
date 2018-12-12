function [oBW, oImages] = Segment_fibers(...
    aImData,...
    aFrame,...
    aMedFiltSize,...
    aBGThreshold,...
    aSmallestCrack,...
    aSegChannel,...
    aSegSmooth,...
    aMergeThreshold,...
    aSmallestUnmerged,...
    aSmallestHole,...
    aOpenRadius,...
    aShapeHmin)
% Segments muscle fibers in tissue sections.
%
% The segmentation is done using a watershed transform on a cell membrane
% stain (laminin). The function also generates a background mask using the
% intensity in all image channels. All background pixels in the
% laminin image are set to the maximum laminin value to create artificial
% cell membranes between all fibers. Gaussian smoothing is used to combine
% the true and the artificial cell membranes. Finally the fibers are
% segmented using a watershed transform with region merging. Regions are
% merged if the intensity ratio between the ridge pixels and the region
% with the highest intensity is too low. All regions smaller than a
% threshold are also merged into other regions, but all merges are done in
% order of increasing intensity ratio. Additional processing is done using
% morphological opening and a watershed transform on the distance image.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
% aFrame - Index of the image to be segmented.
% aMedFiltSize - The size of a median filter which is applied to the
%                maximum of all channels. The maximum image is then used to
%                create the background mask.
% aBGThreshold - Threshold below which pixels in the maximum image are
%                considered to be background.
% aSmallestCrack - Background regions with an area smaller than this
%                  threshold are removed when the maximum image is
%                  thresholded.
% aSegChannel - Name or index of the cell membrane channel.
% aSegSmooth - The standard deviation of the Gaussian kernel used to
%              combine the true and the artificial cell membranes.
% aMergeThreshold - Threshold on intensity ratio below which watersheds
%                   will be merged.
% aSmallestUnmerged - Watershed regions with an area below this threshold
%                     are merged into other regions.
% aSmallestHole - Background regions after the watershed transform
%                 (watershed ridges) with an area below this threshold are
%                 removed. This will remove small pieces of fiber membrane
%                 which are not believed to represent true boundaries
%                 between fibers.
% aOpenRadius - Radius of a disk shaped structuring element which is used
%               for morphological opening of the segmentation mask with
%               fibers. This gives smoother contours and removes thin parts
%               of segments.
% aShapeHmin - h-value of an h-minima transform which is applied to the
%              distance image of the binary segmentation mask before a
%              watershed transform is applied to that distance image. The
%              purpose of that watershed transform is to spilt highly
%              non-convex regions into multiple fibers.
%
% Outputs:
% oBW - Boolean segmentation mask.
% oImages - Struct with intermediate processing results. The struct has the
%           following fields:
%    background - Background regions which are not fibers.
%    membrane - Intensity of the computed membrane separating the fibers.
%    unmerged - Binary mask with unmerged watershed regions.
%    merged - Binary mask with merged watershed regions.
%    mask  - Binary segmentation mask.
%
% See also:
% Segment_generic, MergeWatersheds

% Typical settings values are given as comments at the ends of lines.

% Find background pixels.
allChannels = zeros(aImData.imageHeight, aImData.imageWidth, length(aImData.channelNames));
for i = 1:length(aImData.channelNames)
    allChannels(:,:,i) = aImData.GetDoubleImage(aFrame, 'Channel',  i) / 255;
end
% Maximum of all channels.
im_fibers = max(allChannels, [], 3);
% Get rid of noise using a 5x5 median filter.
im_fibers = medfilt2(im_fibers, aMedFiltSize*[1 1], 'symmetric');  % 5.
minVal = min(im_fibers(:));
im_fibers = (im_fibers - minVal) / (1-minVal);  % Possible division by 0.
background = im_fibers < aBGThreshold;
% Holes smaller than 20 pixels are not considered background.
background = bwareaopen(background, aSmallestCrack);  % 20.
oImages.background = background;

% Find membrane pixels (all pixels between the fibers).
im_membrane = aImData.GetDoubleImage(aFrame, 'Channel', aSegChannel) / 255;
im_membrane = im_membrane - min(im_membrane(:));
% Pretend like the background is a thick cell membrane.
im_membrane(background) = max(im_membrane(:));
% Smooth the membrane to fill in holes, suppress noise and merge the true
% membrane with the artificial membrane created from the background pixels.
if aSegSmooth > 0
    im_membrane = SmoothComp(im_membrane, aSegSmooth);  % 1
end
oImages.membrane = im_membrane;

% Initial watershed transform on the membrane intensity.
labels = double(watershed(im_membrane));

% Remove background pixels from the segments.
labels(background) = 0;

oImages.unmerged = labels > 0;

% Merge watersheds to get rid of over-segmentation.
labels = MergeWatersheds(labels, im_membrane, aMergeThreshold, aSmallestUnmerged);  % 250

oImages.merged = labels > 0;

% Remove thin and irregular parts of the segments.
not_labels_bw = labels == 0;
not_labels_bw = bwareaopen(not_labels_bw, aSmallestHole);  % 5000
oBW = ~not_labels_bw;
oBW = imopen(oBW, strel('disk',  aOpenRadius));  % 5

% Do an additional watershed segmentation on the pixel distance to the
% background. This can split adjacent fibers that are merged together by
% narrow bridges.
if ~isnan(aShapeHmin)
    dist = -double(bwdist(oBW == 0));
    dist = imhmin(dist, aShapeHmin);  % 5
    dist_seeds = bwlabel(imregionalmin(dist));
    labels = SeededWatershed(dist, dist_seeds, double(oBW~=0));
    oBW = labels > 0;
end

oImages.mask = oBW;
end