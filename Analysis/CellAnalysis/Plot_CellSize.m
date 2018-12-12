function Plot_CellSize(aCells, aAxes, varargin)
% Plots cell sizes over time.
%
% For 2D datasets, the size of a cell is the area of the cell seen from
% above. For 3D datasets, the size is the volume of the cell. The sizes of
% all cells are plotted in the same axes, and the curves are plotted in the
% colors of the cells. The function is meant to be called by
% CellAnalysisPlayer. The function PrintStyle is called to make the
% plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% XUnit - The time unit used on the x-axis. The options are 'frames' and
%         'hours', and the default is 'hours'.
% YUnit - The length unit used on the y-axis. The options are 'pixels' and
%         'microns', and the default is 'microns'.
%
% See also:
% CellAnalysisPlayer, Plot_AxisRatio, Plot_Fluorescence, Plot_LinageTree,
% Plot_TotalDistance, PrintStyle

% Parse property/value inputs.
[aXUnit, aYUnit] = GetArgs(...
    {'XUnit', 'YUnit'},...
    {'hours', 'microns'},...
    true, varargin);

% Clear the previous plot.
cla(aAxes)
hold(aAxes, 'off')

if isempty(aCells)
    return
end
imData = aCells(1).imageData;

for i = 1:length(aCells)
    c = aCells(i);
    
    % Create array of area values.
    regionProps = [c.regionProps];
    if isempty(regionProps)
        continue
    end
    
    if imData.GetDim() == 2
        if ~isfield(regionProps, 'Area')
            continue
        end
        cellSize = [regionProps.Area];
        if strcmpi(aYUnit, 'microns')
            cellSize = imData.Pixel2ToMicroM2(cellSize);
        end
    else
        if ~isfield(regionProps, 'Volume')
            continue
        end
        cellSize = [regionProps.Volume];
        if strcmpi(aYUnit, 'microns')
            cellSize = imData.VoxelToMicroM3(cellSize);
        end
    end
    
    % Create array of time points.
    switch aXUnit
        case 'frames'
            t = c.firstFrame : c.lastFrame;
        case 'hours'
            t = imData.FrameToT(c.firstFrame : c.lastFrame);
    end
    
    % Plot axis ratio over time for one cell.
    PlotWithNan(aAxes, t, cellSize, 'Color', c.color, 'LineWidth', 2);
    hold(aAxes, 'on')
end

SetYLimits(aAxes)
xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))

title(aAxes, sprintf('Cell size (%s)',...
    SpecChar(imData.GetSeqDir(), 'matlab')))

switch aXUnit
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end

if imData.GetDim() == 2
    switch aYUnit
        case 'pixels'
            ylabel(aAxes, 'Area (pixels)')
        case 'microns'
            ylabel(aAxes, 'Area (\mum^2)')
    end
else
    switch aYUnit
        case 'pixels'
            ylabel(aAxes, 'Volume (voxels)')
        case 'microns'
            ylabel(aAxes, 'Volume (\mum^3)')
    end
end

PrintStyle(aAxes)
end