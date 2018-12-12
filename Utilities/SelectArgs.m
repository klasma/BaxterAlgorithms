function [oSelected, oUnselected] = SelectArgs(aArguments, aSelection)
% Selects property/value arguments from a list of property/value arguments.
%
% The property names are not case sensitive.
%
% Inputs:
% aArguments - Cell array with the full list of property/value arguments
%              from which a subset will be selected. Odd indices in the
%              cell array are property names and even indices are the
%              corresponding values.
% aSelection - Character array with one property name or cell array with
%              multiple property names to be selected.
%
% Outputs:
% oSelected - Cell array with property/value arguments for the selected
%             properties.
% oUnselected - Cell array with property/value arguments for the remaining
%               properties that were not selected.
%
% See also:
% GetArgs

if mod(length(aArguments),2) ~= 0
    error('The arguments have to be in Property/Value pairs.')
end

oSelected = {};
oUnselected = {};
for i = 1:2:length(aArguments)
    if any(strcmpi(aSelection, aArguments(i)))
        oSelected = [oSelected aArguments(i) aArguments(i+1)]; %#ok<AGROW>
    else
        oUnselected = [oUnselected aArguments(i) aArguments(i+1)]; %#ok<AGROW>
    end
end
end