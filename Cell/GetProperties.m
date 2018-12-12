function oProp = GetProperties(aCells, aProperty, aT)
% Returns an array of properties for an array of Cell objects.
%
% The function is simply a wrapper for the class method GetProperty of the
% Cell class. If the cell is not present at the desired time points, or if
% the desired property is not available, there will be an error.
%
% Inputs:
% aCells - Array of Cell objects, with arbitrary dimensions.
% aProperty - The name of the desired property.
% aT - The time point for which the property will be extracted. If this
%      input is omitted, a default value of 1 will be used.
%
% Outputs:
% oProp - An array with the same size as aCells, containing the desired
%         property.
%
% See also:
% Cell

if nargin == 2
    aT = 1;
end
oProp = arrayfun(@(x)x.GetProperty(aProperty, aT), aCells);
end