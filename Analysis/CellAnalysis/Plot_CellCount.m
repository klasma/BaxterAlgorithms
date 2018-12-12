function Plot_CellCount(aCells, aAxes, varargin)
% Plots the number of cells in an image or clone over time.
%
% The function takes an array of cells as input and plots the cell count as
% a function of time. The function is meant to be called by
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
%
% See also:
% CellAnalysisPlayer, LiveCount, PrintStyle

% Parse property/value inputs.
aXUnit = GetArgs({'XUnit'}, {'hours'}, false, varargin);

% Clear the previous plot.
cla(aAxes)
hold(aAxes, 'off')

if isempty(aCells)
    return
end
imData = aCells(1).imageData;

[numFrames, t] = TimeSpan(aCells);

if ~isempty(aCells)
    % Convert from hours to frames if necessary.
    if strcmpi(aXUnit, 'frames')
        t = imData.TToFrame(t);
    end
    
    % Count the number of cells in each frame.
    numCells = zeros(numFrames,1);
    for i = 1:length(aCells)
        c = aCells(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        numCells(ff:lf) = numCells(ff:lf) + 1;
    end
    
    plot(aAxes, t, numCells, 'LineWidth', 2)
end
% Set hold to 'on' so that a zoom box can be plotted in the axes.
hold(aAxes, 'on')

SetYLimits(aAxes)
xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))

title(aAxes, sprintf('Number of cells (%s)',...
    SpecChar(imData.GetSeqDir(), 'matlab')))

switch aXUnit
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end
ylabel(aAxes, 'Count')

PrintStyle(aAxes)
end