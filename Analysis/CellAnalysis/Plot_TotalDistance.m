function Plot_TotalDistance(aCells, aAxes, varargin)
% Plots the total distance traveled by cells as functions of time.
%
% The total distance traveled is defined as the sum of all distances that
% the cell and its ancestors have moved during the experiment. This value
% is equal to the lengths of the trajectories of the cells that come before
% the cell in the lineage tree, plus the length of the trajectory of the
% cell up to the time point of interest. The slope of the curve represents
% the speed of the cell. The increments associated with the displacements
% of a cell are plotted in the color of that cell. The function PrintStyle
% is called to make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% XUnit - The time unit used on the x-axis. The options are 'frames' and
%         'hours', and the default is 'hours'.
% YUnit - The area unit used on the y-axis. The options are 'pixels' and
%         'microns', and the default is 'microns'.
%
% See also:
% CellAnalysisPlayer, Plot_AxisRatio, Plot_CellSize, Plot_Fluorescence,
% Plot_LinageTree, PrintStyle

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
c = aCells(1);
imData = c.imageData;

% Plot distances traveled recursively.
for i = 1:length(aCells)
    if isempty(aCells(i).parent);
        PlotDistance(aCells(i), 0)
    end
end

% Adjust the limits of the axes.
SetYLimits(aAxes)
xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))

% Put a title on the axes.
title(aAxes, sprintf('Total distance traveled (%s)',...
    SpecChar(imData.GetSeqDir(), 'matlab')))

% Label the axes.
switch aXUnit
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end
switch aYUnit
    case 'pixels'
        ylabel(aAxes, 'Distance (pixels)')
    case 'microns'
        ylabel(aAxes, 'Distance (\mum)')
end

PrintStyle(aAxes)

    function PlotDistance(aCell, aD)
        % Plots the total distance traveled by a cell and its progeny.
        %
        % The function is recursive and should only be called from outside
        % with the root cells in lineage trees as input arguments.
        %
        % Inputs:
        % aCell - Cell for which the total distance traveled should be
        %         plotted. The function will also recursively plot the
        %         total distances traveled by the progeny of the cell.
        % aD - The total distance traveled by the ancestors of a cell. This
        %      is used to place each curve in the right place on the
        %      y-axis.
        
        % Time (x-coordinates of plot).
        t = aCell.firstFrame : aCell.lastFrame;
        if strcmpi(aXUnit, 'hours')
            t = imData.FrameToT(t);
        end
        
        % Total distance traveled (y-coordinates of plot).
        dx = diff(aCell.cx);
        dy = diff(aCell.cy);
        if isempty(aCell.cz)
            dz = zeros(size(dx));
        else
            dz = diff(aCell.cz) * imData.voxelHeight;
        end
        dd = sqrt(dx.^2 + dy.^2 + dz.^2);  % Movements in individual frames.
        if strcmpi(aYUnit, 'microns')
            dd = imData.PixelToMicroM(dd);
        end
        d = aD + [0 cumsum(dd)];  % Total distance traveled.
        
        plot(aAxes, t, d, 'LineWidth', 2, 'Color', aCell.color);
        hold(aAxes, 'on')
        
        % Plot child branches recursively.
        ch = aCell.children;
        if ~isempty(ch)
            for j = 1:length(ch)
                PlotDistance(ch(j), d(end))
            end
        end
    end
end