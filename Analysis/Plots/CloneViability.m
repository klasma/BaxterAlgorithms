function CloneViability(aCells, aFigure, varargin)
% Plots the clone viability in an experiment as a function of time.
%
% The clone viability is defined as the fraction of the branches in a
% lineage tree which are still alive. All branches are not weighted
% equally. Assume that the cell with the highest generation number at the
% end of the experiment is in generation G. (The first cell is generation
% 1, its offspring is generation 2, and so forth.) Further assume that all
% cells in generations lower than G go through divisions without cell
% death, until all cells are in generation G. Then, the clone viability is
% the number of live branches in that lineage tree, divided by the maximum
% number of cells in a lineage tree with cells in generation G. This means
% that death events in generations 1, 2, 3, 4... reduce the viability by 1,
% 1/2, 1/4, 1/8...
%
% A histogram of the clone viabilities is created for each time point. Each
% bin in the histogram corresponds to a death event in the highest
% generation with death, or a death event in generation MaxGen if there are
% death events in generations above generation MaxGen. When the histograms
% have been computed, the distribution between the different bins is
% plotted over time. The clone fractions are added cumulatively, so that
% the curve for viability v is the fraction of the clones which have
% viability v or a lower viability. The area under the first curve and the
% areas between the curves are colored in different colors, which represent
% the different viabilities. In the color map, red represents viability 0,
% yellow represents viability 1/2, and green represents viability 1. The
% function PrintStyle is called to make the plotting style consistent with
% other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% PlotDeath - When this is true, death events are plotted as circles on the
%             x-coordinate corresponding to the time of death and the
%             y-coordinate corresponding to the viability of the clone in
%             which the death event occurred. The default is true.
% aMaxGen - The cell generation corresponding to the minimum step between
%           two viability levels. If a cell in this generation dies, the
%           viability will go down by one level, even if there are cells in
%           higher generations. In this case, there will be 2^(aMaxGen-1)
%           viability levels. If the maximum cell generation in the
%           experiment is lower than aMaxGen, the step between two
%           viability levels will correspond to a death event in the
%           highest generation where there are death events. The default
%           value is 9.
%
% See also:
% CloneSize, GenerationDistribution, DeadCellRatio, LiveDead, PlotGUI,
% PrintStyle

% Parse property/value inputs.
[aPlotDeath, aMaxGen] =...
    GetArgs({'PlotDeath', 'MaxGen'}, {true, 9}, true, varargin);

[pCellVec, pLabels] = PartitionCells(aCells, 'condition', 'cloneParent');
numCond = length(pCellVec);

[numFrames, t] = TimeSpan(aCells);

% Cell arrays with one cell per experimental condition.

% Histograms over different viability levels.
aliveHistVec = cell(numCond,1);
% Frames of death events in clones with the different viability levels.
deathFrameVec = cell(numCond,1);
% Generations of cells that died in clones with the different viability
% levels.
deathGenerationVec = cell(numCond,1);

% Gather data.
for i = 1:numCond
    % Find the maximum generation of cells that died.
    pCells = [pCellVec{i}{:}];
    if any([pCells.died])
        maxGen = max([pCells([pCells.died]).generation]);
    else
        maxGen = 1;
    end
    
    % Matrix where each row is a time series with the fraction of the
    % branches in the lineage tree that are alive. The matrix has one
    % column for each time point.
    aliveFractions = ones(length(pCellVec{i}), numFrames);
    % Cell array with indices of frames in which cells died. There is one
    % cell for each viability level, and each cell contains the frames in
    % which death events occurred in clones with that viability level.
    deathFrames = cell(2^(maxGen-1)+1,1);
    % Cell array with the generations of cells that died. The cell array
    % has the same structure as deathFrames.
    deathGenerations = cell(2^(maxGen-1)+1,1);
    
    for cloneIndex = 1:length(pCellVec{i})
        aCells = pCellVec{i}{cloneIndex};
        
        % Start processing the cells that die first, so that the clone
        % viability for earlier frames is accurate when a new cell is
        % processed.
        [~, order] = sort([aCells.lastFrame]);
        aCells = aCells(order);
        
        for cellIndex = 1:1:length(aCells)
            c = aCells(cellIndex);
            if c.died
                lf = c.lastFrame;
                % The viability of the clone before the death event.
                viability = aliveFractions(cloneIndex, lf) / 0.5^(maxGen-1) + 1;
                
                % Update the clone viability for frames after the death
                % event.
                aliveFractions(cloneIndex, lf+1:end) =...
                    aliveFractions(cloneIndex, lf+1:end) - 0.5^(c.generation-1);
                
                % Store the last frame and the generation of the dead cell.
                deathFrames{viability} = [deathFrames{viability} lf];
                deathGenerations{viability} =...
                    [deathGenerations{viability} c.generation];
            end
        end
    end
    
    % Compute a histogram over the different viability levels.
    aliveHist = histc(aliveFractions, 0:0.5^min(maxGen-1,aMaxGen-1):1, 1);
    aliveHistVec{i} = aliveHist;
    
    deathFrameVec{i} = flipud(deathFrames);
    deathGenerationVec{i} = flipud(deathGenerations);
