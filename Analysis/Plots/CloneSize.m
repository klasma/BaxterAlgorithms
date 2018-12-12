function CloneSize(aCells, aFigure)
% Plots clone sizes as a function of time.
%
% A histogram of the clone sizes is created for each time point. The upper
% limits of the histogram bins correspond to the number of cells in each
% generation of a lineage tree. This means that the bins contain clones
% with 1, 2, 3-4, 5-8, 9-16,... cells. When the histograms have been
% computed, the distribution between the different bins is plotted over
% time. The fraction of the clones which have a single cell is plotted as
% the first curve. Then the clone fractions are added cumulatively, so that
% the second curve is the fraction of the clones which have 1-2 cells, the
% third curve is the fraction of the clones which have 1-3 cells, and so
% forth. The area under the first curve and the areas between the curves
% are colored in different colors, which represent the different clone
% sizes. Clones without cells are not plotted, but the fraction of the
% clones with zero cells is equal to 1 minus the value of the highest
% curve. The function PrintStyle is called to make the plotting style
% consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% CloneViability, GenerationDistribution, PlotGUI, PrintStyle

% Partition the cells into conditions and clones.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'cloneParent');
numCond = size(pLabels,2);

[numFrames, t] = TimeSpan(aCells);

% Count the number of cells in each clone at each time point.
countVec = cell(numCond,1);
for i = 1:numCond
    counts = zeros(length(pCellVec{i}), numFrames);
    for cloneIndex = 1:length(pCellVec{i})
        for cellIndex = 1:length(pCellVec{i}{cloneIndex})
            c = pCellVec{i}{cloneIndex}(cellIndex);
            ff = c.firstFrame;
            lf = c.lastFrame;
            counts(cloneIndex, ff:lf) = counts(cloneIndex, ff:lf) + 1;
        end
    end
    countVec{i} = counts;
end

% Lower limits of the clone size bins.
intervals = [1 2.^(0:16)+1];

% Count the number of clones in each size bin.
maxBin = 0;  % Index of the highest size bin used.
countHists = cell(numCond,1);
for i = 1:numCond
    histogram = histc(countVec{i}, intervals, 1) / size(countVec{i},1);
    mBin = find(sum(histogram, 2) ~= 0, 1, 'last');
    countHists{i} = histogram(1:mBin,:);
    maxBin = max(maxBin, mBin);
end

% Create legend strings with the size bin intervals.
intervals = intervals(1:maxBin+1);
legendStrings = cell(numCond,1);
for i = 1:length(intervals)-1
    lower = intervals(i);
    upper = intervals(i+1)-1;
    if upper == lower
        legendStrings{i} = sprintf('%d', lower);
    else
        legendStrings{i} = sprintf('%d-%d', lower, upper);
    end
end

% Colors that will be used to plot the different size bins. The colors are
% taken from the default color order. If there are more bins than colors,
% the colors are recycled.
colors = get(0, 'DefaultAxesColorOrder');
colors = mat2cell(colors, ones(size(colors,1),1), 3);
indices = mod((1:maxBin)'-1,length(colors)) + 1;
colors = colors(indices);

for i = 1:numCond
    ax = subplot(numCond, 1, i, 'Parent', aFigure);
    sumY = cumsum(countHists{i},1);
    
    PlotFilled(t, sumY, colors(1:size(sumY,1)), 'Parent', ax)
    hold(ax, 'on')
    
    legend(ax, legendStrings(1:size(sumY,1)),...
        'Location', 'NorthEastOutside')
    xlim(ax, [t(1) t(end)])
    ylim(ax, [0 1])
    ylabel(ax, 'Fraction')
    xlabel(ax, 'Time (hours)')
    title(ax, pLabels{1,i})
    
    PrintStyle(ax)
end
end