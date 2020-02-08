function [oBlobs, oBw, oGray, oImages] = Segment_generic3D(aImData, aFrame, varargin)
% Runs 3D segmentation algorithms together with pre- and post-processing.
%
% The function runs other segmentation functions and allows pre- and
% post-processing to be done before and after the main segmentation
% function is called. In the pre-processing step, the function can perform
% intensity clipping, median filtering, and Gaussian smoothing. In the
% post-processing step, the function can fill holes, apply watershed
% transforms to break clusters, remove regions that are too small or too
% large, and apply morphological operations to the segmented cell regions.
% Using property/value inputs, a sub-volume can be specified for
% segmentation. This can save computation time when parameters are tweaked
% in SegmentationPlayer.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - The index of the frame to be segmented.
%
% Property/Value inputs:
% X1 - First pixel in x-dimension of sub-volume to be segmented.
% X2 - Last pixel in x-dimension of sub-volume to be segmented.
% Y1 - First pixel in y-dimension of sub-volume to be segmented.
% Y2 - Last pixel in y-dimension of sub-volume to be segmented.
% Z1 - First pixel in z-dimension of sub-volume to be segmented.
% Z2 - Last pixel in z-dimension of sub-volume to be segmented.
%
% Settings in aImData (these are only a few important ones):
% SegAlgorithm - The name of the segmentation algorithm that will be used.
% SegFillHoles - Fill holes in the segmentation mask if set to 1.
% SegMinArea - Minimum volume of segmented regions in voxels. No regions
%              are removed if the value is 0.
% SegMaxArea - Maximum volume of segmented regions in pixels. No regions
%              are removed if the value is inf.
%
% Outputs:
% oBlobs - Array of Blob objects representing the segmented regions.
% oBw - Binary segmentation mask where cell pixels are 1s.
% oGray - Z-stack before the thresholding step which creates cell regions.
% oImages - Struct with fields for intermediate processing steps. The
%           fields are named after the processing steps. The z-stacks
%           included in oImages vary depending on the segmentation
%           algorithm and the pre- and post-processing algorithms used.
%
% See also:
% SegmentSequence, SegmentationPlayer, Segment_generic,
% Segment_threshold3D, Segment_bandpass3D, Segment_precondPSF3D

% Parse property/value inputs.
[aX1, aX2, aY1, aY2, aZ1, aZ2] = GetArgs(...
    {'X1', 'X2', 'Y1', 'Y2', 'Z1', 'Z2'},...
    {1, aImData.imageWidth, 1, aImData.imageHeight, 1, aImData.numZ},...
    true, varargin);

if isempty(varargin)
    
    xBlock = 483;
    yBlock = 468;
    zBlock = 496;
    
    xMarg = 50;
    yMarg = 50;
    zMarg = 50;

%     xBlock = 256;
%     yBlock = 256;
%     zBlock = 30;
%     
%     xMarg = 50;
%     yMarg = 50;
%     zMarg = 50;
    
    xN = max(ceil((aImData.imageWidth - xMarg) / xBlock), 1);
    yN = max(ceil((aImData.imageHeight - yMarg) / yBlock), 1);
    zN = max(ceil((aImData.numZ - zMarg) / zBlock), 1);
    
    blobGroups = cell(yN, xN, zN);
    limits = struct();
    
    for i = 1:xN
        for j = 1:yN
            for k = 1:zN
                x1 = 1 + (i - 1) * xBlock;
                x2 = i * xBlock;
                y1 = 1 + (j - 1) * yBlock;
                y2 = j * yBlock;
                z1 = 1 + (k - 1) * zBlock;
                z2 = k * zBlock;
                
                if i == 1
                    limits(j, i, k).xMin = -inf;
                else
                    limits(j, i, k).xMin = x1;
                end
                if j == 1
                    limits(j, i, k).yMin = -inf;
                else
                    limits(j, i, k).yMin = y1;
                end
                if k == 1
                    limits(j, i, k).zMin = -inf;
                else
                    limits(j, i, k).zMin = z1;
                end
                
                if i == xN
                    limits(j, i, k).xMax = inf;
                else
                    limits(j, i, k).xMax = x2;
                end
                if j == yN
                    limits(j, i, k).yMax = inf;
                else
                    limits(j, i, k).yMax = y2;
                end
                if k == zN
                    limits(j, i, k).zMax = inf;
                else
                    limits(j, i, k).zMax = z2;
                end
                
                x1 = max(x1 - xMarg, 1);
                y1 = max(y1 - yMarg, 1);
                z1 = max(z1 - zMarg, 1);
                
                x2 = min(x2 + xMarg, aImData.imageWidth);
                y2 = min(y2 + yMarg, aImData.imageHeight);
                z2 = min(z2 + zMarg, aImData.numZ);
                
                fprintf('Segmenting i=%d, j=%d, k=%d\n', i, j, k)
                blobs = Segment_generic3D(aImData, aFrame,...
                    'X1', x1,...
                    'X2', x2,...
                    'Y1', y1,...
                    'Y2', y2,...
                    'Z1', z1,...
                    'Z2', z2);
                
                % Shift the blob bounding boxes to the full image.
                for bIndex = 1:length(blobs)
                    blobs(bIndex).boundingBox = blobs(bIndex).boundingBox +...
                        [x1-1 y1-1 z1-1 0 0 0];
                end
                
                blobGroups{j, i, k} = blobs;
            end
        end
    end
    
    oBlobs = SelectBlobs(blobGroups, limits, 50);
    oImages = struct();
    return
    
