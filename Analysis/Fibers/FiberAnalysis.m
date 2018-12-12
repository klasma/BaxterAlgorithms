function oFigures = FiberAnalysis(aSeqPaths, aFiberVersion, aChannel, aPlots, varargin)
% Creates analysis plots for segmented sections of muscle fibers.
%
% This function is used to analyze fluorescently stained sections of muscle
% fibers. The segmentation of the fibers needs to be performed by running
% tracking in the main GUI before this function is called. All image
% sequences are assumed to consist of a single time point, so that the
% tracking results only contain segmentation information. This function
% will analyze the segmentation and the fluorescent images and plot
% different results. The fluorescence intensity can either be measured at
% the border around the edge of the fiber, or in the entire fiber. There
% are plots with heatmaps of the fluorescence intensity in different
% fibers, and plots of the fiber size and fluorescence intensity.
% Information about the number of fibers, the fiber size and the fiber
% intensity can be saved to a csv file. It is also possible to save a csv
% file containing raw data for the fiber sizes. The fibers can be
% classified as positive or negative based on the fluorescence intensity.
% In that case, a mixture of two Gaussians is fitted to the intensities of
% the fibers. The lower Gaussian represents negative fibers and the higher
% Gaussian represents positive fibers. The information about which fibers
% are positive and negative can then be saved to a new tracking version,
% edited in the manual correction GUI for fibers, and then loaded in a new
% analysis session. It is also possible to create the information about
% positive and negative fibers from scratch in the manual correction GUI
% for fibers. The different distributions of sizes and intensities are
% estimated using kernel smoothing, and the function can also plot a couple
% of histograms. At the end of the function, there is code for additional
% histograms, which has been commented out.
%
% Inputs:
% aSeqPaths - Cell array of strings with the full path names of all image
%             sequences that should be included in the analysis. The image
%             sequences should have only one time point.
% aFiberVersion - Tracking version with the outlines of the fibers.
% aChannel - The name of the channel to analyze the fluorescence intensity
%            in.
% aPlots - Cell array with the names of plotting functions to run. Saving
%          to csv files is also specified in this cell array. The following
%          functions are available: 
%    'Analyzed fiber regions'
%    'Area per intensity'
%    'Expression distribution'
%    'Expression histograms'
%    'Expression vs size'
%    'Fiber outlines'
%    'Fiber statistics (csv-file)'
%    'Fiber size distribution'
%    'Fiber size histograms'
%    'Fiber sizes (csv-file)'
%    'Heat maps'
%    'Heat maps of positive fibers'
%    'Weighted expression distribution'
%    'Weighted fiber size distribution'
%
% Property/Value inputs:
% aImageBinning - If this is set to 'conditions', the fibers in each
%                 experimental condition will be analyzed as a group.
%                 Otherwise the image sequences will be analyzed
%                 separately. The default is to analyze the image sequences
%                 separately.
% aBorderWidth - The width (in pixels) of the border region of each fiber
%                in which the fluorescence intensity will be measured. The
%                default is inf, which means that the entire fiber is used
%                to compute the intensity.
% aAnalyzeOnlyWholeFibers - If this is true, only fibers which do not touch
%                           the image border are included in the analysis.
%                           The default is true.
% aStatistic - The statistical operator that will be applied to the pixel
%              values in the border region, to compute the fluorescence
%              intensity. The default is 'mean', but 'median' can also be
%              used.
% aThreshold - The type of threshold that will be used to find positive
%              fibers. The available alternatives are 'no', 'auto', and
%              'manual'. 'no' means that all fibers are treated as
%              positive. 'auto' means that a threshold will be computed by
%              fitting a mixture of two Gaussians to the intensity values.
%              'manual' means that the information about positive and
%              negative fibers is taken from the saved segmentation
%              results. This lets the user specify which fibers are
%              positive. The default is 'no'.
% aGlobalThreshold - If this is set to true, the same threshold will be
%                    applied to all images when aThreshold is 'auto'.
%                    Otherwise a separate threshold is computed for each
%                    image.
% aNormalize - This specifies if the fluorescence intensities should be
%              normalized by the automatic intensity thresholds. The
%              default is true.
% aSaveVersion - If aThreshold is 'auto' and this parameter is specified,
%                the fibers will be labeled as positive or negative and
%                saved to a tracking version with this name.
% aStatisticsCsvPath - The full path of a csv-file that statistics about
%                      the fibers will be saved to.
% aSizeCsvPath - The full path of a csv-file that the areas of all fibers
%                will be saved to.
%
% Outputs:
% oFigures - Array of all figures with plots that have been generated by
%            the function.
%
% See also:
% FiberAnalysisGUI, TrackingGUI, CentralNuclei, CentralNucleiGUI,
% ManualFiberCorrectionPlayer

% Parse property/value inputs.
[...  % Input variables.
    aImageBinning,...
    aBorderWidth,...
    aAnalyzeOnlyWholeFibers,...
    aStatistic,...
    aThreshold,...
    aGlobalThreshold,...
    aNormalize,...
    aSaveVersion,...
    aStatisticsCsvPath,...
    aSizeCsvPath...
    ] = GetArgs({...  % Parameter names.
    'ImageBinning',...
    'BorderWidth',...
    'AnalyzeOnlyWholeFibers',...
    'Statistic',...
    'Threshold',...
    'GlobalThreshold',...
    'Normalize',...
    'SaveVersion',...
    'StatisticsCsvPath',...
    'SizeCsvPath'...
    },{...  % Default parameter values.
    'none',...
    inf,...
    true,...
    'mean',...
    'no',...
    false,...
    true,...
    [],...
    [],...
    []...
    }, true, varargin);

if strcmpi(aThreshold, 'no')
    % Remove alternatives which require thresholding.
    aNormalize = false;
    aPlots = setdiff(aPlots, 'Heat maps of positive fibers');
end

% String describing which fibers are included in the analysis.
if strcmpi(aThreshold, 'no')
    whatFibers = '';
else
    whatFibers = [aChannel ' positive '];
end

% String describing the intensity reference used.
if aNormalize
    intensityReference = 'threshold';
else
    intensityReference = 'saturation';
end

[~, seqDirs] = FileParts2(aSeqPaths);

