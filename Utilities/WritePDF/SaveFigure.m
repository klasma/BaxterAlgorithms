function SaveFigure(aFig, aSaveFile, aFmt, varargin)
% Saves a figure to an image file.
%
% If either a width or a height is specified, this dimension is used and
% the other dimension is given by preserving the plot proportions. If both
% a width and a hight are given, the plot changes proportions if the input
% argument KeepProp is set to false. Otherwise the argument producing the
% smallest image is used. If neither are given, the size is given by the
% size of the plot on the screen and will therefore depend on the size of
% the screen unless the figure size is set in inches.
%
% Inputs:
% aFig - Handle of figure to be saved.
% aSaveFile - Path of the file to be created.
% aFmt - Image format string sent to the MATLAB function PRINT. Use -dpdf
%        for pdf, -depsc for color eps, -dtiff for tif, and so on.
%
% Parameter/Value pairs:
% Width - Width of the saved image in inches.
% Height - Height of the saved image in inches.
% KeepProp - Keep width/height ratio of the figure
% Dpi - Resolution in dots per inch. Works only for raster formats.
%
% See also:
% SavePlots, SavePlotsGUI

% Get inputs.
pnames_dflts = {...
    'Width', []
    'Height', 7.5
    'KeepProp', true
    'Dpi' 300};
[aWidth, aHeight, aKeepProp, aDpi] = ...
    GetArgs(pnames_dflts(:,1), pnames_dflts(:,2), true, varargin);

% Old values to be restored afterwards.
figUnits = get(aFig, 'Units');
figPaperUnits = get(aFig, 'PaperUnits');

% Get width and height of figure.
set(aFig, 'Units', 'Inches', 'PaperUnits', 'Inches')
figPos = get(aFig, 'Position');
wFig = figPos(3);
hFig = figPos(4);

% Set paper size based on inputs.
if isempty(aWidth) && isempty(aHeight)
    aWidth = wFig;
    aHeight = hFig;
elseif isempty(aWidth)
    aWidth = wFig*aHeight/hFig;
elseif isempty(aHeight)
    aHeight = hFig*aWidth/wFig;
elseif aKeepProp
    minScale = min(aWidth/wFig, aHeight/hFig);
    aWidth = wFig*minScale;
    aHeight = hFig*minScale;
end
set(aFig,...
    'PaperSize', [aWidth aHeight],...
    'PaperPosition', [0 0 aWidth aHeight])

% Write figure to file.
print(aFig, aSaveFile, aFmt, sprintf('-r%d', aDpi), '-noui')

% Restore old values.
set(aFig, 'Units', figUnits, 'PaperUnits', figPaperUnits)
end