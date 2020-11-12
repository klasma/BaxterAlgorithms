function Plot_ParameterTree(aCells, aAxes, aParameter, varargin)
% Plots a lineage tree with branches colored by cell property.
%
% This function plots a lineage tree where the branches are colored based
% on the either the sizes or the axis ratios of the cells in the individual
% frames. A color bar is drawn to the right of the lineage tree. The colors
% are mapped to a logarithmic scale. The color bar for size has tick marks
% with values given in pixels or square microns for 2D data and voxels or
% cubic microns for 3D data.
%
% Inputs:
% aCells - Array of Cell objects to plot the lineage tree for.
% aAxes - Axes object to plot in.
% aParameter - The name of the parameter to be plotted. The allowed values
%              are 'size' and 'axisratio'.
%
% Property/value inputs:
% XUnit - Unit for time. ['hours'] or 'frames'.
% YUnit - Unit for cell size. If this parameter is 'microns', the unit will
%         be microns^2 for 2D data and microns^3 for 3D data. If it is
%         'pixels', the unit will be pixels for 2D data and voxels for 3D
%         data. This input is ignored for axis ratio plots.['microns'] or
%         'pixels'.
% Min - The minimum parameter value to plot (in the specified units). Lower
%       values will be replaced by this value. The default is 0, meaning
%       that there is no lower limit.
% Max - The maximum parameter value to plot (in the specified units).
%       Higher values will be replaced by this value. The default is inf,
%       meaning that there is no upper limit.
% Vertical - Plots the tree vertically from the top of the axes to the
%            bottom. In this case the axes are rotated so that the x-axis
%            points downward and the y-axis points to the right. true or
%            [false].
% MarkDeath - If this is true, death events are plotted as x:es in the
%             lineage tree. The default is true.
% StyleFunction - Function handle to a function which takes the axes
%                 object as input and changes the plot style by altering
%                 line thicknesses, font sizes, and other parameters.
% ColorMap - MATLAB color map which will be used to represent the different
%            parameter values. The default is jet(1000).
%
% See also:
% SaveTikzSizeTree, Plot_LineageTree

% Parse property/value inputs.
[   aXUnit,...
    aYUnit,...
    aMin,...
    aMax,...
    aVertical,...
    aMarkDeath,...
    aStyleFunction,...
    aColorMap] = GetArgs(...
    {'XUnit',...
    'YUnit',...
    'Min',...
    'Max',...
    'Vertical',...
    'MarkDeath',...
    'StyleFunction',...
    'ColorMap'},...
    {'hours', 'microns', 0, inf, false, true, [], jet(1000)},...
    false,...
    varargin);

% Remove the contents of the axes.
cla(aAxes)
hold(aAxes, 'off')

cells = AreCells(aCells);

% Take image data from the first cell.
if ~isempty(cells)
    imData = cells(1).imageData;
else
    % Return if there were no cells to plot.
    return
end

% Find the y-values to plot branches at.
Y1 = nan(size(cells));  % y-values where the branches start.
Y2 = nan(size(cells));  % y-values where the branches end.
maxY = 0;  % Largest y-value currently assigned to a branch.
for i = 1:length(cells)
    if isempty(cells(i).parent) && isnan(Y2(i))
        FindY(cells(i));
    end
end