end

oImages = struct();

I = aImData.GetDoubleZStack(aFrame, 'Channel', aImData.Get('SegChannel'));

if ~isempty(varargin)
    % Crop the input volume if cropping instructions are given.
    I = I(aY1:aY2, aX1:aX2, aZ1:aZ2);
end

% Apply intensity clipping.
if aImData.Get('SegClipping') < 1
    I(I > 255*aImData.Get('SegClipping')) = 255*aImData.Get('SegClipping');
end
% Apply intensity clipping from below.
if aImData.Get('SegClippingBelow') > 0
    I = max(0, I - aImData.Get('SegClippingBelow')*255);
end
if aImData.Get('SegClipping') < 1 || aImData.Get('SegClippingBelow') > 0
    oImages.clipped = I;
end

% Apply median filtering to get rid of noise.
if any(aImData.Get('SegMedFilt') > 1)
    switch length(aImData.Get('SegMedFilt'))
        case 1
            medFilt = aImData.Get('SegMedFilt') * ones(1,3);
        case 3
            medFilt = aImData.Get('SegMedFilt');
        otherwise
            error('SegMedFilt must have length 1 or 2 for 2D data.')
    end
    I = medfilt3(I, medFilt);
end

% Apply Gaussian smoothing to get rid of noise.
% TODO: Make segmentation in the z-dimension different.
if aImData.Get('SegSmooth') > 0
    I = SmoothComp(I, aImData.Get('SegSmooth'));
end

% Perform top-hat filtering to remove non-uniform background illumination.
if ~isinf(aImData.Get('SegTopHatRadius'))
    % The top-hat filtering is done separately on each z-slice.
    for i = 1:size(I,3)
        I(:,:,i) = imtophat(I(:,:,i),...
            strel('disk', aImData.Get('SegTopHatRadius')));
    end
end

% Execute main segmentation algorithm.
oGray = [];
segSteps = struct();
switch aImData.Get('SegAlgorithm')
    case 'Segment_threshold3D'
        [oBw, segSteps] = Segment_threshold3D(I,...
            aImData.Get('TSegThreshold'),...
            aImData.Get('TSegDarkOrBright'));
    case 'Segment_bandpass3D'
        [oBw, oGray, segSteps] = Segment_bandpass3D(I, aImData, aFrame,...
            aImData.Get('BPSegHighStd'),...
            aImData.Get('BPSegLowStd'),...
            aImData.Get('BPSegBgFactor'),...
            aImData.Get('BPSegThreshold'),...
            aImData.Get('BPSegDarkOrBright'));
    case 'Segment_precondPSF3D'
        [oBw, oGray] = Segment_precondPSF3D(I,...
            aImData.Get('PCSegPSF'),...
            aImData.Get('PCSegPSFSizeXY'),...
            aImData.Get('PCSegPSFSizeZ'),...
            aImData.Get('PCSegBeta'),...
            aImData.Get('PCSegIterations'),...
            aImData.Get('PCSegThreshold'));
    case 'Segment_import'
        [oBlobs, oBw] = Segment_import(aImData, aFrame);
        return
    case 'Segment_import_binary'
        oBw = Segment_import_binary(aImData, aFrame);
    otherwise
        error('Unknown segmentation algorithm %s for 3D segmentation.',...
            aImData.Get('SegAlgorithm'))
end

% Transfer images from different segmentation steps to the output images.
stepNames = fieldnames(segSteps);
for i = 1:length(stepNames)
    oImages.(stepNames{i}) = segSteps.(stepNames{i});
end

% Add the z-stack before thresholding to the output images.
if ~isempty(oGray)
    oImages.gray = oGray;
end

% Fill holes in segmentation. Holes are filled in the individual z-slices.
if aImData.Get('SegFillHoles')
    for i = 1:size(oBw,3)
        oBw(:,:,i) = imfill(oBw(:,:,i), 'holes');
    end
end

% Remove small regions early to avoid unnecessary computation.
% TODO: Consider removing this if morphological operators are used.
if aImData.Get('SegMinArea') > 0
    oBw = bwareaopen(oBw, aImData.Get('SegMinArea'));
end