% The following variables have one cell for each image sequence. Later, the
% variables will be changed so that they instead have one cell for each
% experimental condition.
fibers = cell(size(aSeqPaths));              % Cell objects representing the fibers.
notFibers = cell(size(aSeqPaths));           % Cell objects representing background features or other structures.
intensities = cell(size(aSeqPaths));         % Fluorescence intensity for each fiber.
fluorescence = cell(size(aSeqPaths));        % Fluorescence intensity summed over all pixels, for each fiber.
areas = cell(size(aSeqPaths));               % The area of each fiber in pixels.
expressionHeatmaps = cell(size(aSeqPaths));  % Heat maps of average fiber fluorescence intensity.
borderImages = cell(size(aSeqPaths));        % Binary images with the pixels used to compute the fluorescence intensity.
imDatas = cell(size(aSeqPaths));             % ImageData objects for all image sequences.
conditions = cell(size(aSeqPaths));          % The condition that every image belongs to.
thresholds = cell(size(aSeqPaths));          % Intensity thresholds above which fibers are considered to be positive.

% Collect analysis data for all image sequences, one at a time.
for i = 1:length(aSeqPaths)
    fprintf('Processing image %d / %d\n', i, length(aSeqPaths))
    
    imData = ImageData(aSeqPaths{i});
    imDatas{i} = imData;
    
    conditions{i} = imData.condition;
    
    im_marker = imData.GetDoubleImage(1, 'Channel', aChannel) / 255;
    
    % Load fibers.
    fibers{i} = LoadCells(aSeqPaths{i}, aFiberVersion)';
    notFibers{i} = NotCells(fibers{i});
    fibers{i} = AreCells(fibers{i});
    if aAnalyzeOnlyWholeFibers
        fibers{i} = fibers{i}(~IsCellOnBorder(fibers{i}, imData));
    end
    labels = ReconstructSegments(imData, fibers{i}, 1);
    cellMask = labels > 0;
    membraneDist = double(bwdist(cellMask == 0));
    
    % Initialize variables.
    intensities{i} = zeros(length(fibers{i}),1);
    areas{i} = zeros(length(fibers{i}),1);
    fluorescence{i} = zeros(length(fibers{i}),1);
    expressionHeatmaps{i} = -ones(size(im_marker));
    borderImages{i} = zeros(size(im_marker));
    
    % Extract data from the images.
    for j = 1:length(fibers{i})
        blob = fibers{i}(j).blob;
        
        bb = blob.boundingBox;
        mask = blob.image;
        
        % Find indices of all pixels in the fiber.
        [masky, maskx] = find(mask);
        y = masky + bb(2) - 0.5;
        x = maskx + bb(1) - 0.5;
        index = y + (x-1)*imData.imageHeight;
        
        % Find indices of all pixels near the edge of the fiber.
        dist = membraneDist(index);
        borderIndex = index(dist <= aBorderWidth);
        
        switch aStatistic
            case 'mean'
                intensities{i}(j) = mean(im_marker(borderIndex));
            case 'median'
                intensities{i}(j) = median(im_marker(borderIndex));
            otherwise
                error('Statistic has to be either ''mean'' or ''median''.')
        end
        
        areas{i}(j) = sum(blob.image(:));
        fluorescence{i}(j) = areas{i}(j) * intensities{i}(j);
        expressionHeatmaps{i}(index) = intensities{i}(j);
        borderImages{i}(borderIndex) = 1;
    end
end

% An array of unique condition names.
conditionNames = unique(conditions);

if strcmpi(aThreshold, 'auto')
    % Find positive fibers by thresholding the fluorescence intensity. The
    % threshold is found by fitting a Gaussian mixture with two components
    % to the fiber intensities using the EM-algorithm. The threshold is
    % then set to the value where the two Gaussians have the same
    % probability density.
    
    if aGlobalThreshold
        % Use the same threshold for all images.
        
        % Reset the random number generator so that the Gaussian mixture
        % fit becomes reproducible.
        reset(RandStream.getGlobalStream);
        
        % The EM algorithm sometimes crashes without regularization and can
        % give two almost identical components if a single replicate is
        % used.
        try
            % The warning about convergence failure does not seem to matter
            % to the results.
            warning('off', 'stats:gmdistribution:FailedToConvergeReps')
            gmdist = fitgmdist(cat(1,intensities{:}), 2, 'Replicate', 5);
            warning('on', 'stats:gmdistribution:FailedToConvergeReps')
            gmSuccess = true;
        catch
            gmSuccess = false;
        end
        
        if gmSuccess
            % Gaussian for negative fibers.
            [mu1, index1] = min(gmdist.mu);
            p1 = gmdist.PComponents(index1);
            sigma1 = gmdist.Sigma(:,:,index1);
            
            % Gaussian for positive fibers.
            [mu2, index2] = max(gmdist.mu);
            p2 = gmdist.PComponents(index2);
            sigma2 = gmdist.Sigma(:,:,index2);
            
            % Find the intensity where the Gaussians have the same value.
            zerofun = @(x) p1*normpdf(x,mu1,sqrt(sigma1)) -...
                p2*normpdf(x,mu2,sqrt(sigma2));
            globalThreshold = fzero(zerofun, (mu1+mu2)/2);
        else
            % Make all fibers positive if the EM-algorithm did not
            % converge.
            globalThreshold = inf;
        end
        
        for i = 1:length(aSeqPaths)
            thresholds{i} = globalThreshold;
        end
    else
        % Use different thresholds on the different images.
        
        for i = 1:length(aSeqPaths)
            % Reset the random number generator so that the Gaussian
            % mixture fit becomes reproducible.
            reset(RandStream.getGlobalStream);
            
            % The EM algorithm sometimes crashes without regularization and
            % can give two almost identical components if a single
            % replicate is used.
            try
                % The warning about convergence failure does now seem to
                % matter to the results.
                warning('off', 'stats:gmdistribution:FailedToConvergeReps')
                gmdist = fitgmdist(intensities{i}, 2,...
                    'Replicate', 5, 'Regularize', 1E-9);
                warning('on', 'stats:gmdistribution:FailedToConvergeReps')
                gmSuccess = true;
            catch
                gmSuccess = false;
            end
            
            if gmSuccess
                % Gaussian for negative fibers.
                [mu1, index1] = min(gmdist.mu);
                p1 = gmdist.PComponents(index1);
                sigma1 = gmdist.Sigma(:,:,index1);
                
                % Gaussian for positive fibers.
                [mu2, index2] = max(gmdist.mu);
                p2 = gmdist.PComponents(index2);
                sigma2 = gmdist.Sigma(:,:,index2);
                
                % Find the intensity where the Gaussians have the same
                % value.
                zerofun = @(x) p1*normpdf(x,mu1,sqrt(sigma1)) -...
                    p2*normpdf(x,mu2,sqrt(sigma2));
                thresholds{i} = fzero(zerofun, (mu1+mu2)/2);
            else
                % Make all fibers positive if the EM-algorithm did not
                % converge.
                thresholds{i} = inf;
            end
        end
    end
    
    % Remove fibers below the thresholds from the analysis.
    for i = 1:length(aSeqPaths)
        remove = intensities{i} < thresholds{i};
        
        % Save the fibers after they have been classified as positive or
        % negative.
        if ~isempty(aSaveVersion)
            saveFibers = fibers{i};
            for j = 1:length(saveFibers)
                saveFibers(j).positive = ~remove(j);
                saveFibers(j).coloring = 'Positive/Negative';
            end
            saveFibers = [saveFibers; notFibers{i}]';
            SaveCells(saveFibers, aSeqPaths{i}, aSaveVersion)
        end
        
        fibers{i}(remove) = [];
        areas{i}(remove) = [];
        fluorescence{i}(remove) = [];
        intensities{i}(remove) = [];
        
        % Normalize by the threshold.
        if aNormalize
            intensities{i} = intensities{i} / thresholds{i};
            expressionHeatmaps{i} = expressionHeatmaps{i} / thresholds{i};
        end
        
        % The threshold has to be normalized as well.
        thresholds{i} = 1;
    end
