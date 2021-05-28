function [oBlobs, oBw, oGray, oImages] = Segment_generic(aImData, aFrame, varargin)
% Runs 2D segmentation algorithms together with pre- and post-processing.
%
% The function runs other segmentation functions and allows pre- and
% post-processing to be done before and after the main segmentation
% function is called. In the pre-processing step, the function can perform
% background subtraction, intensity normalization, intensity clipping,
% median filtering, and Gaussian smoothing. In the post-processing step,
% the function can fill holes, apply watershed transforms to break
% clusters, remove regions that are too small or too large, and apply
% morphological operations to the segmented cell regions. Using
% property/value inputs, a sub-image can be specified. This can save
% computation time when parameters are tweaked in SegmentationPlayer.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - The index of the frame to be segmented.
%
% Property/Value inputs:
% X1 - First pixel in x-dimension of sub-image to be segmented.
% X2 - Last pixel in x-dimension of sub-image to be segmented.
% Y1 - First pixel in y-dimension of sub-image to be segmented.
% Y2 - Last pixel in y-dimension of sub-image to be segmented.
%
% Settings in aImData (these are only a few important ones):
% SegAlgorithm - The name of the segmentation algorithm that will be used.
% SegBgSubAlgorihtm - Specifies what background subtraction algorithm
%                     should be used. The value 'none' gives no background
%                     subtraction.
% SegFillHoles - Fill holes in the segmentation mask if set to 1.
% SegMinArea - Minimum area of segmented regions in pixels. No regions are
%              removed if the value is 0.
% SegMaxArea - Maximum area of segmented regions in pixels. No regions are
%              removed if the value is inf.
%
% Outputs:
% oBlobs - Array of Blob objects representing the segmented regions.
% oBw - Binary segmentation mask where cell pixels are 1s.
% oGray - Image before the thresholding step which creates cell regions.
% oImages - Struct with fields for intermediate processing steps. The
%           fields are named after the processing steps. The images
%           included in oImages vary depending on the segmentation
%           algorithm and the pre- and post-processing algorithms used.
%
% See also:
% SegmentSequence, SegmentationPlayer, Segment_generic3D,
% Segment_localvariance, Segment_threshold, Segment_template,
% Segment_precondPSF, Segment_fibers, Segment_bandpass,
% Segment_ridgeconnection, Segment_import, Segment_import_binary

% Parse property/value inputs.
[aX1, aX2, aY1, aY2] = GetArgs(...
    {'X1', 'X2', 'Y1', 'Y2'},...
    {1, aImData.imageWidth, 1, aImData.imageHeight},...
    true, varargin);

oImages = struct();

% Read in image or compute a background subtracted version.
if strcmp(aImData.Get('SegBgSubAlgorithm'), 'none')
    I = aImData.GetIntensityCorrectedImage(aFrame, aImData.Get('SegLightCorrect'),...
        'Channel', aImData.Get('SegChannel'));
    if ~isempty(varargin)
        % Crop the input image if cropping instructions are given.
        I = I(aY1:aY2, aX1:aX2);
    end
    oImages.intensityCorrected = I;
else
    [I, bg] = BgSub_generic(aImData, aFrame,...
        'CorrectLight', aImData.Get('SegLightCorrect'),...
        'BgSubAtten', aImData.Get('SegBgSubAtten'));
    if ~isempty(varargin)
        % Crop the input image and the background image if cropping
        % instructions are given.
        I = I(aY1:aY2, aX1:aX2);
        bg = bg(aY1:aY2, aX1:aX2);
    end
    oImages.bgSub = (I + mean(bg(:))) / 255;
end

% Apply intensity clipping.
if aImData.Get('SegClipping') < 1
    I(I > 255*aImData.Get('SegClipping')) = 255*aImData.Get('SegClipping');
    oImages.clipped = I;
end

% Apply intensity clipping from below.
if aImData.Get('SegClippingBelow') > 0
    I = max(0, I - 255*aImData.Get('SegClippingBelow'));
    oImages.clipped = I;
