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
% NumBlocks - The number of blocks that each dimension of the image should
%             be broken into before segmentation is applied. The dimensions
%             are in the order [yN, xN, zN].
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
[aX1, aX2, aY1, aY2, aZ1, aZ2, aPixelRegion, aNumBlocks] = GetArgs(...
    {'X1', 'X2', 'Y1', 'Y2', 'Z1', 'Z2', 'PixelRegion', 'NumBlocks'},...
    {1, aImData.imageWidth, 1, aImData.imageHeight, 1, aImData.numZ, {}, aImData.Get('SegNumBlocks')},...
    true, varargin);

if any(aNumBlocks > 1)
    oBlobs = Segment_generic3D_blocks(aImData, aFrame,...
        aNumBlocks,...
        aImData.Get('SegBlockMargin'));
    oBw = [];
    oGray = [];
    oImages = struct();
    return
end

if nargout > 3
    oImages = struct();
    % Variable used to capture the last output from methods.
    output = cell(1,1);
else
    % Variable used to NOT capture the last output from methods.
    output = cell(1,0);
end

if (isempty(aPixelRegion))
    I = aImData.GetDoubleZStack(aFrame,...
        'Channel', aImData.Get('SegChannel'),...
        'X1', aX1,...
        'X2', aX2,...
        'Y1', aY1,...
        'Y2', aY2,...
        'Z1', aZ1,...
        'Z2', aZ2);
else
    I = aImData.GetDoubleZStack(aFrame,...
        'Channel', aImData.Get('SegChannel'),...
        'PixelRegion', aPixelRegion,...
        'Z1', aZ1,...
        'Z2', aZ2);
end
    

% Apply intensity clipping.
if aImData.Get('SegClipping') < 1
    I(I > 255*aImData.Get('SegClipping')) = 255*aImData.Get('SegClipping');
end
% Apply intensity clipping from below.
if aImData.Get('SegClippingBelow') > 0
    I = max(0, I - aImData.Get('SegClippingBelow')*255);
end
if nargout > 3 && aImData.Get('SegClipping') < 1 || aImData.Get('SegClippingBelow') > 0
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
switch aImData.Get('SegAlgorithm')
    case 'Segment_threshold3D'
        [oBw, output{:}] = Segment_threshold3D(I,...
            aImData.Get('TSegThreshold'),...
            aImData.Get('TSegDarkOrBright'));
    case 'Segment_bandpass3D'
        [oBw, oGray, output{:}] = Segment_bandpass3D(I, aImData, aFrame,...
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
if (numel(output) > 0)
    stepNames = fieldnames(output{1});
    for i = 1:length(stepNames)
        oImages.(stepNames{i}) = output{1}.(stepNames{i});
    end
end

% Add the z-stack before thresholding to the output images.
if nargout > 3 && ~isempty(oGray)
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
    
    [labels, output{:}] = WatershedLabels(prop, oBw,...
        'Smooth', aImData.Get('SegWSmooth'),...
        'HMax', aImData.Get('SegWHMax'),...
        'Threshold', aImData.Get('SegWThresh'),...
        'UpSampling', aImData.Get('SegWUpSampling'),...
        'Store', all(aImData.Get('SegNumBlocks') == 1));
    if numel(output) > 0
        oImages.watershed = output{1};
    end
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
    
    [labels, output{:}] = WatershedLabels(prop2, labels,...
        'Smooth', aImData.Get('SegWSmooth2'),...
        'HMax', aImData.Get('SegWHMax2'),...
        'Threshold', aImData.Get('SegWThresh2'),...
        'UpSampling', aImData.Get('SegWUpSampling2'),...
        'Store', all(aImData.Get('SegNumBlocks') == 1));
    clear prop2
    if numel(output) > 0
        oImages.watershed2 = output{1};
    end
end

% Remove ridges between watersheds by assigning the pixels to one of the
% adjacent regions. Adjacent cells should not have background pixels
% between them, and filling in the pixels increases the performance in the
% Cell Tracking Challenges.
if ~strcmpi(aImData.Get('SegWatershed'), 'none')
    ridges = oBw & labels == 0;
    labels = RemoveWatershedRidges(labels, ridges, prop);
    clear ridges
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
    clear intensity
    remove = sumIntensities < aImData.Get('SegMinSumIntensity');
    oBlobs(remove) = [];
end
clear I

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