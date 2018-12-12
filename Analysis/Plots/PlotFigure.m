function oFigure = PlotFigure(aName, aCaption, varargin)
% Creates a figure with a name and a caption.
%
% The caption is placed in the UserData of the figure, so that it is
% inserted as a caption if the figure is exported as a part of a tex- or
% pdf-document. The caption can also be displayed by pressing a menu
% labeled "Caption" in the menu bar of the figure. The figure has all the
% menus and tools that a normal figure has.
%
% Inputs:
% aName - Name that will be displayed at the top of the figure.
% aCaption - String with caption text.
%
% Property/Value inputs:
% The function accepts all property/value pairs that the built in figure
% function accepts, but you should not specify 'Name' or 'UserData'.
%
% Outputs:
% oFigure - Handle of figure object.
%
% See also:
% PlotGUI, SavePlotsGUI

oFigure = figure(...
    'Name', aName,...
    'NumberTitle', 'off',...
    'UserData', aCaption,...
    varargin{:});

% Create the Caption menu.
uimenu('Parent', oFigure, 'Label', 'Caption',...
    'Callback', {@CaptionCallback, aCaption})
end

function CaptionCallback(~, ~, aCaption)
% Opens a dialogs with the caption text when the Caption menu is pressed.

msgbox(aCaption, 'Caption')
end