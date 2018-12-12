function ProliferationProfile(aCells, aFigure, varargin)
% Plots proliferation profiles and modeled proliferation profiles.
%
% The function plots the number of cells in each experimental condition as
% a function of time. It can also plot modeled exponential curves with the
% same division and death rates. Furthermore, it can create modeled
% exponential curves with the same division rates and a death rate of 0.
% The curves can be used to see if the cell proliferation follows an
% exponential function, and if differences in population sizes are due to
% differences in division rates, death rates, or both. The function
% PrintStyle is called to make the plotting style consistent with other
% plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% Model - If this is true, a modeled exponential curve with the same
%         division and death rates as the true curve will be plotted. The
%         default is true.
% NoDeathModel - If this is true, a modeled exponential curve with the same
%                division rate as the true curve and a death rate of 0 will
%                be plotted. The default is true.
%
% See also:
% CloneSize, CloneViability, DeadCellRatio, FateProbabilityGeneration,
% GenterationDistribution, LiveCount, DeadCount, LiveDeadGhost, PlotGUI,
% PrintStyle

% Parse property/value inputs.
[aModel, aNoDeathModel] = GetArgs(...
    {'Model' 'NoDeathModel'},...
    {true, true, true},...
    true, varargin);

[numFrames, t] = TimeSpan(aCells);

[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'cloneParent');
numCond = length(pCellVec);  % Number of experimental conditions.

% Each element in the following three cell arrays corresponds to an
% experimental condition.

% The total number of cells in each frame.
cellCount = cell(1,numCond);
% The death rate as the fraction of cells that die per hour.
divisionRate = cell(1,numCond);
% The division rate as the fraction of cells that divide per hour.
deathRate = cell(1,numCond);

for p = 1:numCond
    cellCount{p} = zeros(numFrames,1);
    
    % Total number cell detections where the cells can divide or die.
    detectionCount = 0;
    % Total number of cell divisions.
    divisionCount = 0;
    % Total number of cell deaths.
    deathCount = 0;
    
    % Count cells, detections, divisions and deaths.
    for cloneIndex = 1:length(pCellVec{p})
        cells = pCellVec{p}{cloneIndex};
        for cellIndex = 1:length(cells)
            c = cells(cellIndex);
            ff = c.firstFrame;
            lf = c.lastFrame;
            cellCount{p}(ff:lf) = cellCount{p}(ff:lf) + 1;
            
            % Divisions and deaths cannot be detected in the last frame and
            % therefore the last frame is not counted in the total number
            % of frames used to estimate rates of division and death.
            detectionCount = detectionCount + min(lf,numFrames-1) - ff + 1;
            
            if c.divided
                divisionCount = divisionCount + 1;
            elseif c.died
                deathCount = deathCount + 1;
            end
        end
    end
    
    % Compute division and death rates.
    divisionRate{p} = divisionCount / detectionCount * 3600 / c.dT;
    deathRate{p} = deathCount / detectionCount * 3600 / c.dT;
end

% Colors to plot the different experimental conditions in.
colors = get(0, 'DefaultAxesColorOrder');
colors = mat2cell(colors, ones(size(colors,1),1), 3);

% Plot curves.
ax = axes('Parent', aFigure);
for p = 1:numCond
    % Plot the actual proliferation curve.
    proliferationCurve = cellCount{p} / cellCount{p}(1) * 100;
    plot(ax, t, proliferationCurve, 'LineWidth', 4, 'Color', colors{p})
    hold(ax, 'on')
    
    % Fine time grid used for the model curves.
    tMin = c.imageData.FrameToT(1);
    tFine = t(1):(t(end)-t(1))/10000:t(end);
    
    if aModel
        % Exponential model curve with the same division and death rates.
        modelCount = 100*exp((divisionRate{p} - deathRate{p})*(tFine-tMin));
        plot(ax, tFine, modelCount,...
            'LineStyle', '-',...
            'Color', colors{p},...
            'LineWidth', 4)
    end
    
    if aNoDeathModel
        % Exponential model curve with the same division rate and a death
        % rate of 0.
        noDeathModelCount = 100*exp((divisionRate{p})*(tFine-tMin));
        plot(ax, tFine, noDeathModelCount,...
            'LineStyle', '--',...
            'Color', colors{p},...
            'LineWidth', 4)
    end
end

% Set the lower y-limit to 0.
yL = get(ax, 'ylim');
ylim(ax, [0 yL(2)])

xlim(ax, [t(1) t(end)])

xlabel(ax, 'Time (hours)')
ylabel(ax, 'Normalized cell count')

% Add a legend.
legendStrings = {};
for p = 1:size(pLabels,2)
    legendStrings = [legendStrings...
        {sprintf('%s', pLabels{1,p})}]; %#ok<AGROW>
    if aModel
        legendStrings = [legendStrings...
            {sprintf('%s modeled proliferation', pLabels{1,p})}]; %#ok<AGROW>
    end
    if aNoDeathModel
        legendStrings = [legendStrings...
            {sprintf('%s modeled proliferation without death',...
            pLabels{1,p})}]; %#ok<AGROW>
    end
end
legend(legendStrings, 'Location', 'Northwest')

PrintStyle(ax)
end