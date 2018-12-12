function Plot_AxisRatio(aCells, aAxes, varargin)
% Plots the axis ratios of cells over time.
%
% The axis ratios of all cells are plotted in the same axes, and the curves
% are plotted in the colors of the cells. The function is meant to be
% called by CellAnalysisPlayer. The function PrintStyle is called to make
% the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% XUnit - The time unit used on the x-axis. The options are 'frames' and
%         'hours', and the default is 'hours'.
%
% See also:
% CellAnalysisPlayer, Plot_CellSize, Plot_Fluorescence, Plot_LinageTree,
% Plot_TotalDistance, PrintStyle

% Parse property/value inputs.
aXUnit = GetArgs({'XUnit'}, {'hours'}, false, varargin);

% Clear the previous plot.
cla(aAxes)
hold(aAxes, 'off')

if isempty(aCells)
    return
end
imData = aCells(1).imageData;

for i = 1:length(aCells)
    c = aCells(i);
    
    % Create array of axis ratios.
    regionProps = c.regionProps;
    if isempty(regionProps) || ~isfield(regionProps, 'MajorAxisLength')
        continue
    end
    ratio = [regionProps.MajorAxisLength] ./ [regionProps.MinorAxisLength];
    
    % Create array of time points.
    switch aXUnit
        case 'hours'
            t = imData.FrameToT(c.firstFrame : c.lastFrame);
        case 'frames'
            t = c.firstFrame : c.lastFrame;
    end
    
    % Plot axis ratio over time for one cell.
    PlotWithNan(aAxes, t, ratio, 'Color', c.color, 'LineWidth', 2);
    hold(aAxes, 'on')
end

SetYLimits(aAxes)
xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))

title(aAxes, sprintf('Ratio between cells major and minor axes (%s)',...
    SpecChar(imData.GetSeqDir(), 'matlab')))

switch aXUnit
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end
ylabel(aAxes, 'Ratio')

PrintStyle(aAxes)
end