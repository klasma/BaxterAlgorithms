function ScatterPlot(aAxes, aX, aY, aCat, aCol, aLabels, varargin)
% Plots data in a scatter plot.
%
% The function creates a scatter plot where y-values are plotted against
% x-values using dots or other markers. If markers come too close to each
% other, markers are moved to the closest available location with the same
% y-value. Y-values are never changed, but markers can be spread around
% their true x-value to create sufficient separation. The marker positions
% are computed from the pixel coordinates that correspond to the data
% points, and therefore the axis limits of the axes object need to be set
% before this function is called. The data points can be separated into
% multiple categories with different colors and markers. When markers need
% to be spread out, markers in the last category are plotted closest to the
% true x-value and markers in the first category are plotted furthest away.
%
% Inputs:
% aAxes - Axes object to plot in.
% aX - x-values of the data points.
% aY - y-values of the data points.
% aCat - Categories of the data points. Each data point belongs to a
%        category, and the categories can be plotted with different markers
%        and colors.
% aCol - Cell array with plotting style information for the categories. The
%        potting style is a letter for a color followed by a marker symbol.
%        For example, 'ro' stands for red dots.
% aLabels - Legend labels of the categories.
%
% Property/Value inputs:
% R - Assumed marker size in pixels, used when the markers are placed. The
%     minimum distance between two markers is two times this value. This
%     input does  not change the plotted marker size. It only changes the
%     separation between the markers. The default value is 5.
%
% See also:
% Scatter

% Parse property/value inputs.
aR = GetArgs({'R'}, {5}, true, varargin);

% Get the axes size in pixels, without altering the units permanently.
unit = get(aAxes, 'Units');
set(aAxes, 'Units', 'pixels')
pos = get(aAxes, 'Position');
set(aAxes, 'Units', unit)

% Compute the distances in the x- and y-dimensions which correspond to one
% pixel.
xlim  = get(aAxes, 'xlim');
ylim  = get(aAxes, 'ylim');
xscale = (max(xlim) - min(xlim))/pos(3);
yscale = (max(ylim) - min(ylim))/pos(4);

xAdded = [];
yAdded = [];

% Loop over the categories, starting with the last category.
for catIndex = max(aCat) : -1 : 1
    if ~any(aCat == catIndex)
        % No values had this category.
        continue
    end
    
    xAddedLength = length(xAdded);
    
    % Compute x- and y-values in pixels. Order them from smallest to
    % largest y-value.
    [y, order] = sort(aY(aCat == catIndex)/yscale, 'ascend');
    x = aX(aCat == catIndex);
    x = x(order)/xscale;
    
    if isempty(xAdded)
        % Add the first data point.
        xAdded = x(1);
        yAdded = y(1);
        colorAdded = aCol(catIndex);
        x = x(2:end);
        y = y(2:end);
    end
    
    while ~isempty(x)
        distances = nan(length(x),1);
        xpos = nan(length(x),1);
        
        for i = 1:length(x)
            % Find all previous y-values that are within 2*aR of the point
            % to be added. These could interfere with the placement of the
            % next point.
            dy = yAdded - y(i);
            close = abs(dy) < 2*aR;
            
            % If all previous y-values are further away, they will not
            % interfere with the next point.
            if ~any(close)
                distances(i) = 0;
                xpos(i) = x(i);
                continue
            end
            
            % Find potential x-values next to all existing points. The
            % potential x-values are computed so that the points are
            % 2*aR away (euclidian distance in x and y) from the previous
            % point, either to the left (xmin) or to the right (xmax) of
            % the previous point.
            xmin = xAdded(close) - sqrt((2*aR)^2 - dy(close).^2);
            xmax = xAdded(close) + sqrt((2*aR)^2 - dy(close).^2);
            
            % The values in xmin and xmax are all potential x-coordinates,
            % provided that they do not overlap with any of the other
            % previous points that are 'close'. It is also possible that
            % the next point can be placed on the original x-value, in a
            % 'hole' between existing points.
            candidates = [x(i); xmin; xmax];
            
            % Compute which of the candidate points are legal in the sense
            % that they do not overlap with any of the 'close' points. The
            % criteria for that is that the point must not lie between xmin
            % and xmax for any of the 'close' points.
            keep = false(size(candidates));
            for j = 1:length(candidates)
                if ~any(xmin < candidates(j) & candidates(j) < xmax)
                    keep(j) = true;
                end
            end
            legal = candidates(keep);
            
            % Find the closest legal x-value.
            [distances(i), minIndex] = min(abs(legal-x(i)));
            xpos(i) = legal(minIndex);
        end
        % Only the closest points are added in each iteration of the
        % while-loop. This makes the algorithm slow, but it is necessary to
        % get a tight packing of points.
        [~, minIndex] = min(distances);
        xAdded = [xAdded; xpos(minIndex)]; %#ok<AGROW>
        yAdded = [yAdded; y(minIndex)]; %#ok<AGROW>
        colorAdded = [colorAdded; aCol(catIndex)]; %#ok<AGROW>
        x(minIndex) = [];
        y(minIndex) = [];
    end
    
    if ~any(aCol{catIndex} == 'x')
        % The marker 'x' is plotted using different marker settings.
        plot(aAxes,...
            xAdded(xAddedLength+1:end)*xscale,...
            yAdded(xAddedLength+1:end)*yscale,...
            aCol{catIndex},...
            'MarkerFaceColor', aCol{catIndex}(1),...
            'MarkerSize', 5,...
            'DisplayName', aLabels{catIndex})
    else
        plot(aAxes,...
            xAdded(xAddedLength+1:end)*xscale,...
            yAdded(xAddedLength+1:end)*yscale,...
            aCol{catIndex},...
            'LineWidth', 2,...
            'MarkerSize', 10,...
            'DisplayName', aLabels{catIndex})
    end
    hold(aAxes, 'on')
end

% Go back to the original axis limits in case they were changed by
% plotting.
set(aAxes, 'xlim', xlim)
set(aAxes, 'ylim', ylim)

% Sort the markers in the axes based on their legend labels.
ch = get(aAxes, 'Children');
if length(ch) > 1
    [~, order] = sort(get(ch, 'DisplayName'));
    set(aAxes, 'Children', ch(order));
end
% Only display a legend label once in the legend. Once a legend label has
% been added, the following markers with the same legend label are excluded
% from the legend.
displayNames = {};
for i = 1:length(ch)
    dispName = get(ch(i), 'DisplayName');
    if any(strcmp(displayNames, dispName))
        set(get(get(ch(i),'Annotation'), 'LegendInformation'),...
            'IconDisplayStyle', 'off');
    else
        displayNames = [displayNames {dispName}]; %#ok<AGROW>
    end
end
% Update the legend.
legend(aAxes, 'off')
legend(aAxes, 'show')
end