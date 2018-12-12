function oCells = UniqueCells(aCells)
% Naive implementation of the unique set operation, for the Cell class.
%
% The built in function unique uses the built in function sort, which has
% caused a segfault for a particular array of cells. To avoid such errors
% in the future, this function should be used instead of unique. This
% function is a lot slower for large arrays, so the function unique should
% still be used in situations where stability is not essential. In contrast
% to the build in function, this function only removes duplicated elements
% and does not sort the elements. The function works for any array, but
% should only be used on arrays of Cell objects.
%
% The segfault caused by sort occurred in MATLAB 2014b and may be fixed in
% future releases.
%
% Inputs:
% aCells - Array of Cell objects which may contain duplicated elements.
%
% Outputs:
% oCells - Array of Cell objects where duplicated objects have been
%          removed. The leftmost object in each set of identical objects is
%          kept.
%
% See also:
% SetdiffCells, Cell

if isempty(aCells)
    oCells = aCells;
    return
end

keep = false(size(aCells));
keep(1) = true;
for i = 2:length(aCells)
    keep(i) = any(aCells(1:i-1) ~= aCells(i));
end
oCells = aCells(keep);
end