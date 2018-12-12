function Tree_AvgSpeed(aCells, aAxes, varargin)
% Plots the average speeds of cells as a lineage tree of dots.
%
% The function is a wrapper for Trees. Each cell is represented by a dot.
% The y-coordinate of the dot is the average speed over the life time of
% the cell. The x-coordinate is the generation of the cell. The dots of all
% cells are connected to the dots of their parents and their children, so
% that the dots form lineage trees. The function PrintStyle is called to
% make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% XUnit - Time unit from CellAnalysisPlayer. If it is 'frames', the speed
%         unit will be ??/frame and if it is 'hours' the speed unit will be
%         ??/hour.
% YUnit - Length unit from CellAnalysisPlayer. If it is 'pixels', the speed
%         unit will be pixels/?? and if it is 'microns', the speed unit
%         will be microns/??.
%
% See also:
% Trees, Tree_AvgAxisRatio, Tree_AvgSize, Plot_LineageTree,
% CellAnalysisPlayer, PrintStyle

Trees(aAxes, aCells, 'avgSpeed', varargin{:})

% Put a title on the axes object.
c = aCells(1);
title(aAxes, sprintf('Lineage tree of average speed (%s)',...
    SpecChar(FileEnd(c.seqPath), 'matlab')))

PrintStyle(aAxes)
end