end

% Apply median filtering to get rid of noise.
if any(aImData.Get('SegMedFilt') > 1)
    switch length(aImData.Get('SegMedFilt'))
        case 1
            medFilt = aImData.Get('SegMedFilt') * ones(1,2);
        case 2
            medFilt = aImData.Get('SegMedFilt');
        otherwise
            medFilt = aImData.Get('SegMedFilt');
            medFilt = medFilt(1:2);
    end
    
    I = medfilt2(I, medFilt);
end

% Apply Gaussian smoothing to get rid of noise before segmentation.
if aImData.Get('SegSmooth') > 0
    I = SmoothComp(I, aImData.Get('SegSmooth'));
end

% Perform top-hat filtering to remove non-uniform background illumination.
if ~isinf(aImData.Get('SegTopHatRadius'))
    I = imtophat(I, strel('disk', aImData.Get('SegTopHatRadius')));
end

% Execute main segmentation algorithm.
oGray = [];
segSteps = struct();
switch aImData.Get('SegAlgorithm')
    case 'Segment_localvariance'
        [oBw, oGray, segSteps] = Segment_localvariance(I,...
            aImData.Get('LVSegRegionShape'),...
            aImData.Get('LVSegRegionSize'),...
            aImData.Get('LVSegThreshold'),...
            aImData.Get('SegFillHoles'),...
            aImData.Get('LVSegErodeShape'),...
            aImData.Get('LVSegErodeSize'),...
            aImData.Get('SegMinHoleArea'));
    case 'Segment_threshold'
        [oBw, segSteps] = Segment_threshold(I,...
            aImData.Get('TSegThreshold'),...
            aImData.Get('TSegDarkOrBright'));
    case 'Segment_template'
        % The template matching segmentation does not work together with
        % the post segmentation processing, as the regions can border each
        % other.
        [oBlobs, oBw, oGray, segSteps] = Segment_template(aImData, aFrame, I,...
            aImData.Get('SegMinArea'),...
            aImData.Get('SegMaxArea'),...
            aImData.Get('TMSegTemplate'),...
            aImData.Get('TMSegThreshold'),...
            aImData.Get('TMSegCovThreshold'),...
            aImData.Get('TMSegMinSeparation'),...
            aImData.Get('TMSegComplementAlg'),...
            aImData.Get('TMSegComplementErode'),...
            aImData.Get('TMSegComplementOpen'),...
            varargin{:});
        % Transfer images from different segmentation steps to the output images.
        stepNames = fieldnames(segSteps);
        for i = 1:length(stepNames)
            oImages.(stepNames{i}) = segSteps.(stepNames{i});
        end
        return
    case 'Segment_precondPSF'
        [oBw, oGray] = Segment_precondPSF(I,...
            aImData.Get('PCSegPSF'),...
            aImData.Get('PCSegBeta'),...
            aImData.Get('PCSegIterations'),...
            aImData.Get('PCSegThreshold'));
    case 'Segment_fibers'
        [oBw, segSteps] = Segment_fibers(aImData, aFrame,...
            aImData.Get('FibSegMedFiltSize'),...
            aImData.Get('FibSegBGThreshold'),...
            aImData.Get('FibSegSmallestCrack'),...
            aImData.Get('SegChannel'),...
            aImData.Get('SegSmooth'),...
            aImData.Get('FibSegMergeThreshold'),...
            aImData.Get('FibSegSmallestUnmerged'),...
            aImData.Get('FibSegSmallestHole'),...
            aImData.Get('FibSegImOpenRadius'),...
            aImData.Get('FibSegShapeHmin'));
    case 'Segment_bandpass'
        [oBw, oGray, segSteps] = Segment_bandpass(I, aImData, aFrame,...
            aImData.Get('BPSegHighStd'),...
            aImData.Get('BPSegLowStd'),...
            aImData.Get('BPSegBgFactor'),...
            aImData.Get('BPSegThreshold'),...
            aImData.Get('BPSegDarkOrBright'));
    case 'Segment_ridgeconnection'
        [oBw, oGray, segSteps] = Segment_ridgeconnection(I,...
            aImData.Get('RCSegAlpha'),...
            aImData.Get('RCSegBeta'),...
            aImData.Get('RCSegSmooth'),...
            aImData.Get('RCSegScaling'),...
            aImData.Get('RCSegThreshold'),...
            aImData.Get('RCSegMaxDist'),...
            aImData.Get('RCSegMinVar'),...
            aImData.Get('RCSegMinArea'));
    case 'Segment_import'
        [oBlobs, oBw] = Segment_import(aImData, aFrame);
        return
    case 'Segment_import_binary'
        oBw = Segment_import_binary(aImData, aFrame);
    otherwise
        error('Unknown segmentation algorithm %s for 2D segmentation.',...
            aImData.Get('SegAlgorithm'))
