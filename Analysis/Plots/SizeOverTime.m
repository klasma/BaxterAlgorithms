function SizeOverTime(aCells, aFigure)
% Plots the average cell size as a function of time.
%
% The function is a wrapper for the function Overtime_generic, with 'size'
% as the third input argument.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% OverTime_generic, AxisRatioOverTime, SpeedOverTime, PlotGUI.

OverTime_generic(aCells, aFigure, 'size')
end