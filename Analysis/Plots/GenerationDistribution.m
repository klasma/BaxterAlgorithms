function GenerationDistribution(aCells, aFigure, varargin)
% Plots the number of cells in each generation as a function of time.
%
% The function can plot live cells, dead cells, or both live and dead cells
% in the same plot. The cell counts in each frame are summed cumulatively
% so that the curve for generation g is the number or cells in generation g
% and lower generations. The region under the generation 1 curve and the
% regions between curves are filled with colors representing the different
% generations. The colors are taken from the default color order. If both
% live and dead cells are plotted in the same plot, the dead cells are
% plotted in a darker color. Division and death events can be plotted  as
% rings and crosses respectively. Division markers are not included when
% dead cells are plotted, and no markers are included when both live and
% dead cells are plotted. The cell counts can be normalized in different
% ways. The function PrintStyle is called to make the plotting style
% consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% Type - This property specifies which cells should be plotted. The allowed
%        values are 'live', 'dead', or 'liveanddead'. The default is
%        'live'.
% Normalization - This parameter specifies how the cell counts should be
%                 normalized. With 'none', the raw cell counts are plotted,
%                 with 'start', the cell counts are normalized to starting
%                 populations of 100 cells, and with 'percentage', the
%                 cells in each frame are normalized so that they sum to
%                 100 %. The default is 'none'.
% Markers - No markers will be plotted if this property is set to false.
%           The default is true.
%
% See also:
% CloneViability, DeadCount, FateProbabilityGeneration, LiveCount,
% ProliferationProfile, PlotGUI, PrintStyle

% Parse property/value inputs.
[aType, aNormalization, aMarkers] = GetArgs(...
    {'Type' 'Normalization' 'Markers'},...
    {'live', 'none', true},...
    true, varargin);

% Check inputs.
if ~any(strcmpi({'live' 'dead' 'liveanddead'}, aType))
    error('Unknown type ''%s''', aType)
end
if ~any(strcmpi({'none' 'start' 'percentage'}, aNormalization))
    error('Unknown normalization ''%s''', aNormalization)
end

[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'generation');
numCond = length(pCellVec);  % Number of experimental conditions.
maxGen = max([aCells.generation]);  % Highest cell generation.

[numFrames, t] = TimeSpan(aCells);

% Cell arrays with matrices that hold counts of live and dead cells in each
% frame. There is one cell for each experimental condition. That cell
% contains a matrix with one row for each generation and one column for
% each frame.
cellCount = cell(numCond,1);
deadCount = cell(numCond,1);

% Cell arrays with indices of frames that have death and division events.
% There is one cell for each experimental condition. Each such cell
% contains a cell array with one cell for each generation. Each such cell
% contains an array with frame indices.
divFrames = cell(numCond,1);
deathFrames = cell(numCond,1);

% Count live and dead cells, and store indices of frames with death and
% division events.
for p = 1:numCond
    cellCount{p} = zeros(maxGen, numFrames);
    deadCount{p} = zeros(maxGen, numFrames);
    divFrames{p} = cell(maxGen,1);
    deathFrames{p} = cell(maxGen,1);
    for g = 1:length(pCellVec{p})
        for i = 1:length(pCellVec{p}{g})
            c = pCellVec{p}{g}(i);
            ff = c.firstFrame;
            lf = c.lastFrame;
            
            cellCount{p}(g, ff:lf) = cellCount{p}(g, ff:lf) + 1;
            
            if c.died
                deadCount{p}(g, lf+1:end) = deadCount{p}(g, lf+1:end) + 1;
                deathFrames{p}{g} = [deathFrames{p}{g} lf];
            end
            
            if c.divided
                divFrames{p}{g} = [divFrames{p}{g} lf];
            end
        end
    end
end

% Create a list of colors for plotting. The colors in the default color
% order are placed in a cell array.
colors = get(0, 'DefaultAxesColorOrder');
if strcmpi(aType, 'liveanddead')
    % Use darker colors to plot dead cells if both live and dead cells are
    % plotted.
    colors = reshape([colors'*0.5; colors'], 3, size(colors,1)*2)';
end
colors = mat2cell(colors, ones(size(colors,1),1), 3);

