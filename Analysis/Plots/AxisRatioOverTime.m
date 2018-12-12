function AxisRatioOverTime(aCells, aFigure)
% Plots the average cell axis ratio as a function of time.
%
% The function is a wrapper for the function Overtime_generic, with
% 'axisratio' as the third input argument.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% OverTime_generic, SizeOverTime, SpeedOverTime, PlotGUI.

OverTime_generic(aCells, aFigure, 'axisratio')
end