end

% Transfer images from different segmentation steps to the output images.
stepNames = fieldnames(segSteps);
for i = 1:length(stepNames)
    oImages.(stepNames{i}) = segSteps.(stepNames{i});
end

% Add the image before thresholding to the output images.
if ~isempty(oGray)
    oImages.gray = oGray;
end

% Fill holes in segmentation.
if aImData.Get('SegFillHoles')
    if isinf(aImData.Get('SegMinHoleArea'))
        % Fill all holes.
        oBw = imfill(oBw,'holes');
    else
        % Fill only holes that are smaller than a threshold.
        withoutHoles = imfill(oBw,'holes');
        holes = withoutHoles & ~oBw;
        largeholes = bwareaopen(holes, round(aImData.Get('SegMinHoleArea')));
        oBw = withoutHoles & ~largeholes;
    end
end

% Remove small regions early to avoid unnecessary computation.
% TODO: Consider removing this if morphological operators are used.
if round(aImData.Get('SegMinArea')) > 0
    oBw = bwareaopen(oBw, round(aImData.Get('SegMinArea')));
end

% Apply a watershed transform to break clusters of cells.
if ~strcmpi(aImData.Get('SegWatershed'), 'none')
    % Select what image feature to apply the transform to.
    switch lower(aImData.Get('SegWatershed'))
        case {'shape', 'planeshape', 'anisotropicshape'}
            prop = double(bwdist(~oBw));
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
        'Threshold', aImData.Get('SegWThresh'));
else
    labels = bwlabel(oBw);
end

% Apply a second watershed transform to break clusters of cells even more.
if ~strcmpi(aImData.Get('SegWatershed2'), 'none')
    % Select what image feature to apply the transform to.
    switch lower(aImData.Get('SegWatershed2'))
        case {'shape', 'planeshape', 'anisotropicshape'}
            prop2 = double(bwdist(labels == 0));
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
        'Threshold', aImData.Get('SegWThresh2'));
end

% Remove ridges between watersheds by assigning the pixels to one of the
% adjacent regions. Adjacent cells should not have background pixels
% between them, and filling in the pixels increases the performance in the
% Cell Tracking Challenges.
if ~strcmpi(aImData.Get('SegWatershed'), 'none')
    ridges = oBw & labels == 0;
    labels = RemoveWatershedRidges(labels, ridges, prop);
end

% Create Blob objects from the segmentation labels.
oBlobs = Labels2Blobs(labels, aFrame);
oBw = labels > 0;

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
    [cy, cx] = find(locmax);
    indices = labels(sub2ind(size(labels), cy, cx));
    [cxNew, cyNew] = SubPixelMaximaWeighting(prop, cx, cy);
    for centroidIndex = 1:length(indices)
        bIndex = indices(centroidIndex);
        if bIndex ~= 0  % There can be local maxima that are not segmented.
            oBlobs(bIndex).centroid = [cxNew(centroidIndex) cyNew(centroidIndex)];
        end
    end
end

% Give the blobs indices.
for bIndex = 1:length(oBlobs)
    oBlobs(bIndex).index = bIndex;
end
end