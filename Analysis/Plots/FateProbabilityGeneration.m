function FateProbabilityGeneration(aCells, aFigure, varargin)
% Plots the fates of cells in different generations in bar graphs.
%
% The cells with different fates are counted in each generation. The
% different fates are division, death, and surviving to the end of the
% image sequence. The results are visualized using bar graphs where the
% bars for different fates are stacked on top of each other for each
% generation. A separate plot is made for each experimental condition. The
% cell counts can be normalized in different ways. One can also choose to
% exclude cells that divided from the bar graphs, so that only live and
% dead cells that can be seen at the end of the experiment are visualized.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% LiveOrDead - If this is set to true, the cells that divided are excluded
%              from the bar graphs. The plot is then made in black and
%              white to match the colors in LiveDead. The default is false.
% Normalization - This parameter specifies how the cell counts should be
%                 normalized. With 'none', the raw cell counts are plotted,
%                 with 'start', the cell counts are normalized to starting
%                 populations of 100 cells, and with 'percentage', the
%                 cells in each frame are normalized so that they sum to
%                 100 %. The default is 'none'.
% Print - When this is true, the counts and fractions for different fates
%         in different generations are printed to the command line. The
%         default is true.
%
% See also:
% PlotGUI, LiveDead, GenerationDistribution

% Parse property/value inputs.
[aLiveOrDead, aNormalization, aPrint] = GetArgs(...
    {'LiveOrDead', 'Normalization', 'Print'},...
    {false, 'none', true},...
    true, varargin);

[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'generation');
numCond = length(pCellVec);  % Number of experimental conditions.
maxGen = max([aCells.generation]);  % Highest cell generation.

% Each cell has data from the corresponding experimental condition.
cellCount = cell(numCond,1);   % Cells in each generation.
deathCount = cell(numCond,1);  % Dead cells from each generation.
splitCount = cell(numCond,1);  % Cells that divided in each generation.
aliveCount = cell(numCond,1);  % Cells present in the last image from each generation.
% Histogram where column 1 has dividing cells, column 2 has cells present
% in the last image, and column 3 has dead cells. The values are normalized
% with the user specified normalization, so that the histograms can be
% given as input to bar.
countHist = cell(numCond,1);

for p = 1:numCond
    % The highest cell generation in this experimental condition.
    numGen = length(pCellVec{p});
    
    % Allocate arrays for this experimental condition.
    cellCount{p} = zeros(numGen,1);
    deathCount{p} = zeros(numGen,1);
    splitCount{p} = zeros(numGen,1);
    aliveCount{p} = zeros(numGen,1);
    countHist{p} = nan(numGen,3);
    
    % Count cells in each generation.
    for g = 1:numGen
        for i = 1:length(pCellVec{p}{g})
            c = pCellVec{p}{g}(i);
            cellCount{p}(g) = cellCount{p}(g) + 1;
            splitCount{p}(g) = splitCount{p}(g) + c.divided;
            deathCount{p}(g) = deathCount{p}(g) + c.died;
            aliveCount{p}(g) = aliveCount{p}(g) + c.survived;
        end
        countHist{p}(g,1) = splitCount{p}(g);
        countHist{p}(g,2) = aliveCount{p}(g);
        countHist{p}(g,3) = deathCount{p}(g);
        
        % Normalize the histogram.
        switch lower(aNormalization)
            case 'none'
                % Use the raw counts.
            case 'start'
                % Normalize to a starting population of 100 cells.
                countHist{p}(g,:) = countHist{p}(g,:) / cellCount{p}(1) * 100;
            case 'percentage'
                % Look at percentages of cells in each generation.
                countHist{p}(g,:) = countHist{p}(g,:) / cellCount{p}(g) * 100;
        end
    end
end

for p = 1:length(pCellVec)
    ax = subplot(length(pCellVec), 1, p, 'Parent', aFigure);
    
    % Plot the histogram.
    if aLiveOrDead
        % Black and white histogram with live and dead cells only.
        cmap = [1 1 1; 0 0 0];
        colormap(ax, cmap)
        bar(ax, countHist{p}(:,2:end), 'stack', 'LineWidth', 2)
    else
        % Histogram with all fates using built in colors.
        bar(ax, countHist{p}, 'stack')
    end
    
    % X-axis
    xlim(ax, [0.5 maxGen+0.5])
    xlabel(ax, 'Generation')
    
    % Y-axis
    switch lower(aNormalization)
        case 'none'
            ylabel('Cell count')
            ylim(ax, [0 max(cellCount{p})*1.05])
        case 'start'
            ylabel(ax, 'Normalized cell count')
            ylim(ax, [0 max(cellCount{p}/cellCount{p}(1)*100)*1.05])
        case 'percentage'
            ylabel(ax, 'Percentage of cells')
            ylim(ax, [0 100])
    end
    
    title(ax, pLabels{1,p})
    
    if aLiveOrDead
        legend('live', 'dead', 'Location', 'NorthEastOutside')
    else
        legend(ax, 'dividing', 'non-dividing', 'dead',...
            'Location', 'NorthEastOutside')
    end
    
    PrintStyle(ax)
end

if aPrint
    % Print the number of cells with different fates in all generations.
    fprintf('\n')
    for p = 1:numCond
        numGen = length(pCellVec{p});
        fprintf('Cell fates for %s in counts\n', pLabels{1,p})
        fprintf('%26s  %8s  %8s  %8s\n', 'divided', 'survived', 'died', 'total')
        for g = 1:numGen
            fprintf('generation %4d : %8d  %8d  %8d  %8d\n',...
                g,...
                splitCount{p}(g),...
                aliveCount{p}(g),...
                deathCount{p}(g),...
                cellCount{p}(g))
        end
        fprintf('all generations : %8d  %8d  %8d  %8d\n\n',...
            sum(splitCount{p}),...
            sum(aliveCount{p}),...
            sum(deathCount{p}),...
            sum(cellCount{p}))
    end
    
    % Print the fraction of cells with different fates in all generations.
    for p = 1:length(pCellVec)
        fprintf('Cell fates for %s in fractions\n', pLabels{1,p})
        fprintf('%26s  %8s  %8s\n', 'divided', 'survived', 'died')
        for g = 1:length(pCellVec{p})
            fprintf('generation %4d : %.6f  %.6f  %.6f\n',...
                g,...
                splitCount{p}(g)/cellCount{p}(g),...
                aliveCount{p}(g)/cellCount{p}(g),...
                deathCount{p}(g)/cellCount{p}(g))
        end
        fprintf('all generations : %.6f  %.6f  %.6f\n\n',...
            sum(splitCount{p})/sum(cellCount{p}),...
            sum(aliveCount{p})/sum(cellCount{p}),...
            sum(deathCount{p})/sum(cellCount{p}))
    end
end
end