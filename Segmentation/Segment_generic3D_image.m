function [oBlobs, oBw, oGray, oImages] = Segment_generic3D_image(aIm, aImData, aFrame)

oImages = struct();

% Apply intensity clipping.
if aImData.Get('SegClipping') < 1
    aIm(aIm > 255*aImData.Get('SegClipping')) = 255*aImData.Get('SegClipping');
end
% Apply intensity clipping from below.
if aImData.Get('SegClippingBelow') > 0
    aIm = max(0, aIm - aImData.Get('SegClippingBelow')*255);
end
if aImData.Get('SegClipping') < 1 || aImData.Get('SegClippingBelow') > 0
    oImages.clipped = aIm;
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
    aIm = medfilt3(aIm, medFilt);
end

% Apply Gaussian smoothing to get rid of noise.
% TODO: Make segmentation in the z-dimension different.
if aImData.Get('SegSmooth') > 0
    aIm = SmoothComp(aIm, aImData.Get('SegSmooth'));
end

% Perform top-hat filtering to remove non-uniform background illumination.
if ~isinf(aImData.Get('SegTopHatRadius'))
    % The top-hat filtering is done separately on each z-slice.
    for i = 1:size(aIm,3)
        aIm(:,:,i) = imtophat(aIm(:,:,i),...
            strel('disk', aImData.Get('SegTopHatRadius')));
    end
end

% Execute main segmentation algorithm.
oGray = [];
segSteps = struct();
switch aImData.Get('SegAlgorithm')
    case 'Segment_threshold3D'
        [oBw, segSteps] = Segment_threshold3D(aIm,...
            aImData.Get('TSegThreshold'),...
            aImData.Get('TSegDarkOrBright'));
    case 'Segment_bandpass3D'
        [oBw, oGray, segSteps] = Segment_bandpass3D(aIm, aImData, aFrame,...
            aImData.Get('BPSegHighStd'),...
            aImData.Get('BPSegLowStd'),...
            aImData.Get('BPSegBgFactor'),...
            aImData.Get('BPSegThreshold'),...
            aImData.Get('BPSegDarkOrBright'));
    case 'Segment_precondPSF3D'
        [oBw, oGray] = Segment_precondPSF3D(aIm,...
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
            prop = aIm;
        case 'darkness'
            prop = -aIm;
        case 'intermediate'
            if ~isempty(oGray)
                prop = oGray;
            else
                prop = aIm;
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
            prop2 = aIm;
        case 'darkness'
            prop2 = -aIm;
        case 'intermediate'
            if ~isempty(oGray)
                prop2 = oGray;
            else
                prop2 = aIm;
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
    intensity = (aIm-min(aIm(:)))/255;
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