elseif strcmpi(aThreshold, 'manual')
    % Take the information about positive and negative fibers from the
    % saved file. The information can be created either by saving a
    % tracking version in this GUI, or by specifying which cells are
    % positive in the manual correction GUI.
    
    % Remove negative fibers from the analysis.
    for i = 1:length(aSeqPaths)
        if ~isempty(fibers{i})
            remove = ~[fibers{i}.positive];
            fibers{i}(remove) = [];
            areas{i}(remove) = [];
            fluorescence{i}(remove) = [];
            intensities{i}(remove) = [];
        end
    end
end

% Save csv file with statistics.
if any(strcmp(aPlots, 'Fiber statistics (csv-file)'))
    totalData = {};
    for i = 1:length(conditionNames)
        % Indices of image sequences in the condition of interest.
        seqIndices = find(strcmp(conditions, conditionNames{i}));
        
        % Create column titles.
        data = cell(length(seqIndices)+5,6);
        data(1,1) = conditionNames(i);
        data(2,:) = {...
            ''...
            'Number of fibers'...
            'Fiber area'...
            ['Fiber ' aChannel]...
            ['Fiberpixel ' aChannel]...
            ['Sum fiberpixel ' aChannel]};
        
        % Allocate arrays that will be used to compute averages over the
        % image sequences.
        counts = zeros(length(seqIndices), 1);
        avgArea = zeros(length(seqIndices), 1);
        cover = zeros(length(seqIndices), 1);
        avgIntensity = zeros(length(seqIndices), 1);
        avgFiberIntensity = zeros(length(seqIndices), 1);
        
        % Compute statistics for the individual image sequences.
        for j = 1:length(seqIndices)
            index = seqIndices(j);
            
            counts(j) = length(intensities{index});
            avgArea(j) = mean(areas{index});
            cover(j) = sum(areas{index}) /...
                (imDatas{index}.imageWidth*imDatas{index}.imageHeight);
            avgIntensity(j) = intensities{index}' *...
                areas{index} / sum(areas{index});
            avgFiberIntensity(j) = mean(intensities{index});
            
            data(j+2,:) = {seqDirs{index},...
                num2str(counts(j)),...
                num2str(avgArea(j)),...
                num2str(avgIntensity(j)),...
                num2str(avgFiberIntensity(j)),...
                num2str(avgIntensity(j)*cover(j))};
        end
        
        % NaN-values of image sequences with no fibers would make the
        % combined values NaN. Therefore the NaN-values are replaced by
        % zeros.
        avgArea(isnan(avgArea)) = 0;
        avgFiberIntensity(isnan(avgFiberIntensity)) = 0;
        avgIntensity(isnan(avgIntensity)) = 0;
        
        % Add combined results for all image sequences.
        data(length(seqIndices)+4,:) = {...
            'Combined',...
            num2str(mean(counts)),...
            num2str(avgArea'*counts/sum(counts)),...
            num2str(avgFiberIntensity'*counts/sum(counts)),...
            num2str(avgIntensity'*cover/sum(cover)),...
            num2str(mean(avgIntensity.*cover))};
        
        % Concatenate the statistics for different conditions.
        if i==1
            totalData = data;
        else
            totalData = vertcat(totalData, data); %#ok<AGROW>
        end
    end
    
    % Add explanations saying how the different results were computed.
    explanations = {...
        ''
        '"Number of fibers: The number of fibers in each image."'
        '"Fiber area: The average fiber area in pixels."'
        sprintf(['"Fiber %s: The average fiber intensity in the %s channel, '...
        'divided by the saturation intensity. Each fiber intensity is a %s '...
        'over fiber pixels."'], aChannel, aChannel, aStatistic)
        sprintf(['"Fiberpixel %s: The average intensity in the %s channel '...
        'for pixels inside fibers, divided by the saturation intensity."'],...
        aChannel, aChannel)
        sprintf(['"Sum fiberpixel %s: The sum of %s pixel intensities over '...
        'all fiber pixels, divided by the saturation intensity and the '...
        'image area."'], aChannel, aChannel);
        ''
        ['"In the ''Combined'' rows, all images in each condition have been '...
        'analyzed together."']
        ['"For ''Number of fibers'', an average value is given and for the '...
        'other parameters the fibers from all images are analyzed together."']};
    if ~strcmpi(aThreshold, 'no')
        explanations = [explanations
            {''
            '"Only positive fibers are included in the tables."'}];
    end
    
    if aAnalyzeOnlyWholeFibers
        includedOrNot = '';
    else
        includedOrNot = 'NOT';
    end
    explanations = [explanations
        {''
        ['"Fibers that touch the image border have ' includedOrNot ...
        ' been excluded."']}];
    
    totalData = [totalData; explanations cell(size(explanations,1),5)];
    
    if isempty(aStatisticsCsvPath)
        % Use the default filename.
        file = fullfile(imDatas{1}.GetAnalysisPath(),...
            ['Statistics ' aChannel '.csv']);
    else
        % Use a filename specified by the caller.
        file = aStatisticsCsvPath;
    end
    
    WriteDelimMat(file, totalData, ',')
end

% Save csv file with the sizes of all fibers.
if any(strcmp(aPlots, 'Fiber sizes (csv-file)'))
    fiberSizeData = {};
    for i = 1:length(conditionNames)
        % Indices of image sequences in the condition of interest.
        seqIndices = find(strcmp(conditions, conditionNames{i}));
        
        % Extract fiber sizes for the individual image sequences.
        for j = 1:length(seqIndices)
            index = seqIndices(j);
            
            % Add the areas of all fibers that are not on the border.
            next = size(fiberSizeData,2) + 1;
            fiberSizeData{3,next} = seqDirs{index}; %#ok<AGROW>
            for k = 1:length(areas{index})
                fiberSizeData{k+3,next} = num2str(areas{index}(k));
            end
        end
    end
    
    if aAnalyzeOnlyWholeFibers
        includedOrNot = '';
    else
        includedOrNot = 'NOT';
    end
    fiberSizeData{1,1} = ['"Areas for individual fibers (in pixels). '...
        'Note: Fibers that touch the image border have ' includedOrNot ...
        ' been removed."'];
    
    if isempty(aSizeCsvPath)
        % Use the default filename.
        file = fullfile(imDatas{1}.GetAnalysisPath(), 'Fiber sizes.csv');
    else
        % Use a filename specified by the caller.
        file = aSizeCsvPath;
    end
    
    WriteDelimMat(file, fiberSizeData, ',')
end

% The rest of this method does plotting and should not be executed if there
% is nothing to plot.
if isempty(setdiff(aPlots,...
        {'Fiber statistics (csv-file)', 'Fiber sizes (csv-file)'}))
    oFigures = [];
    return
end

if strcmp(aImageBinning, 'conditions')
    % Group the analysis data by experimental condition.
    
    % Put images in cell arrays, to avoid concatenating them.
    fibers = cellfun(@(x){x}, fibers,...
        'UniformOutput', false);
    expressionHeatmaps = cellfun(@(x){x}, expressionHeatmaps,...
        'UniformOutput', false);
    borderImages = cellfun(@(x){x}, borderImages,...
        'UniformOutput', false);
    
    % Group all analysis variables by experimental condition.
    fibers = BunchByCondition(fibers, conditions, conditionNames);
    intensities = BunchByCondition(intensities, conditions, conditionNames);
    fluorescence = BunchByCondition(fluorescence, conditions, conditionNames); %#ok<NASGU>
    areas = BunchByCondition(areas, conditions, conditionNames);
    expressionHeatmaps = BunchByCondition(expressionHeatmaps, conditions, conditionNames);
    borderImages = BunchByCondition(borderImages, conditions, conditionNames);
    imDatas = BunchByCondition(imDatas, conditions, conditionNames);
    
    numberOfImages = cellfun(@length, imDatas);
    
    % Labels for figure legends.
    labels = conditionNames;
else
    % Keep separate analysis data for the individual images.
    
    % Put images in cell arrays to get the same format as when the data is
    % grouped by experimental condition.
    fibers = cellfun(@(x){x}, fibers,...
        'UniformOutput', false);
    expressionHeatmaps = cellfun(@(x){x}, expressionHeatmaps,...
        'UniformOutput', false);
    borderImages = cellfun(@(x){x}, borderImages,...
        'UniformOutput', false);
    
    numberOfImages = ones(length(seqDirs),1);
    
    % Labels for figure legends.
    labels = seqDirs;
end

% Display an error message if all labels do not have fibers to be analyzed.
for i = 1:length(fibers)
    fibersWithLabel = cat(1, fibers{i}{:});
    if isempty(fibersWithLabel)
        errordlg(...
            sprintf('The label "%s" has no %sfibers.', labels{i}, whatFibers),...
            'Cannot analyze fibers')
        oFigures = [];
        return
    end
end

% Lists of colors, styles and markers associated with different
% experimental conditions or images.
colors = {...
    [1    0    0],...
    [0    0    1],...
    [0    0.5  0],...
    [0    0.75 0.75],...
    [0.75 0    0.75],...
    [0.75 0.75 0],...
    [0.25 0.25 0.25]};
styles = {'-', ':', '--', '-.'};
styles = arrayfun(@(x)repmat(x,1,length(colors)), styles, 'UniformOutput', false);
styles = [styles{:}];
markers = {'v', 'o', 's'};

% Duplicate the colors, styles and markers so that we are sure to have one
% set for each condition or image.
colors = repmat(colors, 1, length(labels));
styles = repmat(styles, 1, length(labels));
markers = repmat(markers, 1, length(labels));

oFigures = [];

% Display the fiber outlines on top of the original merged images.
if any(strcmp(aPlots, 'Fiber outlines'))
    for i = 1:length(imDatas)
        caption = ['Fiber outlines shown on top of the fluorescence images in '...
            labels{i} '.'];
        if ~strcmpi(aThreshold, 'no')
            caption = [caption ' The ' whatFibers...
                'fibers are outlined in gray.']; %#ok<AGROW>
        end
        fig = figure('Name', ['Fiber outlines ' labels{i}],...
            'Units', 'normalized',...
            'Position', [0.1 0.1 0.8 0.8],...
            'UserData', caption);
        AddCaption(fig, caption)
        oFigures = [oFigures; fig]; %#ok<AGROW>
        
        numRows = floor(sqrt(length(imDatas{i})));
        numCols = ceil(length(imDatas{i}) / numRows);
        for j = 1:length(imDatas{i})
            ax = SubPlotTight(numRows, numCols, j, 'Margins', 0.8);
            
            % Show the image.
            merge = imDatas{i}(j).GetShownImage(1,...
                'Channels', 1:length(imDatas{i}(j).channelNames));
            imshow(merge, 'Parent', ax)
            hold(ax, 'on')
            
            % Plot fiber outlines in green.
            for fiberIndex = 1:length(fibers{i}{j})
                % Make the outlines green.
                fibers{i}{j}(fiberIndex).color = [0.5 0.5 0.5];
            end
            PlotOutlines(ax, fibers{i}{j}, 1, 1,...
                'Options', struct('LineWidth', 0.5))
            
            title(ax, SpecChar(imDatas{i}(j).GetSeqDir(), 'matlab'),...
                'FontSize', 8)
        end
    end
end


% Plot heat maps.
if any(strcmp(aPlots, 'Heat maps'))
    % Concatenate all pixels.
    pixels = cat(1,expressionHeatmaps{:});
    pixels = cellfun(@(x)x(:), pixels, 'UniformOutput', false);
    pixels = cat(1,pixels{:});
    
    % Limits for the color map.
    cmin = 0;
    cmax = max(pixels);
    
    for i = 1:length(expressionHeatmaps)
        caption = ['Heat map of the ' aChannel ' expression relative to '...
            intensityReference ', of the individual fibers in ' labels{i} '.'];
        if ~strcmpi(aThreshold, 'no')
            caption = [caption ' The ' aChannel...
                ' positive fibers are outlined in red.']; %#ok<AGROW>
        end
        fig = figure('Name', ['Heat maps ' labels{i}],...
            'Units', 'normalized',...
            'Position', [0.1 0.1 0.8 0.8],...
            'UserData', caption);
        AddCaption(fig, caption)
        oFigures = [oFigures; fig]; %#ok<AGROW>
        
        % Apply a jet colormap, where black has been added in the
        % beginning. Black is used for the background.
        colormap(fig, [0 0 0; jet(255)])
        
        numRows = floor(sqrt(length(expressionHeatmaps{i})));
        numCols = ceil(length(expressionHeatmaps{i}) / numRows);
        for j = 1:length(expressionHeatmaps{i})
            ax = SubPlotTight(numRows, numCols, j, 'Margins', 0.8);
            
            % Display the heatmap.
            heatmap = expressionHeatmaps{i}{j};
            % Make the background black.
            heatmap(heatmap < 0) = cmin-(cmax-cmin)/254;
            imagesc(heatmap, 'Parent', ax)
            
            % Plot the fiber outlines in red.
            if ~strcmpi(aThreshold, 'no')
                hold(ax, 'on')
                % Make all the fibers red.
                for fiberIndex = 1:length(fibers{i}{j})
                    fibers{i}{j}(fiberIndex).color = [1 0 0];
                end
                PlotOutlines(ax, fibers{i}{j}, 1, 1,...
                    'Options', struct('LineWidth', 0.1))
            end
            
            % Set the limits for the colormap.
            set(ax, 'CLim', [cmin-(cmax-cmin)/254 cmax])
            
            colorbar(ax)
            axis(ax, 'off')
            axis(ax, 'square')
            title(ax, SpecChar(imDatas{i}(j).GetSeqDir(), 'matlab'),...
                'FontSize', 8)
        end
    end
end


% Plot a heat map with only positive fibers. Negative fibers are gray.
if any(strcmp(aPlots, 'Heat maps of positive fibers'))
    
    % Concatentate all pixels.
    pixels = cat(1,expressionHeatmaps{:});
    pixels = cellfun(@(x)x(:), pixels, 'UniformOutput', false);
    pixels = cat(1,pixels{:});
    
    % Limits for the color map.
    cmin = 0;
    cmax = max(pixels);
    
    for i = 1:length(expressionHeatmaps)
        caption = ['Heat map of the ' aChannel ' expression relative to '...
            intensityReference ', of the positive fibers in ' labels{i} '.'...
            ' The negative fibers are shown in gray.'];
        fig = figure(...
            'Name', ['Heat maps of positive fibers ' labels{i}],...
            'Units', 'normalized',...
            'Position', [0.1 0.1 0.8 0.8],...
            'UserData', caption);
        AddCaption(fig, caption)
        oFigures = [oFigures; fig]; %#ok<AGROW>
        
        % Jet colormap where black and gray have been added to the
        % beginning. Black is used for background and gray is used for
        % negative fibers.
        colormap([0 0 0; 0.25 0.25 0.25; jet(254)])
        
        numRows = floor(sqrt(length(expressionHeatmaps{i})));
        numCols = ceil(length(expressionHeatmaps{i}) / numRows);
        for j = 1:length(expressionHeatmaps{i})
            ax = SubPlotTight(numRows, numCols, j, 'Margins', 0.8);
            
            % Binary image where positive fiber pixels are 1.
            positiveMask = ReconstructSegments(imDatas{i}(j), fibers{i}{j}, 1) > 0;
            
            positiveMap = expressionHeatmaps{i}{j};
            % Make the background black.
            positiveMap(positiveMap < 0) = cmin-2*(cmax-cmin)/253;
            % Make the negative fibers gray.
            positiveMap(~positiveMask & positiveMap >= 0) = cmin-(cmax-cmin)/253;
            
            imagesc(positiveMap, 'Parent', ax)
            
            % Set the limits for the colormap.
            set(ax, 'CLim', [cmin-2*(cmax-cmin)/253 cmax])
            
            colorbar(ax)
            axis(ax, 'off')
            axis(ax, 'square')
            title(ax, SpecChar(imDatas{i}(j).GetSeqDir(), 'matlab'),...
                'FontSize', 8)
        end
    end
end


% Display the parts of the fibers that were used to compute fluorescence
% intensities. These regions are highlighted by adding a gray component to
% the channel of interest.
if any(strcmp(aPlots, 'Analyzed fiber regions'))
    for i = 1:length(borderImages)
        caption = ['The regions in the fibers, for which the ' aChannel...
            ' fluorescence intensity was computed in ' labels{i} '.'];
        fig = figure('Name', ['Analyzed fiber regions ' labels{i}],...
            'Units', 'normalized',...
            'Position', [0.1 0.1 0.8 0.8],...
            'UserData', caption);
        AddCaption(fig, caption)
        oFigures = [oFigures; fig]; %#ok<AGROW>
        
        numRows = floor(sqrt(length(borderImages{i})));
        numCols = ceil(length(borderImages{i}) / numRows);
        for j = 1:length(borderImages{i})
            % Create a gray image showing the regions of interest.
            merge = repmat(borderImages{i}{j}*0.1, [1 1 3]);
            
            % Add a color image with the channel of interest.
            color = imDatas{i}(j).GetColor(aChannel);
            for ci = 1:3
                if color(ci) > 0
                    merge(:,:,ci) = merge(:,:,ci) +...
                        imDatas{i}(j).GetDoubleImage(1, 'Channel', aChannel) / 255;
                end
            end
            
            ax = SubPlotTight(numRows, numCols, j, 'Margins', 0.8);
            imshow(merge, 'Parent', ax)
            title(ax, SpecChar(imDatas{i}(j).GetSeqDir(), 'matlab'),...
                'FontSize', 8)
        end
    end
end


% Plot a kernel smoothing density over the fluorescence expression in
% different fibers.
if any(strcmp(aPlots, 'Expression distribution'))
    caption = ['Distribution of the ' aChannel...
        ' fluorescence intensity of the ' whatFibers...
        'fibers, estimated using kernel smoothing.'];
    fig = figure('Name', 'Expression distribution',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    % Find an appropriate width for the smoothing kernel by pooling all
    % data.
    [~, ~, ksWidth] = ksdensity(cat(1,intensities{:})+eps(0),...
        'support', 'positive');
    
    legendStrings = {};
    for i = 1:length(intensities)
        if isempty(intensities{i})
            continue
        end
        
        [f, xi] = ksdensity(intensities{i}+eps(0),...
            'Width', ksWidth, 'Npoints', 1000, 'support', 'positive');
        
        plot(ax, xi, f,...
            'Color', colors{i},...
            'LineStyle', styles{i},...
            'LineWidth', 2)
        
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    
    grid(ax, 'on')
    xlabel(ax, [aChannel ' expression relative to ' intensityReference])
    ylabel(ax, 'Kernel smoothing density estimate')
    legend(ax, legendStrings)
end

% Plot a weighted kernel smoothing density over the intensities in
% different fibers. The areas of the fibers are used as weights. This can
% be used to look at how much of the tissue has fluorescence intensities of
% different levels.
if any(strcmp(aPlots, 'Weighted expression distribution'))
    caption = ['Weighted distribution of the ' aChannel...
        ' fluorescence intensity of the ' whatFibers 'fibers, where '...
        'every fiber is weighted by its area. The distribution was '...
        'estimated using weighted kernel smoothing.'];
    fig = figure('Name', 'Weighed expression distribution',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    % Find an appropriate width for the smoothing kernel by pooling all
    % data.
    all_areas = cat(1,areas{:});
    all_weights = all_areas / sum(all_areas);
    all_intensities = cat(1,intensities{:});
    [~, ~, ksWidth] = ksdensity(all_intensities+eps(0),...
        'Weights', all_weights, 'support', 'positive');
    
    legendStrings = {};
    for i = 1:length(intensities)
        if isempty(intensities{i})
            continue
        end
        
        weights = areas{i} / sum(areas{i});
        [f, xi] = ksdensity(intensities{i}+eps(0),...
            'Weights', weights,...
            'Width', ksWidth,...
            'Npoints', 1000,...
            'support', 'positive');
        
        plot(ax, xi, f,...
            'Color', colors{i},...
            'LineStyle', styles{i},...
            'LineWidth', 2)
        
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    
    grid(ax, 'on')
    xlabel(ax, [aChannel ' expression relative to ' intensityReference])
    ylabel(ax, 'Kernel smoothing density estimate, weighted by area')
    legend(ax, legendStrings)
end


% Plot a normalized weighted kernel smoothing density of the fluorescence
% expression in different fibers. The fibers are weighted by their areas,
% and the normalization is done so that the density integrates to the
% fraction of the images that is covered by fibers. This can be used to
% look at expression levels in positive fibers.
if any(strcmp(aPlots, 'Area per intensity'))
    caption = ['The fiber area belonging to ' whatFibers 'fibers with '...
        'different ' aChannel ' fluorescence intensities. The '...
        'distribution was computed using kernel smoothing and was then '...
        'scaled so that it integrates to the total ' whatFibers...
        'fiber area divided by the total image area.'];
    fig = figure('Name', 'Area per intensity',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    % Find an appropriate width for the smoothing kernel by pooling all
    % data.
    all_areas = cat(1,areas{:});
    all_weights = all_areas / sum(all_areas);
    all_intensities = cat(1,intensities{:});
    [~, ~, ksWidth] = ksdensity(all_intensities+eps(0),...
        'Weights', all_weights, 'support', 'positive');
    
    legendStrings = {};
    for i = 1:length(intensities)
        if isempty(intensities{i})
            continue
        end
        
        weights = areas{i} / sum(areas{i});
        [f, xi] = ksdensity(intensities{i}+eps(0),...
            'Weights', weights,...
            'Width', ksWidth,...
            'Npoints', 1000,...
            'support', 'positive');
        
        % Normalize the distribution.
        totalFiberArea = sum(areas{i});
        totalImageArea = 0;
        for j = 1:length(imDatas{i})
            totalImageArea = totalImageArea +...
                (imDatas{i}(j).imageWidth*imDatas{i}(j).imageHeight);
        end
        f = f * totalFiberArea / totalImageArea;
        
        plot(ax, xi, f,...
            'Color', colors{i},...
            'LineStyle', styles{i},...
            'LineWidth', 2)
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    grid(ax, 'on')
    xlabel(ax, [aChannel ' expression relative to ' intensityReference])
    ylabel(ax, 'Image area per intensity interval')
    legend(ax, legendStrings)
end

% Plot a kernel smoothing density of the fiber size distribution.
if any(strcmp(aPlots, 'Fiber size distribution'))
    caption = ['Distribution of the areas of '...
        'the ' whatFibers 'fibers, estimated using kernel smoothing.'];
    fig = figure('Name', 'Fiber size distribution',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    % Find an appropriate width for the smoothing kernel by pooling all
    % data.
    all_areas = cat(1,areas{:});
    [~, ~, ksWidth] = ksdensity(all_areas, 'support', 'positive');
    
    legendStrings = {};
    for i = 1:length(areas)
        if isempty(areas{i})
            continue
        end
        
        [f, xi] = ksdensity(areas{i}(),...
            'Width', ksWidth,...
            'Npoints', 1000,...
            'support', 'positive');
        plot(ax, xi, f,...
            'Color', colors{i},...
            'LineStyle', styles{i},...
            'LineWidth', 2)
        
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    
    grid(ax, 'on')
    xlabel(ax, 'Fiber area (pixels)')
    ylabel(ax, 'Kernel smoothing density estimate')
    legend(ax, legendStrings)
end


% Plot a weighted kernel smoothing density over the fiber size. The fibers
% are weighted by their sizes, so that the distribution shows how much of
% the tissue is constituted by fibers of different sizes.
if any(strcmp(aPlots, 'Weighted fiber size distribution'))
    caption = ['Weighted distribution of the areas of the ' whatFibers...
        'fibers, where every fiber is weighted by its area. The '...
        'distribution was estimated using weighted kernel smoothing.'];
    fig = figure('Name', 'Weighted fiber size distribution',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    % Find an appropriate width for the smoothing kernel by pooling all
    % data.
    all_areas = cat(1,areas{:});
    all_weights = all_areas / sum(all_areas);
    [~, ~, ksWidth] = ksdensity(all_areas,...
        'Weights', all_weights, 'support', 'positive');
    
    legendStrings = {};
    for i = 1:length(areas)
        if isempty(areas{i})
            continue
        end
        
        weights = areas{i} / sum(areas{i});
        [f, xi] = ksdensity(areas{i},...
            'Weights', weights,...
            'Width', ksWidth,...
            'Npoints', 1000,...
            'support', 'positive');
        plot(ax, xi, f,...
            'Color', colors{i},...
            'LineStyle', styles{i},...
            'LineWidth', 2)
        
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    
    grid(ax, 'on')
    xlabel(ax, 'Fiber area (pixels)')
    ylabel(ax, 'Kernel smoothing density estimate, weighted by area')
    legend(ax, legendStrings)
end


% Plot expression vs fiber size in a scatter plot.
if any(strcmp(aPlots, 'Expression vs size'))
    caption = ['Fiber area plotted against fiber intensity for all '...
        whatFibers 'fibers in the experiment.'];
    fig = figure('Name', 'Expression vs size',...
        'Units', 'normalized',...
        'Position', [0.1 0.1 0.8 0.8],...
        'UserData', caption);
    AddCaption(fig, caption)
    oFigures = [oFigures; fig];
    
    ax = axes('Parent', fig);
    
    legendStrings = {};
    for i = 1:length(areas)
        if isempty(areas{i})
            continue
        end
        
        plot(ax, intensities{i}, areas{i},...
            'Color', colors{i},...
            'Marker', markers{i},...
            'LineStyle', 'none',...
            'LineWidth', 2)
        hold(ax, 'on')
        legendStrings = [legendStrings SpecChar(labels(i), 'matlab')]; %#ok<AGROW>
    end
    
    grid(ax, 'on')
    xlabel(ax, [aChannel ' expression relative to ' intensityReference])
    ylabel(ax, 'Fiber area (pixels)')
    legend(ax, legendStrings)
end

% Create histogram weight vectors where all fibers have the weight 1.
oneCell = cell(size(intensities));
for i = 1:length(intensities)
    oneCell{i} = ones(size(intensities{i}));
end

% Plot a histogram over the fiber size.
if any(strcmp(aPlots, 'Fiber size histograms'))
    fig = PlotHistogram('Fiber size histograms',...
        ['Histogram of the areas of the ' whatFibers 'fibers. The bars '...
        'show the average number of fibers per image, that belong to '...
        'the area bins.'],...
        'Fiber area (pixels)',...
        '# of fibers per bin and image',...
        labels,...
        areas,...
        oneCell,...
        numberOfImages,...
        false);
    oFigures = [oFigures; fig];
end

% Plot a histogram over the fiber intensity.
if any(strcmp(aPlots, 'Expression histograms'))
    fig = PlotHistogram('Expression histograms',...
        ['Histogram of the ' aChannel ' fluorescence intensity in the '...
        whatFibers 'fibers. The bars show the average number of fibers '...
        'per image, that belong to the intensity bins.'],...
        [aChannel ' expression relative to ' intensityReference],...
        '# of fibers per bin and image',...
        labels,...
        intensities,...
        oneCell,...
        numberOfImages,...
        false);
    oFigures = [oFigures; fig];
end

% The following histograms have been removed as they were believed to not
% be of sufficient interest to the users.
%
% PlotHistogram('Total fluorescence in intensity bins',...
%     ['The total amount of integrated ' aChannel ' fluorescence '...
%     'intensity in ' whatFibers 'fibers. The bins show the integrated '...
%     'intensity per image, that belongs to the particular intensity '...
%     'bins.'],...
%     [aChannel ' intensity relative to ' intensityReference],...
%     ['Integrated ' aChannel ' intensity'],...
%     labels,...
%     intensities,...
%     fluorescence,...
%     numberOfImages,...
%     false)
%
% PlotHistogram('Average area in intensity bins',...
%     ['The average fiber area of ' whatFibers 'fibers, in different '...
%     'intensity bins.'],...
%     [aChannel ' intensity relative to ' intensityReference],...
%     'Average fiber area',...
%     labels,...
%     intensities,...
%     areas,...
%     numberOfImages,...
%     true)
%
% PlotHistogram('Total area in intensity bins',...
%     ['The total fiber area of ' whatFibers 'fibers, in different '...
%     'intensity bins.'],...
%     [aChannel ' intensity relative to ' intensityReference],...
%     'Total fiber area in pixels',...
%     labels,...
%     intensities,...
%     areas,...
%     numberOfImages,...
%     false)
%
% PlotHistogram('Average intensity in area bins',...
%     ['The average ' aChannel ' fluorescence intensity in ' whatFibers...
%     'fibers, in different area bins.'],...
%     'Fiber area in pixels',...
%     ['Average ' aChannel ' intensity relative to ' intensityReference],...
%     labels,...
%     areas,...
%     intensities,...
%     numberOfImages,...
%     true)
%
% PlotHistogram('Total fluorescence in area bins',...
%     ['The total amount of integrated ' aChannel ' fluorescence '...
%     'intensity in ' whatFibers 'fibers. The bins show the integrated '...
%     'intensity per image, that belongs to the particular area bins.'],...
%     'Fiber area in pixels',...
%     ['Integrated ' aChannel ' intensity'],...
%     labels,...
%     areas,...
%     fluorescence,...
%     numberOfImages,...
%     false)
%
% PlotHistogram('Total area in area bins',...
%     ['The total fiber area of ' whatFibers 'fibers, in different area '...
%     'bins.'],...
%     'Fiber area in pixels',...
%     'Total fiber area in pixels',...
%     labels,...
%     areas,...
%     areas,...
%     numberOfImages,...
%     false)
end

function oValues = BunchByCondition(aValues, aConditions, aConditionNames)
% Groups analysis values in a cell array by experimental conditions.
%
% Inputs:
% aValues - Cell array where each cell contains a column vector of analysis
%           values associated with a particular image sequence.
% aConditions - Cell array of experimental conditions that were used for
%               the different cells in aValues.
% aConditionNames - Cell array where every cell contains the name of an
%                   experimental condition that will give rise to a group
%                   in the output.
%
% Outputs:
% oValues - Cell array with grouped analysis values. All column vectors of
%           analysis values associated with a particular experimental
%           condition are concatenated and put in the appropriate cell in
%           the output.

oValues = cell(size(aConditionNames));
for i = 1:length(aConditionNames)
    oValues{i} = cat(1, aValues{strcmp(aConditions, aConditionNames{i})});
end
end

function oFigure = PlotHistogram(...
    aName,...
    aCaption,...
    aXLabel,...
    aYLabel,...
    aTitles,...
    aXValues,...
    aWeights,...
    aN,...
    aAverage)
% Presents values for fibers in different conditions as histograms.
%
% This function will create histograms for fiber parameters in different
% experimental conditions. One histogram is created for each experimental
% condition, and the histograms are placed in a grid in the same figure.
% The input to the function is an array of values and an array of weights.
% In the histogram, the height of each bar is the sum of the weights of the
% values that fall in that bin. This results in a normal histogram if the
% weights are arrays of ones. The heights of the bars can be normalized so
% that the histogram distribution represents either one fiber or one image.
%
% Inputs:
% aName - Name that will be given to the figure.
% aCaption - Caption that will be added to the figure. The caption can be
%            seen by pressing the caption menu in the figure. The caption
%            will also be included in exported pdf-documents.
% aXLabel - Label that will be placed on the x-axis of the axes in the
%           bottom row.
% aYLabel - Label that will be placed on the y-axis of the axes in the
%           first column.
% aTitles - Cell array with titles for the different experimental
%           conditions. These titles will be used as titles of the axes.
% aXValues - Cell array where each cell contains an array of values for the
%            corresponding experimental condition.
% aWeights - Cell array where each cell contains an array of weights for
%            the corresponding experimental condition. These weights will
%            be applied to the values in aXValues when the histograms are
%            computed. To produce a normal histogram, the weights should be
%            an array of ones.
% aN - Array with the number of images in each experimental condition. This
%      is used for normalization if aAverage is false.
% aAverage - If this is set to true, the histogram represents a single
%            fiber. Otherwise, it represents an image.
%
% Outputs:
% oFigure - Figure object containing the histogram.

oFigure = figure('Name', aName,...
    'Units', 'normalized',...
    'Position', [0.1 0.1 0.8 0.8],...
    'UserData', aCaption);
AddCaption(oFigure, aCaption)

% Create one axes for each experimental condition.
subplots = zeros(length(aXValues),1);
numCols = floor(sqrt(length(aXValues)));
numRows = ceil(length(aXValues) / numCols);
for i = 1:length(subplots)
    subplots(i) = subplot(numRows, numCols, i);
end

% Create 100 bins for the histogram based on values from all conditions.
allX = cat(1, aXValues{:});
xStart = min(allX);
xEnd = max(allX);
if xEnd == xStart
    % Avoids errors when all values are identical.
    xStart = xStart - abs(xStart)/10;
    xEnd = xEnd + abs(xEnd)/10;
end
xDelta = (xEnd-xStart)/100;
x = (xStart:xDelta:xEnd)';
% Make the last bin empty. Otherwise, the last bin would only contain the
% maximum value.
x(end) = x(end)+eps(x(end));

for i = 1:length(aXValues)
    % Count the number of points in each bin.
    [cnt, index] = histc(aXValues{i}, x);
    cnt = cnt(1:end-1);
    
    % Put the bars on the center points of the bins.
    xi = x(1:end-1) + xDelta/2;
    
    % Compute the sum of the weights for the points in each bin.
    y = zeros(size(xi));
    for j = 1:length(index)
        y(index(j)) = y(index(j)) + aWeights{i}(j);
    end
    
    % Normalize the weighted sums.
    if aAverage
        % Per fiber.
        y = y./cnt;
    else
        % Per image.
        y = y./aN(i);
    end
    
    bar(subplots(i), xi, y)
    
    grid(subplots(i), 'on')
    title(subplots(i), SpecChar(aTitles{i}, 'matlab'))
    [column, row] = ind2sub([numCols, numRows], i);
    if row == numRows
        % Add an x-axis label only on the axes in the bottom row.
        xlabel(subplots(i), aXLabel)
    end
    if column == 1
        % Add a y-axis label only on the axes in the first column.
        ylabel(subplots(i), aYLabel)
    end
end

% Make all axes have the same limits.
xmins = zeros(length(aXValues),1);
xmaxes = zeros(length(aXValues),1);
ymins = zeros(length(aXValues),1);
ymaxes = zeros(length(aXValues),1);
for i = 1:length(subplots)
    xlims = get(subplots(i), 'xlim');
    xmins(i) = xlims(1);
    xmaxes(i) = xlims(2);
    ylims = get(subplots(i), 'ylim');
    ymins(i) = ylims(1);
    ymaxes(i) = ylims(2);
end
for i = 1:length(subplots)
    set(subplots(i), 'xlim', [min(xmins) max(xmaxes)])
    set(subplots(i), 'ylim', [min(ymins) max(ymaxes)])
end

% Sync the zooming in the different axes.
linkaxes(subplots)
end