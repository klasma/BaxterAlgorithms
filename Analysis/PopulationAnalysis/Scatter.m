function Scatter(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, aMarkDead, aMarkSurvived)
% Visualizes a cell property using a scatter plot.
%
% The cell properties are defined as properties of the Cell class, and are
% time averaged measurements of cell properties, such as speed and size.
% This function can plot scatter plots where the y-axis is the property and
% the x-axis shows indices of cell groups. The cells in each group are
% plotted around the corresponding x-value, and the spread is determined so
% that the dots are easy to seen in the scatter plot. If specified in the
% input arguments, the cells that die can be colored red and the cells
% that are present in the last image can be colored blue. All cells which
% are not colored red or blue are colored black. The red dots are plotted
% closest to the x-value of the group, blue dots are potted next, and black
% dots are plotted last.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCellVec - Cell array where each cell contains a group of Cell objects
%            that will be plotted separately. Each group will be plotted on
%            the corresponding integer on the x-axis.
% aLabels - Labels associated with the different cell groups. The groups
%           are usually either experimental conditions or cell generations.
% aProperty - The name of the cell property to be plotted. The property
%             must be a property of the Cell class.
% aTitle - Title describing the plotted property. The title will be placed
%          at the top of the plot.
% aPropertyLabel - The axis label associated with the plotted property.
% aMarkDead - If this input is true, cells that die during the experiment
%             are colored red.
% aMarkSurvived - If this input is true, cells that are present in the last
%                 frame of the experiment are colored blue.
%
% See also:
% PlotConditionProperty, Scatter

% Extract the cell property of interest for all cells .
cells = [aCellVec{:}];
props = ExtractProperty(cells, aProperty);
if all(isnan(props))
    return
end

% For the function Scatter to work, the axis limits must be set before the
% function is called.

% Set the y-limits for the axis.
maxVal = max(props(~isnan(props)));
if maxVal > 0
    set(aAxes, 'ylim', [0, maxVal*1.1])
end

% The x-values are integers and the axis limits have margins of 0.5.
set(aAxes, 'xlim', [0.5 length(aCellVec)+0.5])

% Create legend entries depending on which cells are colored differently.
if aMarkDead && aMarkSurvived
    legendStrings = {'dividing', 'non-dividing', 'dead'};
elseif aMarkDead
    legendStrings = {'dividing or non-dividing', 'dividing or non-dividing', 'dead'};
elseif aMarkSurvived
    legendStrings = {'dead or dividing', 'non-dividing', 'dead or dividing'};
else
    legendStrings = {'cells'};
end

% Loop over cell groups.
for i = 1:length(aCellVec)
    % Extract cells for which the property is not empty.
    indices = ~cellfun(@isempty, ExtractProperty(aCellVec{i}, aProperty,...
        'UniformOutput', false));
    cells = aCellVec{i}(indices);
    
    % Extract property values.
    y = ExtractProperty(cells, aProperty);
    if strcmp(aProperty, 'deltaT')
        % Plot only the positive deltaT-value in daughter cell pairs.
        y(y<0) = nan;
        zeroIndex = find(y == 0);
        % Remove half of the zero-values as a daughter cell pair creates
        % two zeros. The cell categories do not matter as all cells for
        % which deltaT is defined come from the same category.
        y(zeroIndex(1:length(zeroIndex)/2)) = nan;
    end
    
    % Divide the cells into categories.
    survived = [cells.survived];
    died = [cells.died];
    category = 1*ones(size(y));
    if aMarkSurvived
        category(survived) = 2;
    end
    if aMarkDead
        category(died) = 3;
    end
    
    % Remove NaNs.
    category(isnan(y)) = [];
    y(isnan(y)) = [];
    
    % The x-value is group index.
    x = i*ones(size(y));
    
    ScatterPlot(aAxes, x, y, category, {'ko', 'bo', 'ro'}, legendStrings)
    hold(aAxes, 'on')
end

grid(aAxes, 'on')
title(aAxes, aTitle)
% The tick labels on the x-axis are set to the group labels.
xlabel(aAxes, '')
set(aAxes, 'XTick', 1:length(aCellVec), 'XTickLabel', aLabels(1,:))
ylabel(aAxes, aPropertyLabel)
end