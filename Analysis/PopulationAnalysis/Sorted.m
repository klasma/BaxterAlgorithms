function Sorted(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots a sorted sequence of time averaged cell properties.
%
% The cells property values are sorted from largest to smallest, and are
% then plotted on the interval from 0 to 1 on the x-axis. The function can
% plot curves of sorted property values for different cell groups in
% different colors.
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
% PlotConditionProperty, CDF, Histogram, KernelSmoothingDensity

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

labelStrings = {};
for i = 1:length(aCellVec)
    y = ExtractProperty(aCellVec{i}, aProperty);
    
    % Remove NaNs.
    y(isnan(y)) = [];
    if isempty(y)
        continue
    end
    
    % For the property deltaT, each sister cell pair has a positive and a
    % negative value (or two zeros). We only plot non-negative values, and
    % remove half of the zeros. After this, every data point corresponds to
    % one sister cell pair.
    if strcmp(aProperty, 'deltaT')
        y(y<0) = [];
        zeroIndex = find(y == 0);
        y(zeroIndex(1:length(zeroIndex)/2)) = [];
    end
    
    y = sort(y, 'descend');
    if length(y) == 1
        % Plot a horizontal line if there is only one data point.
        y = y * ones(1,2);
        x = [0 1];
    else
        x = 0:1/(length(y)-1):1;
    end
    
    plot(aAxes, x, y, colors{mod(i-1,length(colors))+1}, 'LineWidth', 4)
    hold(aAxes, 'on')
    
    labelStrings = [labelStrings {num2str(aLabels{i})}]; %#ok<AGROW>
end

grid(aAxes, 'on')
xlabel(aAxes, 'Fraction')
ylabel(aAxes, aPropertyLabel)
title(aAxes, aTitle)
legend(aAxes, labelStrings)
set(aAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
end