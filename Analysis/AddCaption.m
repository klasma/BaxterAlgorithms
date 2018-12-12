function AddCaption(aFigure, aCaption)
% AddCaption adds a dropdown menu labeled Caption, to a figure.
%
% The user can then click on the menu to get an explanation of the plots in
% the figure.
%
% Inputs:
% aFigure - Handle to a figure.
% aCaption - Character array containing the caption.

menu = uimenu('Parent', aFigure, 'Label', 'Caption');
uimenu('Parent', menu, 'Label', aCaption);
end