end

% Plot the data.
for i = 1:numCond
    ax = subplot(numCond, 1, i, 'Parent', aFigure);
    
    % Find the maximum generation of cells that died.
    pCells = [pCellVec{i}{:}];
    if any([pCells.died])
        maxGen = max([pCells([pCells.died]).generation]);
    else
        maxGen = 1;
    end
    
    % Create colors for clones with different viabilities using a color map
    % which goes from green for clones with no dead cells to red for clones
    % with no live cells.
    colors = GreenToRed(2^(min(maxGen-1,aMaxGen-1))+1);
    colors = mat2cell(colors, ones(size(colors,1),1), 3);
    % Use the same color map in the figure, so that a color bar for the
    % different viabilities can be created using the colorbar function.
    colormap(aFigure, flipud(GreenToRed(2^(min(maxGen-1,aMaxGen-1))+1)))
    
    % Accumulate the fractions in the different viability bins, so that it
    % looks like they are stacked on top of each other when they are
    % plotted.
    sumY = cumsum(flipud(aliveHistVec{i}),1);
    sumY = sumY./repmat(sumY(end,:), size(sumY,1), 1);
    
    if aPlotDeath
        % Create strings for the legend. The legend contains information
        % about the circles that represent death events in different
        % generations. Invisible circles are plotted in the origin, so that
        % the correct circles are added to the legend no matter which
        % circles will be present in the final plot.
        hold(ax, 'on')
        legendStrings = cell(min(maxGen,aMaxGen), 1);
        for gIndex = 1:min(maxGen,aMaxGen)
            plot(nan, nan, 'ko',...
                'MarkerSize', 32/(sqrt(2).^(gIndex-1)))
            if maxGen > aMaxGen && gIndex == aMaxGen
                legendStrings{gIndex} = sprintf('death in gen. >=%d', gIndex);
            else
                legendStrings{gIndex} = sprintf('death in gen. %d', gIndex);
            end
        end
    end
    
    % Plot the clone viabilities over time.
    PlotFilled(t, sumY, colors)
    hold(ax, 'on')
    
    if aPlotDeath
        % Plot circles of different sizes which represent death events in
        % different generations.
        for dIndex = 1:length(deathFrameVec{i})
            gen = deathGenerationVec{i}{dIndex};
            x = deathFrameVec{i}{dIndex};
            y = sumY(ceil(dIndex/2^(max(0,maxGen-aMaxGen))),x);
            x = c.imageData.FrameToT(x);
            for ddIndex = 1:length(x)
                plot(x(ddIndex), y(ddIndex), 'ko',...
                    'MarkerSize', 32/(sqrt(2).^(min(gen(ddIndex)-1,aMaxGen-1))))
            end
        end
    end
    
    xlim(ax, [t(1) t(end)])
    ylim(ax, [0 1])
    
    % Create a color bar for the different viabilities.
    cBar = colorbar(ax);
    title(cBar, 'clone viability')
    
    if aPlotDeath
        % Create a legend for the death events.
        legend(ax, legendStrings, 'Location', 'NorthEastOutside')
    end
    
    title(ax, pLabels{1,i})
    ylabel(ax, 'Fraction')
    xlabel(ax, 'Time (hours)')
    
    % Use outward pointing ticks so that the ticks do not obscure the plot.
    set(ax, 'TickDir', 'out')
    
    PrintStyle(ax)
end
end