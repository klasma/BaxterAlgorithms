function SingleAxFig(aFig, aFun)
% Creates an axes in a figure and executes a plotting function on the axes.
%
% This function is used as a wrapper for plotting functions that operate on
% axes, so that a figure object can be passed to them in SaveFigure. Before
% creating the axes object, the function removes all existing graphics
% objects from the figure.
%
% Inputs:
% aFig - Figure object.
% aFun - Plotting function which takes an axes object as input.
%
% See also:
% MultiAxFig, PopulationAnalysisGUI, SaveFigure

delete(get(aFig, 'Children'));
ax = axes('Parent', aFig);
feval(aFun, ax)
end