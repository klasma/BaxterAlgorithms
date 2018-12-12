function Symmetry(aAxes, aCellVec, aLabels, aProperty, aTitle, aPropertyLabel, ~, ~)
% Plots property values of sister cells in a dot plot.
%
% The lowest property value is plotted on the x-axis and the highest
% property value is plotted on the y-axis. The property values are plotted
% as dots. Multiple groups of cells can be plotted using different colors.
% A symmetry line at y = x is also plotted. The function also prints out
% the intra-class correlation, the 95 % confidence interval of the
% intra-class correlation, and the p-value of correlation.
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
% PlotConditionProperty, ParentVsChildren, ParentVsAllChildren, Scatter

% Colors used for plotting the different groups of cells. If there are more
% groups than colors, the colors are recycled.
colors = {'b', 'r', 'c', 'm', 'k', 'y', 'g'};

% Minimum and maximum x- and y-values where points have been plotted.
xsMin = inf;
xsMax = -inf;
ysMin = inf;
ysMax = -inf;

labelStrings = {};
for i = 1:length(aCellVec)
    
    % Collect property pairs for sisters.
    xy = [];
    for j = 1:length(aCellVec{i})
        c = aCellVec{i}(j);
        if length(c.children) == 2
            xyNew = ExtractProperty(c.children, aProperty);
            xyNew = sort(xyNew, 'ascend');
            if length(xyNew) == 2 && ~any(isnan(xyNew))
                xy = [xy; xyNew]; %#ok<AGROW>
            end
        end
    end
    if isempty(xy)
        continue
    end
    
    % Update minimum and maximum values.
    xsMin = min([xsMin; xy(:,1)]);
    xsMax = max([xsMax; xy(:,1)]);
    ysMin = min([ysMin; xy(:,2)]);
    ysMax = max([ysMax; xy(:,2)]);
    
    colorIndex = mod(i-1,length(colors)) + 1;
    plot(aAxes, xy(:,1), xy(:,2), [colors{colorIndex} 'o'],...
        'MarkerFaceColor', colors{colorIndex})
    
    labelStrings = [labelStrings num2str(aLabels{i})]; %#ok<AGROW>
    
    hold(aAxes, 'on')
end

% Symmetry line y = x.
plot(aAxes, [-1E10 1E10], [-1E10 1E10], 'k', 'LineWidth', 1)
labelStrings = [labelStrings {['equal ' aProperty]}];

grid(aAxes, 'on')
set(aAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
xlabel(aAxes, aPropertyLabel)
ylabel(aAxes, aPropertyLabel)
title(aAxes, aTitle)
legend(aAxes, labelStrings, 'Location', 'SouthEast')

% Set the x- and y-limits so that the margins on the sides are 10 % of the
% range of plotted values.
if ~any(isinf([xsMax xsMin ysMax ysMin]))
    xMargin = (xsMax-xsMin)*0.1;
    yMargin = (ysMax-ysMin)*0.1;
    if xMargin > 0
        set(aAxes, 'xlim', [xsMin-xMargin xsMax+xMargin])
    end
    if yMargin > 0
        set(aAxes, 'ylim', [ysMin-yMargin ysMax+yMargin])
    end
end
end