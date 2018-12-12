function KernelSmoothingDensity(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots kernel smoothing densities of time averaged cell properties.
%
% The kernel smoothing densities are computed using the function ksdensity,
% with default settings. Kernel smoothing densities for multiple groups of
% cells can be plotted in different colors.
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
% PlotConditionProperty, Histogram, CDF, Sorted

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

% Get minimum and maximum values for the property.
cells = [aCellVec{:}];
props = ExtractProperty(cells, aProperty);
if all(isnan(props))
    return
end
% For the property deltaT, each sister cell pair has a positive and a
% negative value (or two zeros). We only plot non-negative values, and
% remove half of the zeros. After this, every data point corresponds to
% one sister cell pair.
if strcmp(aProperty, 'deltaT')
    props(props<0) = [];
    zeroIndex = find(props == 0);
    props(zeroIndex(1:length(zeroIndex)/2)) = [];
end
minVal = min(props(~isnan(props)));
maxVal = max(props(~isnan(props)));
yMax = -inf;

labelStrings = {};
for i = 1:length(aCellVec)
    y = ExtractProperty(aCellVec{i}, aProperty);
    
    % Remove NaNs.
    y(isnan(y)) = [];
    if isempty(y)
        continue
    end
    
    % Handle the property deltaT as described above.
    if strcmp(aProperty, 'deltaT')
        y(y<0) = [];
        zeroIndex = find(y == 0);
        y(zeroIndex(1:length(zeroIndex)/2)) = [];
    end
    
    [f, x] = ksdensity(y);
    
    % Update the maximum y-value.
    yMax = max([yMax f]);
    
    plot(aAxes, x, f, colors{mod(i-1,length(colors))+1}, 'LineWidth', 4)
    hold(aAxes, 'on')
    
    labelStrings = [labelStrings {num2str(aLabels{i})}]; %#ok<AGROW>
end

grid(aAxes, 'on')
xlabel(aAxes, aPropertyLabel)
ylabel(aAxes, 'a.u.')
title(aAxes, aTitle)
legend(aAxes, labelStrings)
set(aAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')

% Set the x-axis limits so that there is a 10 % margin on each side.
xMargin = (maxVal-minVal)*0.1;
if xMargin > 0
    set(aAxes, 'xlim', [minVal-xMargin maxVal+xMargin])
end

% Set the y-axis limits so that there is a 10 % margin at the top.
if yMax > 0
    set(aAxes, 'ylim', [0 yMax*1.1])
end
end