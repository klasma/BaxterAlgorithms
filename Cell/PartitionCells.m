function [oCellVec, oLabels] = PartitionCells(aCells, varargin)
% Partitions cells into groups based on one or more properties.
%
% If the cells are partitioned based on multiple properties, the
% partitioning will be hierarchical. The hierarchical partitioning is done
% recursively. The groups will be sorted if the property values (group
% labels) are strings or numbers.
%
% Inputs:
% aCells - Array of cells that will be partitioned.
% varargin - Names of properties that the cells will be partitioned on. If
%            multiple properties are specified, the cells will first be
%            partitioned on the first property. Then the cells in each
%            group will be partitioned on the second property, and so
%            forth. The properties have to be properties of the Cell class.
%
% Outputs:
% oCellVec - Cell array with groups of cells. If the cells have been
%            partitioned on a single property, each element of oCellVec
%            will contain an array of cells with a given property value. If
%            the cells have been partitioned on multiple properties, the
%            cell array will be nested hierarchically. For example, if two
%            properties have been used for partitioning, oCellVec{1}{2}
%            will contain an array of cells which have the first value on
%            the first property and the second value on the second
%            property.
% oLabels - Cell array with property values corresponding to the cell
%           groups. The cell group which corresponds to the values i, j,
%           and k on 3 properties will have the value oLabels{1,i} on the
%           first property, oLabels{2,i}{j} on the second property, and
%           oLabels{3,i}{j}{k} on the third property. The first index in
%           the two-dimensional cell array is the hierarchical level of the
%           property, but after that, the indexing is the same as in
%           oCellVec. This structure was chosen to allow indexing with a
%           single index when the cells are partitioned using a single
%           property.
%
% See also:
% Cell, LoadCells

% Partition on the first property.
[oCellVec, oLabels] = PartitionCellsOnce(aCells, varargin{1});

% Partition recursively on the remaining properties.
if length(varargin) > 1
    for i = 1:length(oCellVec)
        [oCellVec{i}, labels] = PartitionCells(oCellVec{i}, varargin{2:end});
        
        % Re-structure the labels to move up one hierarchical level.
        for  j = 1:size(labels,1)
            oLabels(j+1,i) = {labels(j,:)};
        end
    end
end
end

function [oCellVec, oLabels] = PartitionCellsOnce(aCells, aProperty)
% Partitions cells on a single property.
%
% The cell partitions will be sorted if the property has values that are
% strings or numbers.
%
% Inputs:
% aCells - Array of cells to partition.
% aParameter - Name of the property to partition on. The property has to be
%              a property of the Cell class.
%
% Outputs:
% oCellVec - Cell array where each cell contains an array of cells with the
%            same property value.
% oLabels - Cell array with property values that correspond to the cells in
%           oCellVec.

% Go through the cells one at a time and place them in a group. Create the
% groups if they do not already exist.
oCellVec = {};
oLabels = {};
for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    group = c.(aProperty);
    gIndex = find(cellfun(@(x)isequal(x, group), oLabels));
    if isempty(gIndex)
        % Create a new group.
        oLabels = [oLabels {group}]; %#ok<AGROW>
        oCellVec = [oCellVec {c}]; %#ok<AGROW>
    else
        % Place the cell in an existing group.
        oCellVec{gIndex} = [oCellVec{gIndex} c]; %#ok<AGROW>
    end
end

% Sort the groups if the labels are are strings or numbers.
if all(cellfun(@ischar, oLabels))
    % Sort strings.
    [oLabels, order] = sort(oLabels);
    oCellVec = oCellVec(order);
elseif all(cellfun(@isnumeric, oLabels))
    % Sort numbers.
    [~, order] = sort(cell2mat(oLabels));
    oCellVec = oCellVec(order);
    oLabels = oLabels(order);
end
end