% Compute cell areas ahead of time.
values = cell(size(cells));
for i = 1:length(cells)
    regionProps = [cells(i).regionProps];
    
    switch lower(aParameter)
        case 'size'
            if imData.GetDim() == 2 && ~isempty(regionProps) && isfield(regionProps, 'Area')
                % Use pre-computed areas in the region properties.
                values{i} = [regionProps.Area];
            elseif imData.GetDim() == 3 && ~isempty(regionProps) && isfield(regionProps, 'Volume')
                % Use pre-computed volumes in the region properties.
                values{i} = [regionProps.Volume];
            else
                values{i} = zeros(1, cells(i).lifeTime);
                % Compute the sizes from the binary masks.
                for j = 1:cells(i).lifeTime
                    values{i}(j) = sum(cells(i).blob(j).image(:));
                end
            end
            
            % Convert the cell sizes from pixels or voxels to microns^2 or
            % microns^3, if necessary.
            if strcmpi(aYUnit, 'microns')
                if imData.GetDim() == 2
                    values{i} = imData.Pixel2ToMicroM2(values{i});
                else
                    values{i} = imData.VoxelToMicroM3(values{i});
                end
            end
        case 'axisratio'
            if isempty(regionProps) ||...
                    ~isfield(regionProps, 'MajorAxisLength') ||...
                    ~isfield(regionProps, 'MinorAxisLength')
                error('There are no pre-computed axis ratios.')
            else
                values{i} = [regionProps.MajorAxisLength] ./...
                    [regionProps.MinorAxisLength];
            end
        otherwise
            error(['Plot_ParameterTree cannot plot ''%s''. '...
                'Only ''size'' and ''axis ratio'' can be plotted.'],...
                aParameter)
    end
    
    % Truncate the values if minimum or maximum values were given as input.
    values{i} = max(values{i}, aMin);
    values{i} = min(values{i}, aMax);
    
    values{i} = log10(values{i});
end
allValues = [values{:}];
minValue = min(allValues);
maxValue = max(allValues);

% Plot lines.
for i = 1:length(cells)
    c = cells(i);
    ff = c.firstFrame;
    lf = c.lastFrame;
    
    for t = ff:lf
        % The cell branch is plotted frame by frame, so that different
        % time intervals can be colored in different colors.
        
        if t == ff && ~isempty(c.parent)
            % Beginning of a branch. 90 degree angle (or straight line if
            % the cell is the only daughter cell).
            x = [ff ff ff+1];
            y = [Y1(i) Y2(i) Y2(i)];
        else
            % Continuation of a branch, as a straight line.
            x = [t t+1];
            y = [Y2(i) Y2(i)];
        end
        
        % Convert time points from frames to hours if necessary.
        if strcmpi(aXUnit, 'hours')
            x = imData.FrameToT(x);
        end
        
        % Determine plotting color.
        a = values{i}(t-ff+1);
        colorIndex = ceil((a-minValue) /...
            (maxValue-minValue)*size(aColorMap,1));
        colorIndex = max(colorIndex, 1);
        color = aColorMap(colorIndex,:);
        
        % Draw the branch for this time point.
        if length(x) == 3
            % Beginning of a branch.
            plot(aAxes, x(1:2), y(1:2),...
                'LineWidth', 1, 'Color', [0.5 0.5 0.5])
            plot(aAxes, x(2:end), y(2:end), 'LineWidth', 3, 'Color', color)
        else
            % Continuation of a branch.
            plot(aAxes, x, y, 'LineWidth', 3, 'Color', color)
        end
        
        hold(aAxes, 'on')
    end
end

% Plot x:es at death events. The markers are plotted after the lines, so
% that the lines do not cover them.
if aMarkDeath
    for i = 1:length(cells)
        c = cells(i);
        lf = c.lastFrame;
        
        if c.died
            x = lf+1;
            if strcmpi(aXUnit, 'hours')
                x = imData.FrameToT(x);
            end
            y = Y2(i);
            plot(aAxes, x, y, 'kx',...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','k',...
                'LineWidth', 2,...
                'MarkerSize', 10)
        end
    end
end

% Set axis limits and a title.
set(aAxes, 'ylim', [0 maxY+1])
if ~isempty(aCells)
    xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))
    title(aAxes, sprintf('Cell Size Tree (%s)',...
        SpecChar(imData.GetSeqDir(), 'matlab')))
end

% Set axis labels.
switch aXUnit
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end
ylabel('')

% Show only an x-grid. Y-coordinates are not interesting.
set(aAxes, 'XGrid', 'on')
set(aAxes, 'YGrid', 'off')
set(aAxes, 'YTick', [])

