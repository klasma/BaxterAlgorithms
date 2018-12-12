function oClones = SortClones(aClones)
% Sorts clones based on total cell life time in the highest generation.
%
% The clones are sorted in descending order on the total life time of cells
% in the highest generation. The life time is the total number of cell
% detections (blobs) from cells in the generation of interest. This means
% that a clone with a higher maximum generation will come first. If two
% clones have the same total life time in the highest generation, the clone
% with the highest number of cells in that generation comes first. If the
% number of cells is also the same, the cells in the second highest
% generation will be compared first on life time and then on count, and so
% forth. Make sure that cells where the isCell property is false have been
% removed before this function is called.
%
% Inputs:
% aClones - Cell array of clones. Each cell contains an array of cells in
%           the corresponding clone.
%
% Outputs:
% oClones - Cell array of sorted clones.
%
% See also:
% Cell, SortCells, ColorCells

% Compute the maximum cell generation across all clones.
allCells = [aClones{:}];
maxGen = max([allCells.generation]);

% Count the number of cells and the total life time in each generation, for
% all clones.
counts = zeros(length(aClones), maxGen);
time = zeros(length(aClones), maxGen);
for cloneIndex = 1:length(aClones)
    for cellIndex = 1:length(aClones{cloneIndex})
        c = aClones{cloneIndex}(cellIndex);
        gen = c.generation;
        counts(cloneIndex, gen) = counts(cloneIndex, gen) + 1;
        time(cloneIndex, gen) = time(cloneIndex, gen) + c.lifeTime;
    end
end

% Sort the clones multiple times, starting with the least important
% property. The order of elements with the same value will be preserved by
% the sort function. Therefore the order from the properties of lower
% priority will be preserved if the properties of higher priority have the
% same value.
order = 1:length(aClones);
for gIndex = 1:maxGen
    [~, tmp] = sort(counts(order, gIndex), 'descend');
    order = order(tmp);
    [~, tmp] = sort(time(order, gIndex), 'descend');
    order = order(tmp);
end
oClones = aClones(order);
end