function oCells = AreCells(aCells)
% Finds the Cell objects which are believed to be real cells.
%
% Inputs :
% aCells - Array of cell objects
%
% Outputs :
% oCells - Array containing all cell objects in 'aCells' that had the field
%          'isCell' set to true.
%
% See also:
% NotCells

if isempty(aCells)
    oCells = aCells;
    return
end

oCells = aCells([aCells.isCell]);
end