% Rotates the lineage tree so that it is vertical.
if aVertical
    view(aAxes, 90, 90)
end

if ~isempty(aStyleFunction)
    feval(aStyleFunction, aAxes)
end

% Hold should be on even if there were no cells to plot.
hold(aAxes, 'on')

% Create a color bar which shows what values the different colors
% correspond to.
colormap(aAxes, aColorMap)
set(aAxes, 'clim', [minValue maxValue])

% Compute locations and labels for the tick marks. The colors are assigned
% using a logarithmic scale.
ticks = ceil(minValue):floor(maxValue);
tickLabels = 10.^ticks;
% Introduce 9 tick marks between each adjacent pair if there are less than
% 3 tick marks in total.
if length(ticks) < 3
    tickLabels = [];
    for n = floor(minValue):ceil(maxValue)
        tickLabels = [tickLabels 10^n:10^n:9*10^n]; %#ok<AGROW>
    end
    tickLabels(tickLabels < 10^minValue | tickLabels > 10^maxValue) = [];
    ticks = log10(tickLabels);
end
% Add tick marks and tick labels to the color bar.
cbar = colorbar(aAxes,...
    'Ticks', ticks,...
    'TickLabels', tickLabels);

% Add a label to the color bar.
switch lower(aParameter)
    case 'size'
        switch lower(aYUnit)
            case 'pixels'
                if imData.GetDim() == 2
                    ylabel(cbar, 'Area (pixels)')
                else
                    ylabel(cbar, 'Volume (voxels)')
                end
            case 'microns'
                if imData.GetDim() == 2
                    ylabel(cbar, 'Area (\mum^2)')
                else
                    ylabel(cbar, 'Volume (\mum^3)')
                end
            otherwise
                error('Unknown y-unit %s', aYUnit)
        end
    case 'axisratio'
        ylabel(cbar, 'Ratio')
end

    function oY = FindY(aCell)
        % Computes y-coordinates for a cell branch.
        %
        % FindY computes the y-coordinates at which to plot the branch of a
        % lineage tree, and inserts the values into Y1 and Y2. The
        % algorithm is recursive, so that the y-value of a parent cell is
        % set to the mean y-value of the two daughter cells. The function
        % assumes that only cells without mother cells are given as inputs
        % when the function is called from some other function. The
        % function will call itself with daughter cells as inputs, and by
        % doing that it will traverse the lineage tree using depth first
        % search from bottom to top (in a horizontal lineage tree).
        %
        % Inputs:
        % aCell - The cell for which to compute the y-values.
        %
        % Outputs:
        % oY - The y-value at which the branch ends.
        
        if isempty(aCell.children)
            % Leaf cells in the tree are given integer y-values from 1 to
            % the total leaf count.
            oY = maxY + 1;
            maxY = oY;
        elseif length(aCell.children) == 1
            % There is no branching. The single daughter cell continues the
            % mother cell branch.
            oY = FindY(aCell.children(1));
            Y1(GetIndex(cells, aCell.children(1))) = oY;
        else
            % Mother branches end in the middle between the two daughter
            % branches.
            oY = (FindY(aCell.children(1)) + FindY(aCell.children(2))) / 2;
            Y1(GetIndex(cells, aCell.children(1))) = oY;
            Y1(GetIndex(cells, aCell.children(2))) = oY;
        end
        if isempty(aCell.parent)
            Y1(GetIndex(cells, aCell)) = oY;
        end
        Y2(GetIndex(cells, aCell)) = oY;
    end
end

function oIndex = GetIndex(aCellVec, aCell)
% Returns the index that a cell has in an array of cells.
%
% Inputs:
% aCellVec - Array of cells.
% aCell - Cell to find the index of.
%
% Outputs:
% oIndex - The index (indices) of aCell in aCellVec, or [] if aCell is not
%          in aCellVec.

oIndex = find(aCellVec == aCell);
end