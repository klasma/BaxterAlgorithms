function SpeedOverTime(aCells, aFigure)
% Plots the average cell speed as a function of time.
%
% The function is a wrapper for the function Overtime_generic, with 'speed'
% as the third input argument.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% OverTime_generic, AxisRatioOverTime, SizeOverTime, PlotGUI.

OverTime_generic(aCells, aFigure, 'speed')
end