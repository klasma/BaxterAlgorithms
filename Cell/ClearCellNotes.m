function ClearCellNotes(aCells, varargin)
% Sets all notes of cells to 0 or a specified value.
%
% Inputs:
% aCells - Vector of cells to be processed.
%
% Property/Value inputs:
% Value - Specifies the value to set all notes will be to. This has to be a
%         scalar. The default value is 0.
%
% See also:
% Cell

aValue = GetArgs({'Value'}, {0}, true, varargin);

for i = 1:length(aCells)
    aCells(i).notes = ones(1, aCells(i).lifeTime) * aValue;
end
end