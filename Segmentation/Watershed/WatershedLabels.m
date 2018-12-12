function [oLabels, oLandscape] = WatershedLabels(aLandscape, aForeground, varargin)
% Breaks a binary segmentation mask into labeled watersheds.
%
% The function uses a seeded watershed transform to separate clusters of
% cells into individual cell regions. The function uses a custom C++
% implementation of the watershed transform, which does not process
% background pixels. Furthermore, only clusters with multiple seeds are
% included in the foreground, so if there are no clusters which need to be
% separated, the function does not compute a watershed transform at all.
% This can save some time on 3D data. The function can use smoothing or an
% h-minima transform to reduce over-segmentation, and it is also possible
% to remove seeds with a value below a threshold. To handle 3D z-stacks
% where the voxel height is much larger than the voxel width, it is
% possible to up-sample the z-dimension by inserting virtual z-planes into
% the z-stack. This prevents segmentation errors where one region steals a
% shard from a region above or below it.
%
% Inputs:
% aLandscape - Gray scale image to which the watershed algorithm will be
%              applied. This parameter should have local maxima on the
%              seeds, but internally the function inverts aLandscape, so
%              that the cell regions become watersheds with local minima
%              where the seeds are.
% aForeground - Binary segmentation mask with regions which should be
%               separated using a seeded watershed transform.
%
% Property/Value inputs:
% Smooth - Standard deviation of Gaussian smoothing kernel.
% HMax - h in h-minima transform.
% Threshold - Lower threshold on seed intensity.
% UpSampling - The number of virtual z-planes which will be inserted
%              between each pair or real z-planes. The values in the
%              virtual z-planes are computed using linear interpolation.
%
% Outputs:
% oLabels - Label matrix with watersheds.
% oLandscape - Topography used for watershed transform. The same as
%              aLandscape, but with smoothing and an h-minima transform
%              applied.

% Get parameter/value inputs.
[aSmooth, aHMax, aThreshold, aUpSampling] = GetArgs(...
    {'Smooth', 'HMax', 'Threshold', 'UpSampling'},...
    {0, 0, -inf, 1},...
    true,...
    varargin);

landscape = -aLandscape;

% Smooth the image prior to processing it.
if aSmooth > 0
    landscape = SmoothComp(landscape, aSmooth);
end

% Suppress all local maxima below a threshold.
if aHMax > 0
    landscape = imhmin(landscape, aHMax);
end

oLandscape = -landscape;

minima = imregionalmin(landscape);
% Remove seeds in the background.
minima(~aForeground) = false;
% Get rid of local maxima under a specified value.
if aThreshold > -inf
    minima(landscape > -aThreshold) = 0;
end

% Find the connected components of the binary foreground image.
if islogical(aForeground)
    if size(minima,3) == 1
        foregroundLabels = bwlabel(aForeground);
    else
        foregroundLabels = bwlabeln(aForeground);
    end
else
    foregroundLabels = aForeground;
end
numLabels = max(foregroundLabels(:));


% Generate seeds by finding the connected components of the local minima
% and breaking them into multiple seeds whenever they overlap with multiple
% connected components in the foreground image.
minimaLabels = bwlabeln(minima);
overlaps = cell(numLabels,1);
overlapIndices = cell(numLabels,1);
seeds = zeros(size(minimaLabels));
nextIndex = 1;
seedIndices = find(minimaLabels > 0);
for i = 1:length(seedIndices)
    index = seedIndices(i);
    lab = foregroundLabels(index);
    se = minimaLabels(index);
    if ~any(overlaps{lab} == se)
        overlaps{lab} = [overlaps{lab} se];
        overlapIndices{lab} = [overlapIndices{lab} nextIndex];
        seeds(index) = nextIndex;
        nextIndex = nextIndex + 1;
    end
end

multiSeedLabels = find(cellfun(@length,overlapIndices) > 1);
singleSeedLabels = setdiff(1:numLabels, multiSeedLabels);

% Array used to rename the labels so that labels with 0 or 1 seed come
% first and labels with multiple seeds are set to 0.
labelSelection = zeros(numLabels,1);
labelSelection(singleSeedLabels) = 1:length(singleSeedLabels);

% Put the labels with 0 or 1 seed into the output label image.
oLabels = zeros(size(foregroundLabels));
oLabels(foregroundLabels>0) = labelSelection(foregroundLabels(foregroundLabels>0));

% Perform the watershed transform to split labels with multiple seeds only
% if necessary.
if ~isempty(multiSeedLabels)
    % The seeds which lie in labels with multiple seeds.
    multiSeeds = [overlapIndices{multiSeedLabels}];
    
    fprintf('Separating %d clusters into %d cells using the watershed transform\n',...
        length(multiSeedLabels), length(multiSeeds))
    
    % Remove the seeds in regions with a single seed and give the remaining
    % seeds consecutive indices starting with 1.
    seedSelection = zeros(max(seeds(:)),1);
    seedSelection(multiSeeds) = 1:length(multiSeeds);
    watershedSeeds = zeros(size(seeds));
    watershedSeeds(seeds>0) = seedSelection(seeds(seeds>0));
    
    % The watershed transform is computed on only labels with multiple
    % seeds.
    watershedForeground = double(oLabels == 0 & aForeground);
    
    if aUpSampling > 1
        % Insert virtual z-planes between the existing ones.
        landscape = UpSampleZ(landscape, aUpSampling);
        watershedForeground = StretchZ(watershedForeground, aUpSampling);
        watershedSeeds = StretchZ(watershedSeeds, aUpSampling);
    end
    
    watershedLabels = SeededWatershed(landscape, watershedSeeds, watershedForeground);
    
    if aUpSampling > 1
        % Remove virtual z-planes.
        watershedLabels = DownSampleZ(watershedLabels, aUpSampling);
    end
    
    % Insert the labels from the separated clusters into the output label
    % image. The inserted labels have consecutive indices which come
    % directly after the indices of the labels with 0 or 1 seed.
    watershedLabels(watershedLabels > 0) =...
        watershedLabels(watershedLabels > 0) + length(singleSeedLabels);
    oLabels = oLabels + watershedLabels;
end
end