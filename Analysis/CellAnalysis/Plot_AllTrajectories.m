function Plot_AllTrajectories(aCells, aAxes, varargin)
% Plots cell trajectories without showing the image.
%
% The centroids of the cells are plotted as circles connected by lines. The
% trajectories are plotted from the first frame of the experiment to the
% last, in the colors of the cells. If there is a circular microwell, the
% outline of the well is shown as a black circle. The x- and y-units can be
% set to either pixels or microns. The origin placed at the enter of the
% microwell if there is a circular microwell. Otherwise it is placed in the
% center of the image. The function is meant to be called by
% CellAnalysisPlayer. The function PrintStyle is called to make the
% plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% YUnit - The unit used on both the x- and y-axis. The options are 'pixels'
%         and 'microns', and the default is 'microns'.
%
% See also:
% PlotTrajectories, CellAnalysisPlayer, ManualCorrectionPlayer, PrintStyle

% Parse property/value inputs.
aYUnit = GetArgs({'YUnit'}, {'microns'}, false, varargin);

% Clear the previous plot.
cla(aAxes)
hold(aAxes, 'off')

if isempty(aCells)
    return
end
c = aCells(1);
imData = c.imageData;

% Plotting options for trajectories.
opts = struct(...
    'dMarker', {{'o', 'o', 'o'}},...
    'dMarkerSize', [5 5 5],...
    'dMarkerEdgeColor', {{[], [], []}},...
    'dMarkerFaceColor', {{'none', 'none', 'none'}},...
    'cMarker', {{'o', 'o', 'o'}},...
    'cMarkerSize', [5 5 5],...
    'cMarkerEdgeColor', {{[], [], []}},...
    'cMarkerFaceColor', {{'none', 'none', 'none'}},...
    'fMarker', {{'*', '*', '*'}},...
    'fMarkerSize', [5 5 5],...
    'fMarkerEdgeColor', {{'k', 'k', 'k'}},...
    'fMarkerFaceColor', {{'none', 'none', 'none'}});

PlotTrajectories(aAxes, aCells, imData.sequenceLength, inf, 'Options', opts)

[x, y, r] = GetWellCircle(imData);
if ~any(isnan([x y r]))
    % Draw microwell circle.
    rectangle(...
        'Parent', aAxes,...
        'Position', [x-r y-r 2*r 2*r],...
        'Curvature', [1 1],...
        'LineWidth', 3,...
        'LineStyle', '--')
else
    x = imData.imageWidth/2 + 0.5;
    y = imData.imageHeight/2 + 0.5;
end

% Set axis limits.
if ~any(isnan([x y r]))
    % 10% border around circular microwell.
    xLim = [x-r*1.1 x+r*1.1];
    yLim = [y-r*1.1 y+r*1.1];
else
    % The size of the image.
    xLim = [0.5 c.imageData.imageWidth+0.5];
    yLim = [0.5 c.imageData.imageHeight+0.5];
end
set(aAxes, 'xlim', xLim)
set(aAxes, 'ylim', yLim)

% Reverse the y-axis so that the trajectories are the same as when they are
% plotted on top of the image.
set(aAxes, 'ydir', 'reverse')

% Place the tick marks with the origin either at the center of the
% microwell or at the center of the image. The tick marks are separated by
% 100 microns or 100 pixels, depending on the unit chosen.
switch lower(aYUnit)
    case {'microns', 'micrometers'}
        xStep = 10^floor(log10(imData.PixelToMicroM(diff(xLim)/2)));
        xMicron = -xStep*10:xStep:xStep*10;
        xPixel = imData.MicroMToPixel(xMicron) + x;
        xMicron(xPixel < xLim(1) | xPixel > xLim(2)) = [];
        xPixel(xPixel < xLim(1) | xPixel > xLim(2)) = [];
        
        yStep = 10^floor(log10(imData.PixelToMicroM(diff(yLim)/2)));
        yMicron = -yStep*10:yStep:yStep*10;
        yPixel = imData.MicroMToPixel(yMicron) + y;
        yMicron(yPixel < yLim(1) | yPixel > yLim(2)) = [];
        yPixel(yPixel < yLim(1) | yPixel > yLim(2)) = [];
        
        set(aAxes, 'XTick', xPixel);
        set(aAxes, 'XTickLabel', xMicron)
        set(aAxes, 'YTick', yPixel);
        set(aAxes, 'YTickLabel', yMicron)
        
        xlabel(aAxes, '\mum')
        ylabel(aAxes, '\mum')
    case 'pixels'
        xStep = 10^floor(log10(diff(xLim)/2));
        xLabels = -xStep*10:xStep:xStep*10;
        xValues = (-xStep*10:xStep:xStep*10) + x;
        xLabels(xValues < xLim(1) | xValues > xLim(2)) = [];
        xValues(xValues < xLim(1) | xValues > xLim(2)) = [];
        
        yStep = 10^floor(log10(yLim(2)/2));
        yLabels = -yStep*10:yStep:yStep*10;
        yValues = (-yStep*10:yStep:yStep*10) + y;
        yLabels(yValues < yLim(1) | yValues > yLim(2)) = [];
        yValues(yValues < yLim(1) | yValues > yLim(2)) = [];
        
        set(aAxes, 'XTick', xValues);
        set(aAxes, 'XTickLabel', xLabels)
        set(aAxes, 'YTick', yValues);
        set(aAxes, 'YTickLabel', yLabels)
        
        xlabel(aAxes, 'pixels')
        ylabel(aAxes, 'pixels')
end

title(aAxes, sprintf('Trajectories (%s)',...
    SpecChar(imData.GetSeqDir(), 'matlab')))

PrintStyle(aAxes)
grid(aAxes, 'on')
axis(aAxes, 'square')
end