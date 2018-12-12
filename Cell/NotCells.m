function oCells = NotCells(aCells)
% Finds the Cell objects which are believed to be false positives.
%
% False positive Cell objects occur when the segmentation algorithm detects
% debris, background features or other objects which are not cells.
%
% Inputs:
% aCells - Array of cell objects
%
% Outputs:
% oCells - Array containing all cell objects in 'aCells' that had the field
%          'isCell' set to false.
%
% See also:
% AreCells

if isempty(aCells)
    oCells = aCells;
    return
end

oCells = aCells(~[aCells.isCell]);
end