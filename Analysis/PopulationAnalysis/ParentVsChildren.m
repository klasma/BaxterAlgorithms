function ParentVsChildren(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots property values of daughter cells against the mother cell.
%
% The property value of the mother cell is plotted on the x-axis and the
% property values of the daughter cells are plotted on the y-axis. The
% property values are plotted as dots, and the dots of the daughter cells
% are connected. Multiple groups of cells can be plotted using different
% colors. A symmetry line at y = x is also plotted.
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
% PlotConditionProperty, ParentVsAllChildren, Symmetry, Scatter

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

% Minimum and maximum x- and y-values where points have been plotted.
xMin = inf;
xMax = -inf;
yMin = inf;
yMax = -inf;

labelStrings = {};
for i = 1:length(aCellVec)
    labelAdded = false;  % True if a label has been added to the legend.
    for j = 1:length(aCellVec{i})
        c = aCellVec{i}(j);
        
        if isempty(c.children)
            continue
        else
            pVal = ExtractProperty(c, aProperty);  % Parent value.
            cVal = ExtractProperty(c.children, aProperty);  % Child values.
        end
        
        if isempty(pVal) || isempty(cVal) || isnan(pVal) || all(isnan(cVal))
            continue
        end
        
        % Remove NaNs from child values.
        cVal = cVal(~isnan(cVal));
        
        % Update minimum and maximum values.
        xMin = min([xMin pVal]);
        xMax = max([xMax pVal]);
        yMin = min([yMin cVal]);
        yMax = max([yMax cVal]);
        
        colorIndex = mod(i-1,length(colors)) + 1;
        pl = plot(aAxes,...
            repmat(pVal, 1, length(cVal)),...
            cVal,...
            [colors{colorIndex} '-o'],...
            'MarkerFaceColor', colors{colorIndex},...
            'LineWidth', 1);
        
        hold(aAxes, 'on')
        
        if ~labelAdded
            % Let this plotted object be associated with a legend label.
            labelStrings = [labelStrings num2str(aLabels{i})]; %#ok<AGROW>
            labelAdded = true;
        else
            % Do not create a legend label.
            set(get(get(pl,'Annotation'),'LegendInformation'),...
                'IconDisplayStyle','off');
        end
    end
end

% Symmetry line y = x.
plot(aAxes, [-1E10 1E10], [-1E10 1E10], 'k', 'LineWidth', 1)
labelStrings = [labelStrings {['equal ' aProperty]}];

grid(aAxes, 'on')
set(aAxes, 'XTickMode', 'auto')
set(aAxes, 'XTickLabelMode', 'auto')
xlabel(aAxes, aPropertyLabel)
ylabel(aAxes, aPropertyLabel)
title(aAxes, aTitle)
legend(aAxes, labelStrings, 'Location', 'SouthEast')

% Set the x- and y-limits so that the margins on the sides are 10 % of the
% range of plotted values.
if ~any(isinf([xMax xMin yMax yMin]))
    xMargin = (xMax-xMin)*0.1;
    yMargin = (yMax-yMin)*0.1;
    if xMargin > 0
        set(aAxes, 'xlim', [xMin-xMargin xMax+xMargin])
    end
    if yMargin > 0
        set(aAxes, 'ylim', [yMin-yMargin yMax+yMargin])
    end
end
end