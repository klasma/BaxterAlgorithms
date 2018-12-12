function oCells = SetdiffCells(aCells, aCells2Remove)
% Naive implementation of the setdiff set operation, for the Cell class.
%
% The built in function setdiff uses the built in function sort, which has
% caused a segfault for a particular array of cells. To avoid such errors
% in the future, this function should be used instead of unique. This
% function is slow when many elements are removed, but is faster than the
% built in function if few elements are removed. In contrast
% to the build in function, this function will not sort the elements in the
% returned array. The function works for any array, but is meant to be used
% only for arrays of Cell objects.
%
% The segfault caused by sort occurred in MATLAB 2014b and may be fixed in
% future releases.
%
% Inputs:
% aCells - Array of Cell objects from which to remove objets.
% aCells2Remove - Array of Cell objects to be removed.
%
% Outputs:
% oCells - Array of Cell objects where objects have been removed.
%
% See also:
% UniqueCells, Cell

remove = false(size(aCells));
for i = 1:length(aCells2Remove)
    remove = remove | aCells == aCells2Remove(i);
end
oCells = aCells(~remove);
end