% Apply a watershed transform to break clusters of cells.
if ~strcmpi(aImData.Get('SegWatershed'), 'none')
    % Select what image feature to apply the transform to.
    switch lower(aImData.Get('SegWatershed'))
        case 'shape'
            prop = double(bwdist(~oBw));
        case 'anisotropicshape'
            prop = bwdistsc(~oBw, [1 1 aImData.voxelHeight]);
        case 'planeshape'
            bwPlane = sum(oBw,3)>0;
            distPlane = double(bwdist(~bwPlane));
            prop = repmat(distPlane,[1 1 size(oBw,3)]);
        case 'brightness'
            prop = I;
        case 'darkness'
            prop = -I;
        case 'intermediate'
            if ~isempty(oGray)
                prop = oGray;
            else
                prop = I;
            end
        otherwise
            error('Unknown value ''%s'' for the setting SegWatershed.',...
                aImData.Get('SegWatershed'))
    end
    
    [labels, oImages.watershed] = WatershedLabels(prop, oBw,...
        'Smooth', aImData.Get('SegWSmooth'),...
        'HMax', aImData.Get('SegWHMax'),...
        'Threshold', aImData.Get('SegWThresh'),...
        'UpSampling', aImData.Get('SegWUpSampling'));
else
    labels = bwlabeln(oBw);
end

% Apply a second watershed transform to break even more clusters of cells.
if ~strcmpi(aImData.Get('SegWatershed2'), 'none')
    % Select what image feature to apply the transform to.
    switch lower(aImData.Get('SegWatershed2'))
        case 'shape'
            prop2 = double(bwdist(labels == 0));
        case 'anisotropicshape'
            prop2 = bwdistsc(labels == 0, [1 1 aImData.voxelHeight]);
        case 'planeshape'
            bw = labels == 0;
            bwPlane = sum(bw,3)>0;
            distPlane = double(bwdist(~bwPlane));
            prop2 = repmat(distPlane,[1 1 size(bw,3)]);
        case 'brightness'
            prop2 = I;
        case 'darkness'
            prop2 = -I;
        case 'intermediate'
            if ~isempty(oGray)
                prop2 = oGray;
            else
                prop2 = I;
            end
        otherwise
            error('Unknown value ''%s'' for the setting SegWatershed2.',...
                aImData.Get('SegWatershed2'))
    end
    
    [labels, oImages.watershed2] = WatershedLabels(prop2, labels,...
        'Smooth', aImData.Get('SegWSmooth2'),...
        'HMax', aImData.Get('SegWHMax2'),...
        'Threshold', aImData.Get('SegWThresh2'),...
        'UpSampling', aImData.Get('SegWUpSampling2'));
end

% Remove ridges between watersheds by assigning the pixels to one of the
% adjacent regions. Adjacent cells should not have background pixels
% between them, and filling in the pixels increases the performance in the
% Cell Tracking Challenges.
if ~strcmpi(aImData.Get('SegWatershed'), 'none')
    ridges = oBw & labels == 0;
    labels = RemoveWatershedRidges(labels, ridges, prop);
end

oBlobs = Labels2Blobs(labels, aFrame);

% Remove blobs that are too small or too big.
if aImData.Get('SegMinArea') > 0 || aImData.Get('SegMaxArea') < inf
    areas = arrayfun(@(x)x.GetArea(), oBlobs);
    remove = areas < aImData.Get('SegMinArea') | areas > aImData.Get('SegMaxArea');
    oBlobs(remove) = [];
end

% Remove everything with a summed intensity below a threshold.
if aImData.Get('SegMinSumIntensity') > 0
    intensity = (I-min(I(:)))/255;
    sumIntensities = zeros(size(oBlobs));
    for i = 1:length(oBlobs)
        sumIntensities(i) = sum(oBlobs(i).GetPixels(intensity));
    end
    remove = sumIntensities < aImData.Get('SegMinSumIntensity');
    oBlobs(remove) = [];
end

% Apply a morphological operator to the segmentation masks of the
% individual cells. TODO: Consider placing this before regions are pruned.
if ~strcmpi(aImData.Get('SegCellMorphOp'), 'none')
    oBlobs = BlobMorphOp(...
        oBlobs,...
        aImData.Get('SegCellMorphOp'),...
        aImData.Get('SegCellMorphMask'),...
        aImData);
    
    % Fill holes in segmentation after closing.
    if strcmp(aImData.Get('SegCellMorphOp'), 'close') && aImData.Get('SegFillHoles')
        for i = 1:length(oBlobs)
            oBlobs(i).image = imfill(oBlobs(i).image, 'holes');
        end
    end
end

% Move the centroids to the local maxima of the watershed input.
if ~strcmpi(aImData.Get('SegWatershed'), 'none') && aImData.Get('SegWLocMaxCentroids')
    locmax = imregionalmax(prop);
    ind = find(locmax);
    [cx,cy,cz] = ind2sub(size(locmax),ind);
    blobLabels = labels(sub2ind(size(labels), cy, cx, cz));
    for cIndex = 1:length(blobLabels)
        bIndex = blobLabels(cIndex);
        if bIndex ~= 0  % There can be local maxima that are not segmented.
            [cxNew, cyNew, czNew] =...
                SubPixelMaximaWeighting3D(prop, cx(cIndex), cy(cIndex), cz(cIndex));
            oBlobs(bIndex).centroid = [cxNew, cyNew, czNew];
        end
    end
end

% Give the blobs indices.
for bIndex = 1:length(oBlobs)
    oBlobs(bIndex).index = bIndex;
end
end