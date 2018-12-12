function LiveDead(aCells, aFigure, varargin)
% Draws bar graphs with live and dead cells for clones in the last frame.
%
% The function creates bar graphs where each clone has a bar. The total
% height of each bar is the total number of live and dead cells in the
% clone at the end of the experiment. The number of live cells is drawn as
% a white section of the bar and the number of dead cells is plotted as a
% black section on top of the white section. A separate plot is created for
% each experimental condition. A clone is the progeny of a cell which was
% present at the beginning of the experiment. The clones can be sorted on
% either the total number of cells or the number of live cells. The
% function PrintStyle is called to make the plotting style consistent with
% other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% Sort - If this parameter is set to 'live', the clones will be sorted in
%        descending order on the number of live cells. If this parameter is
%        set to 'total', the clones will be sorted in descending order on
%        the total number of cells. Clones that are tied on the selected
%        metric are ordered based on the other metric. The default value is
%        'total'.
%
% See also:
% CloneSize, CloneViability, FateProbabilityGeneration, PlotGUI, PrintStyle

% Parse property/value inputs.
aSort = GetArgs({'Sort'}, {'total'}, true, varargin);

[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'cloneParent');
numCond = length(pCellVec);

% Count the number of live and dead cells in each clone. Each cell in the
% cell arrays contains an array of counts for the corresponding
% experimental condition.
liveCountVec = cell(numCond,1);
deadCountVec = cell(numCond,1);
for p = 1:numCond
    numClones = length(pCellVec{p});
    liveCountVec{p} = zeros(numClones,1);
    deadCountVec{p} = zeros(numClones,1);
    for i = 1:length(pCellVec{p})
        cells = pCellVec{p}{i};
        liveCountVec{p}(i) = sum([cells.survived]);
        deadCountVec{p}(i) = sum([cells.died]);
    end
end

% Pre-compute the maximum y-value to be potted. This will be used to apply
% the same axis limits for all plots.
maxY = max(cat(1,liveCountVec{:}) + cat(1,deadCountVec{:}));

for p = 1:numCond
    ax = subplot(numCond, 1, p, 'Parent', aFigure);
    
    % Use a black and white color map for the bar graph.
    cmap = [1 1 1; 0 0 0];
    colormap(ax, cmap)
    
    % Concatenate the live and the dead counts so that they can be plotted
    % in a stacked bar graph.
    y = [liveCountVec{p} deadCountVec{p}];
    
    % Sort the clones in descending order based on the number of live cells
    % or the total number of cells. The variable sortValues defines the
    % metric that the clones will be sorted on.
    switch aSort
        case 'live'
            % If two clones are tied, the clone with the highest total cell
            % count (the most dead cells) is placed first.
            sortValues = liveCountVec{p} + 1E-6*deadCountVec{p};
        case 'total'
            % If two clones are tied, the clone with the most live cells is
            % placed first.
            sortValues = liveCountVec{p}' + deadCountVec{p}' +...
                1E-6*liveCountVec{p}';
        otherwise
            error('Unknown sort ''%s''', aSort)
    end
    [~, order] = sort(sortValues, 'ascend');
    y = y(order,:);
    
    % Plot the bar graph.
    bar(ax, y, 'stacked')
    
    ylim([0 maxY*1.1])
    
    xlabel(ax, 'Clone index')
    ylabel(ax, 'Cell count')
    title(ax, pLabels{1,p})
    
    legendStrings = {};
    if any(liveCountVec{p})
        legendStrings = [legendStrings {'live'}]; %#ok<AGROW>
    end
    if any(deadCountVec{p})
        legendStrings = [legendStrings {'dead'}]; %#ok<AGROW>
    end
    if ~isempty(legendStrings)
        legend(ax, legendStrings, 'Location', 'northwest')
    end
    
    % Create black borders around the white bars in the bar graphs.
    children = get(ax, 'children');
    for i = 1:length(children)
        set(children(i), 'EdgeColor', [0 0 0])
    end
    
    PrintStyle(ax)
end
end