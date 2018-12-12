function CDF(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots cumulative distribution functions of time averaged cell properties.
%
% The function can plot cumulative distribution functions (CDFs) for
% multiple groups of cells, in different colors.
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
% PlotConditionProperty, Histogram, KernelSmoothingDensity, Sorted

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

labelStrings = {};
for i = 1:length(aCellVec)
    x = ExtractProperty(aCellVec{i}, aProperty);
    
    % Remove NaNs.
    x(isnan(x)) = [];
    if isempty(x)
        continue
    end
    
    % For the property deltaT, each sister cell pair has a positive and a
    % negative value (or two zeros). We only plot non-negative values, and
    % remove half of the zeros. After this, every data point corresponds to
    % one sister cell pair.
    if strcmp(aProperty, 'deltaT')
        x(x<0) = [];
        zeroIndex = find(x == 0);
        x(zeroIndex(1:length(zeroIndex)/2)) = [];
    end
    
    x = sort(x, 'ascend');
    if length(x) == 1
        % Plot a vertical line if there is only one data point.
        x = x * ones(1,2);
        y = [0 1];
    else
        y = 0:1/(length(x)-1):1;
    end
    
    plot(aAxes, x, y, colors{mod(i-1,length(colors))+1}, 'LineWidth', 4)
    hold(aAxes, 'on')
    
    labelStrings = [labelStrings {num2str(aLabels{i})}]; %#ok<AGROW>
end

grid(aAxes, 'on')
xlabel(aAxes, aPropertyLabel)
ylabel(aAxes, 'Fraction')
title(aAxes, aTitle)
legend(aAxes, labelStrings, 'Location', 'SouthEast')
set(aAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
end