function Tree_AvgAxisRatio(aCells, aAxes, varargin)
% Plots the average axis ratios of cells as a lineage tree of dots.
%
% The function is a wrapper for Trees. Each cell is represented by a dot.
% The y-coordinate of the dot is the average axis ratio over the life time
% of the cell. The axis ratio is the ratio between the major axis and the
% minor axis of the binary mask that represents the cell region. The
% x-coordinate is the generation of the cell. The dots of all cells are
% connected to the dots of their parents and their children, so that the
% dots form lineage trees. The function PrintStyle is called to make the
% plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of cell objects.
% aAxes - Axes object to plot in.
% varargin - The function accepts additional input arguments, and forwards
%            them to Trees. This is done to allow arguments with x- and
%            y-units from CellAnalysisPlayer, but these inputs do not have
%            any effect on this plot.
%
% See also:
% Trees, Tree_AvgSize, Tree_AvgSpeed, Plot_LineageTree, CellAnalysisPlayer,
% PrintStyle

Trees(aAxes, aCells, 'avgAxisRatio', varargin{:})

% Put a title on the axes object.
c = aCells(1);
title(aAxes, sprintf('Lineage tree of average axis ratio (%s)',...
    SpecChar(FileEnd(c.seqPath), 'matlab')))

PrintStyle(aAxes)
end