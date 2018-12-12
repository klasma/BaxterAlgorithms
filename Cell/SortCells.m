function oCells = SortCells(aCells)
% Sorts an array of cells.
%
% The cells are sorted by their first frame, in increasing
% order. If multiple cells have the same first frame, they are sorted by
% their life time in decreasing order. If that is also not enough to order
% the cells, they are sorted by their x-coordinate in decreasing order.
% Finally, ties are broken randomly. Daughter cells are ordered so that the
% daughter cell with the longest surviving progeny comes first. If the
% progeny survives for the same number of frames, the daughter cell with
% the longest life time comes first. False positives are put at the end of
% the array.
%
% Inputs:
% aCells - Array of Cell objects.
%
% Outputs:
% oCells - Array where the cells from aCells have been reordered.
%
% See also:
% ColorCells, Cell


% Add the 3 different sorting variables together and give higher weight to
% the more important one. There are 6 orders of magnitude between the
% weights, so that the more important variables take precedence over the
% less important ones for all possible values of the variables. Also
% reorders daughter cell pairs.
sortFunc = zeros(length(aCells), 1);
for i = 1:length(aCells);
    if aCells(i).isCell
        sortFunc(i) = aCells(i).firstFrame*1E12 -...
            aCells(i).lifeTime*1E6 - mean(aCells(i).cx);
        ch = aCells(i).children;
        if length(ch) > 1
            lastFrames = [ch.lastFrame];
            maxSubFrames = [ch.maxSubFrame];
            
            % Reorder daughter cell pairs.
            if maxSubFrames(1) < maxSubFrames(2) ||...
                    (maxSubFrames(1) == maxSubFrames(2) &&...
                    lastFrames(1) < lastFrames(2))
                aCells(i).children = [ch(2) ch(1)];
            end
        end
    else
        sortFunc(i) = inf;
    end
end

% Order the cells.
[~, order] = sort(sortFunc);
oCells = aCells(order);
end