maxY = -inf;  % The largest y-value plotted. Used to sync limits on axes.
for p = 1:numCond
    ax = subplot(numCond, 1, p, 'Parent', aFigure);
    
    % Compute count curves for plotting with PlotFilled.
    switch lower(aType)
        case 'live'
            sumY = cumsum(cellCount{p},1);
        case 'dead'
            sumY = cumsum(deadCount{p},1);
        case 'liveanddead'
            liveDead = reshape([deadCount{p}'; cellCount{p}'], numFrames, maxGen*2)';
            sumY = cumsum(liveDead,1); %#ok<UDIM>
    end
    
    % Apply the user specified normalization to the curves.
    switch aNormalization
        case 'none'
            % Do nothing.
        case 'start'
            sumY = sumY / sum(cellCount{p}(:,1)) * 100;
        case 'percentage'
            sumY = sumY./repmat(sumY(end,:) + eps, size(sumY,1), 1) * 100;
    end
    
    % Plot the count curves with filled regions between curves.
    fillColors = ModIndex(colors, 1:size(sumY,1));
    if ~iscell(fillColors)
        % If a single color is selected, the color will not be in a cell.
        fillColors = {fillColors};
    end
    PlotFilled(t, sumY, fillColors, 'Parent', ax)
    hold(ax, 'on')
    
    % Update maximum y-value.
    maxY = max(maxY, max(sumY(:)));
    
    % Plot markers for divisions.
    if aMarkers && strcmpi(aType, 'live')
        divX = [];
        divY = [];
        for g = 1:length(pCellVec{p})
            for divIndex = 1:length(divFrames{p}{g})
                x = divFrames{p}{g};
                y = sumY(g,x);
                x = c.imageData.FrameToT(x);
                divX = [divX x]; %#ok<AGROW>
                divY = [divY y]; %#ok<AGROW>
            end
        end
        
        plot(ax, divX, divY, 'ko')
    end
    
    % Plot markers for deaths.
    if aMarkers && ~strcmpi(aType, 'liveanddead')
        deathX = [];
        deathY = [];
        for g = 1:length(pCellVec{p})
            for deathIndex = 1:length(deathFrames{p}{g})
                x = deathFrames{p}{g}(deathIndex);
                y = sumY(g,x);
                x = c.imageData.FrameToT(x);
                deathX = [deathX x]; %#ok<AGROW>
                deathY = [deathY y]; %#ok<AGROW>
            end
        end
        
        plot(ax, deathX, deathY,...
            'LineStyle', 'none',...
            'Marker', 'x',...
            'MarkerSize', 10,...
            'MarkerEdgeColor', 'k',...
            'LineWidth', 0.5)
    end
    
    xlim(ax, [t(1) t(end)])
    
    % Create a legend with information about cell generations and markers.
    switch lower(aType)
        case {'live'}
            legendStrings = arrayfun(...
                @(x)sprintf('generation %d', x),...
                1:length(pCellVec{p}),...
                'UniformOutput', false);
            if aMarkers
                if ~isempty([divFrames{p}{:}])
                    legendStrings = [legendStrings {'mitosis'}]; %#ok<AGROW>
                end
                if ~isempty([deathFrames{p}{:}])
                    legendStrings = [legendStrings {'death'}]; %#ok<AGROW>
                end
            end
        case 'dead'
            legendStrings = {};
            for g  = 1:length(pCellVec{p})
                if any(deadCount{p}(g, :))
                    legendStrings = [legendStrings...
                        {sprintf('generation %d', pLabels{2,p}{g})}]; %#ok<AGROW>
                end
            end
            if aMarkers
                if ~isempty([deathFrames{p}{:}])
                    legendStrings = [legendStrings {'death'}]; %#ok<AGROW>
                end
            end
        case 'liveanddead'
            legendStrings = {};
            for g  = 1:length(pCellVec{p})
                if any(deadCount{p}(g, :))
                    legendStrings = [legendStrings...
                        {sprintf('generation %d, dead', pLabels{2,p}{g})}]; %#ok<AGROW>
                end
                if any(cellCount{p}(g, :))
                    legendStrings = [legendStrings...
                        {sprintf('generation %d, alive', pLabels{2,p}{g})}]; %#ok<AGROW>
                end
            end
    end
    if ~isempty(legendStrings)
        legend(legendStrings, 'Location', 'NorthEastOutside');
    end
    
    xlabel(ax, 'Time (hours)')
    switch aNormalization
        case 'none'
            ylabel(ax, 'Cell count')
        case 'start'
            ylabel(ax, 'Normalized cell count')
        case 'percentage'
            ylabel(ax, 'Percentage of cells')
    end
    
    switch lower(aType)
        case 'live'
            title(ax, pLabels{1,p})
        case 'dead'
            title(ax, sprintf('Dead cells on %s', pLabels{1,p}))
        case 'liveanddead'
            title(ax, sprintf('Live and dead cells on %s', pLabels{1,p}))
    end
    
    PrintStyle(ax)
end

% Adjust the y-limits of the axes so that they all match the axes with the
% largest interval. If maxY is 0, the upper limit is set to eps(0), which
% is the smallest possible value, to avoid a crash.
for p = 1:numCond
    ax = subplot(numCond, 1, p, 'Parent', aFigure);
    switch aNormalization
        case {'none' 'start'}
            ylim(ax, [0 max(maxY*1.1, eps(0))])
        case 'percentage'
            ylim(ax, [0 max(maxY, eps(0))])
    end
end
end