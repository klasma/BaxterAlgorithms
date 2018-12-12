function oProperties = ExtractProperty(aCells, aProperty, varargin)
% Extracts cell properties from an array of Cells objects.
%
% The property can either be a property of the cell class, or a
% fluorescence property. The names of fluorescence properties follow the
% format Fluor<Max|Avg|Tot><channel name>. For fluorescence properties, the
% average value across all blobs of the cell is returned. Total
% fluorescence features are given in intensity times area in square
% microns.
%
% Inputs:
% aCells - Array of cell objects.
% aProperty - The name of the property.
%
% Property/Value inputs:
% UniformOutput - If this is set to false, the properties will be returned
%                 in a cell array instead of in a normal array. This makes
%                 it possible to detect empty values, which are removed if
%                 the values are concatenated into a normal array. The
%                 default value is true.
%
% Outputs:
% oProperties - Array with property values, or cell array with property
%               values if UniformOutput is set to false.
%
% See also:
% GetProperties

% Parse property/value inputs.
aUniformOutput = GetArgs({'UniformOutput'}, {true}, true, varargin);

if isempty(regexp(aProperty, '^Fluor.*', 'once'))
    % Not a fluorescence property.
    if aUniformOutput
        oProperties = [aCells.(aProperty)];
    else
        oProperties = {aCells.(aProperty)};
    end
else
    % Fluorescence property.
    oProperties = arrayfun(@(x)x.GetFluorProperty(aProperty), aCells,...
        'UniformOutput', aUniformOutput);
end
end