function Trees(aAxes, aCells, aProperty, varargin)
% Plots cell properties as a lineage tree of dots.
%
% Each cell is represented by a dot. The y-coordinate of the dot is the
% value of the cell property and the x-coordinate is the generation of the
% cell. The dots of all cells are connected to the dots of their parents
% and their children, so that the dots form lineage trees. The plots give
% information about how cell properties change from generation to
% generation in different branches of lineage trees. The function
% PrintStyle is called to make the plotting style consistent with other
% plots.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of cell objects.
% aProperty - The name of the cell property to be plotted. The property has
%             to be a parameter of the Cell class.
% XUnit - The time unit to be used for the property. The options are
%         'frames' and 'hours', and the default is 'hours'. This input
%         is only respected if the property is avgSpeed. Otherwise the
%         original unit defined in the Cell class is used.
% YUnit - The length unit to be used for the property. The options are
%         'pixels' and 'microns', and the default is 'microns'. This input
%         is only respected if the property is avgSize or avgSpeed.
%         Otherwise the original unit defined in the Cell class is used.
%
% See also:
% Tree_AvgAxisRatio, Tree_AvgSize, Tree_AvgSpeed, Plot_LineageTree,
% CellAnalysisPlayer, PrintStyle

% Parse property/value inputs.
[aXUnit, aYUnit] = GetArgs(...
    {'XUnit', 'YUnit'},...
    {'hours', 'microns'},...
    true, varargin);

% Clear the previous plot.
cla(aAxes)
hold(aAxes, 'off')

% Warn the user if the inputs about units are ignored.
if ~any(strcmp(aProperty, {'avgAxisRatio', 'avgSize', 'avgSpeed'})) &&...
        ~isempty(varargin)
    warning(['The scaling has not been defined for '...
        'the parameter %s. Ignoring input arguments '...
        'about units.'], aProperty)
end

imData = aCells(1).imageData;

maxGen = max([aCells.generation]);

% Extract the property to be plotted from all cells.
prop = [aCells.(aProperty)];
prop(isnan(prop)) = [];
if isempty(prop)
    return
end
prop = ScaleProperty(prop);
minVal = min(prop);
maxVal = max(prop);

% Partition the cells into lineage trees.
[pCellVec, labels] = PartitionCells(aCells, 'cloneParent');
cloneParents = [labels{:}];
% Order the root cells of the lineage trees in decreasing order based on
% the property to be plotted. The lineage trees will be potted in this
% order.
[~, order] = sort([cloneParents.(aProperty)], 'descend');

for p = 1:length(pCellVec)
    for i = 1 : length(pCellVec{order(p)})
        c = pCellVec{order(p)}(i);
        if c.generation == 1
            % Plot a dot representing the cell.
            plot(aAxes, c.generation, ScaleProperty(c.(aProperty)), 'o',...
                'Color', c.color,...
                'MarkerFaceColor', c.color,...
                'MarkerEdgeColor', c.color,...
                'MarkerSize', 15)
            hold(aAxes, 'on')
        else
            x = [c.generation-1, c.generation];
            y = ScaleProperty([c.parent.(aProperty) c.(aProperty)]);
            if length(y) == 2
                % Plot a line connecting the cell to its parent.
                plot(aAxes, x, y, 'Color', 'k', 'LineWidth', 2)
                hold(aAxes, 'on')
                % Plot a dot representing the cell.
                plot(aAxes, x(2), y(2), 'o',...
                    'Color', c.color,...
                    'MarkerFaceColor', c.color,...
                    'MarkerEdgeColor', c.color,...
                    'MarkerSize', 15)
            end
        end
    end
end

% Remove legend from previous plot.
legend(aAxes, 'off')

% x-axis.
set(aAxes, 'xlim', [0, maxGen+1])
set(aAxes, 'XTick', 1:maxGen)
xlabel(aAxes, 'Generation')

% y-axis.
if minVal == maxVal
    % Show an interval of 1 if there is a single y-value.
    set(aAxes, 'ylim', [minVal-0.5 maxVal+0.5])
else
    % Put a 5% margin above and below the dots.
    yMargin = (maxVal-minVal)*0.05;
    set(aAxes, 'ylim', [minVal-yMargin maxVal+yMargin])
end

% Put a label on the y-axis.
switch aProperty
    case 'avgSize'
        if imData.GetDim() == 2
            switch lower(aYUnit)
                case 'microns'
                    yStr = 'Area (\mum^2)';
                case 'pixels'
                    yStr = 'Area (pixels)';
            end
        else
            switch lower(aYUnit)
                case 'microns'
                    yStr = 'Volume (\mum^3)';
                case 'pixels'
                    yStr = 'Volume (voxels)';
            end
        end
    case 'avgSpeed'
        switch lower(aXUnit)
            case 'frames'
                timeStr = 'frame';
            case 'hours'
                timeStr = 'hr';
        end
        switch lower(aYUnit)
            case 'microns'
                lengthStr = '\mum';
            case 'pixels'
                lengthStr = 'pixels';
        end
        yStr = sprintf('Speed (%s/%s)', lengthStr, timeStr);
    otherwise
        % Use the original label defined in the Cell class. Inputs about
        % units were ignored.
        yStr = GetLabel(aProperty, imData.GetDim() == 3);
end
ylabel(aAxes, yStr)

PrintStyle(aAxes)

    function oValue = ScaleProperty(aValue)
        % Scales property values based on the units defined in the inputs.
        %
        % The function takes care of scaling from microns to pixels and
        % from hours to frames in the property is avgSize or avgSpeed.
        %
        % Inputs:
        % aValue - Array of unscaled values (sizes, speeds, or axis ratios)
        %          where distance is measured in microns and time is
        %          measured in hours.
        %
        % Outputs:
        % oValue - Array of scaled values (sizes, speeds, or axis ratios)
        %          where distance is measured in pixels and time is
        %          measured in frames.
        
        oValue = aValue;
        switch aProperty
            case 'avgSize'
                % The original unit is square microns.
                if strcmpi(aYUnit, 'pixels')
                    oValue = oValue / imData.xCalibrationMicrons^2;
                end
            case 'avgSpeed'
                % The original unit is microns per hour.
                if strcmp(aYUnit, 'pixels')
                    oValue = oValue / imData.xCalibrationMicrons;
                end
                if strcmp(aXUnit, 'frames')
                    oValue = oValue / (3600 / imData.dT);
                end
            case 'avgAxisRatio'
                % No scaling.
        end
    end
end