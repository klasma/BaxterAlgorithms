function Tree_AvgSize(aCells, aAxes, varargin)
% Plots the average speeds of cells as a lineage tree of dots.
%
% The function is a wrapper for Trees. Each cell is represented by a dot.
% The y-coordinate of the dot is the average size over the life time of the
% cell. The x-coordinate is the generation of the cell. The dots of all
% cells are connected to the dots of their parents and their children, so
% that the dots form lineage trees. The function PrintStyle is called to
% make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
%
% Property/Value inputs:
% XUnit - Time unit from CellAnalysisPlayer. (not used)
% YUnit - Length unit from CellAnalysisPlayer. If it is 'pixels', the area
%         unit will be pixels and if it is 'microns', the area unit will be
%         square microns.
%
% See also:
% Trees, Tree_AvgAxisRatio, Tree_AvgSpeed, Plot_LineageTree,
% CellAnalysisPlayer, PrintStyle

Trees(aAxes, aCells, 'avgSize', varargin{:})

% Put a title on the axes object.
c = aCells(1);
title(aAxes, sprintf('Lineage tree of average size (%s)',...
    SpecChar(FileEnd(c.seqPath), 'matlab')))

PrintStyle(aAxes)
end