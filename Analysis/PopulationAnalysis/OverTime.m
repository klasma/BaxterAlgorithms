function OverTime(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots time averaged cell properties against appearance times of cells.
%
% The appearance times are binned into intervals of 1 hour, and average
% parameter values for the bins are computed and plotted against time. When
% there are no cells in a bin, the value of that bin is interpolated from
% surrounding values using linear interpolation. Lines that end in
% interpolated points are plotted using a dashed line style.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCellVec - Cell array where each cell contains a group of Cell objects
%            that will be plotted in a separate color.
% aLabels - Labels associated with the different cell groups. The groups
%           are usually experimental conditions.
% aProperty - The name of the cell property to be plotted. The property
%             must be a property of the Cell class.
% aTitle - Title describing the plotted property. The title will be placed
%          at the top of the plot.
% aPropertyLabel - The axis label associated with the plotted property.
%
% The function also takes two dummy inputs which make it possible to call
% the function from PlotConditionProperty with the same input arguments as
% Scatter.
%
% See also:
% PlotConditionProperty

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

% Get the maximum property value.
cells = [aCellVec{:}];
props = ExtractProperty(cells, aProperty);
if all(isnan(props))
    return
end
maxVal = max(props(~isnan(props)));

numFrames = TimeSpan(cells);
df = 3600/cells(1).dT;  % Number of frames in each bin.
% Time points corresponding to the bins.
t = cells(1).imageData.FrameToT(1:df:numFrames);

propHist = cell(size(aCellVec));
counts = cell(size(aCellVec));

% Put the cells and their properties into the bins.
for i = 1:length(aCellVec)
    propHist{i} = zeros(ceil(numFrames / df), 1);
    counts{i} = zeros(ceil(numFrames / df), 1);
    for cIndex = 1:length(aCellVec{i})
        c = aCellVec{i}(cIndex);
        if ~isnan(ExtractProperty(c, aProperty))
            % Bin that the cell belongs to.
            bin = floor(c.firstFrame / df) + 1;
            if strcmpi(aProperty, 'deltaT')
                % For the property deltaT, each sister cell pair has a
                % positive and a negative value (or two zeros). To deal
                % with this, we take the absolute value of the property.
                propHist{i}(bin) = propHist{i}(bin) +...
                    abs(ExtractProperty(c, aProperty));
            else
                propHist{i}(bin) = propHist{i}(bin) +...
                    ExtractProperty(c, aProperty);
            end
            counts{i}(bin) = counts{i}(bin) + 1;
        end
    end
end

% Compute the average property value in each bin, by dividing the summed
% property values by the number of cells.
propHistNorm = cell(size(propHist));
for i = 1:length(aCellVec)
    propHistNorm{i} = propHist{i} ./ counts{i};
end

% Create label strings, and make fake lines at the origin with the
% corresponding line styles, so that the correct lines are drawn in the
% legend.
labelStrings = {};
for i = 1:length(aCellVec)
    if all(isnan(propHistNorm{i}))
        continue
    end
    
    colorIndex = mod(i-1,length(colors)) + 1;
    
    % Solid line.
    plot(aAxes, 0, 0, 'LineWidth', 4, 'Color', colors{colorIndex})
    hold(aAxes, 'on')
    labelStrings = [labelStrings {num2str(aLabels{i})}]; %#ok<AGROW>
    
    % Dashed line.
    if any(isnan(propHistNorm{i}))
        plot(aAxes, 0, 0,...
            'LineWidth', 4,...
            'Color', colors{colorIndex},...
            'LineStyle', '--')
        labelStrings = [labelStrings...
            {[num2str(aLabels{i}) ' (interpolated)']}]; %#ok<AGROW>
    end
end

% Plot observed values with solid lines and interpolated values with dotted
% lines. The bins that need to be interpolated have NaN-values.
for i = 1:length(aCellVec)
    colorIndex = mod(i-1,length(colors)) + 1;
    PlotWithNan(aAxes, t', propHistNorm{i}',...
        'LineWidth', 4,...
        'Color', colors{colorIndex})
end

% Set axis limits for the time axes.
if length(t) == 1
    % Avoids a crash when the plot is empty.
    xlim(aAxes, [t t+1])
else
    xlim(aAxes, [t(1) t(end)])
end

% Set y-axis limits so that there is a 10 % Margin at the top.
if maxVal > 0
    set(aAxes, 'ylim', [0, maxVal*1.1])
end

grid(aAxes, 'on')
xlabel(aAxes, 'Time (hours)')
ylabel(aAxes, aPropertyLabel)
legend(aAxes, labelStrings, 'Location', 'Best')
title(aAxes, aTitle)
end