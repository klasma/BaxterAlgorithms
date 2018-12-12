function oElement = ModIndex(aArray, aIndex)
% Extract an element from an infinite periodic array.
%
% The function assumes that the array is repeated periodically, infinitely
% many times both to the left and to the right. The indexing starts from 1.
% If the array has N elements, element N+1 is equal to element 1 and
% element 0 is equal to element N. This function can be useful for example
% when a plotting function cycles through a finite number of colors. The
% function can handle indexing in both normal arrays and cell arrays.
%
% Inputs:
% aArray - Array or cell array to extract an element from.
% aIndex - The index of the element to extract. Given that the array
%          repeats itself periodically, it is not possible to index outside
%          the array. If aIndex is an array, the output will also be an
%          array.
%
% Outputs:
% oElement - The element extracted from aArray.

index = mod(aIndex-1,length(aArray)) + 1;
if iscell(aArray)
    if length(index) == 1
        oElement = aArray{index};
    else
        oElement = aArray(index);
    end
else
    oElement = aArray(index);
end
end