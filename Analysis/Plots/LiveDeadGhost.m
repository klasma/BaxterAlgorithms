function LiveDeadGhost(aCells, aFigure, varargin)
% Plots the number of live cells, dead cells and ghost cells over time.
%
% This function can be used to analyze proliferation and death in a cell
% population, and to estimate the number of live cells that would have been
% present if no cells had died during the experiment. If no cells had died,
% the total cell count would be the live cells plus the dead cells, plus a
% number of "ghost cells" that the dead cells would have given rise to
% through mitosis if they had not died. Only one of the daughter cells in
% such a mitotic event is counted as a ghost cells, so that the number of
% dead cells does not decrease. The number of ghost cells are computed from
% the number of live and dead cells according to the following recursion:
%
% ghosts(t+1) = ghosts(t) + divisions(t) / live(t) * (dead(t) + ghosts(t)),
%
% where live(t), dead(t), and ghosts(t) are the number of cells in the
% different categories in frame t, and divisions(t) is the number of
% cell divisions in frame t. In the first frame ghosts(1) = 0.
%
% The function plots three curves for live(t), live(t)+dead(t), and
% live(t)+dead(t)+ghosts(t), and colors the regions below and between the
% curves in different colors. This makes it possible to see the composition
% of the estimated cell population in a culture with no death, at each time
% point of the experiment. The function creates a separate plot for each
% experimental condition.
%
% Inputs:
% aCells - Array with cells from all experimental conditions.
% aFigure - Figure to plot in.
%
% Property/Value inputs:
% GhostCells - If this parameter is set to false, the ghost cells are not
%              included in the plots.
%
% See also:
% PlotGUI

% Parse parameter/value inputs.
aGhostCells = GetArgs({'GhostCells'}, {true}, true, varargin);

% Plot live cells in green and dead cells in black.
colors = {[0 1 0]; [0 0 0]};
if aGhostCells
    colors = [colors; {[0.5 0.5 0.5]}];  % Plot ghost cells in gray.
end

% Sort the cells by condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

% Get information about the axes and their limits.
[numFrames, time] = TimeSpan(aCells);

% The cell count curves will be stored in the cells of this array.
sumY = cell(length(pCellVec),1);

legendStrings = cell(length(pCellVec),1);

for p = 1:length(pCellVec)
    counts_live = zeros(numFrames,1);
    counts_dead = zeros(numFrames,1);
    divisions = zeros(numFrames,1);
    
    % Count live and dead cells.
    for i = 1:length(pCellVec{p})
        c = pCellVec{p}(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        counts_live(ff:lf) = counts_live(ff:lf) + 1;
        if c.died
            counts_dead(lf+1:end) = counts_dead(lf+1:end) + 1;
        end
        if c.divided
            divisions(c.lastFrame) = divisions(c.lastFrame) + 1;
        end
    end
    
    y = [counts_live'; counts_dead'];
    
    if any(counts_live)
        legendStrings{p} = [legendStrings{p} {'Live cells'}];
    end
    if any(counts_dead)
        legendStrings{p} = [legendStrings{p} {'Dead cells'}];
    end
    
    % Compute the number of ghost cells in each frame.
    if aGhostCells
        counts_ghost = zeros(numFrames,1);
        for t = 1:numFrames-1
            counts_ghost(t+1) = counts_ghost(t) +...
                divisions(t) / counts_live(t) *...
                (counts_dead(t) + counts_ghost(t));
        end
        y = [y; counts_ghost']; %#ok<AGROW>
        
        if any(counts_ghost)
            legendStrings{p} = [legendStrings{p} {'Ghost cells'}];
        end
    end
    
    % Normalize to a starting population of 100 cells.
    y = y / counts_live(1) * 100;
    
    % Stack the different types of cells on top of each other.
    sumY{p} = cumsum(y,1);
end

% Maximum y-value to be plotted.
maxY = max(cellfun(@(x)max(x(:)), sumY));

% Create one plot for each condition.
for p = 1:length(pCellVec)
    ax = subplot(length(pCellVec),1,p,'Parent',aFigure);
    PlotFilled(time, sumY{p}, colors)
    xlim(ax, [time(1) time(end)])
    ylim(ax, [0 maxY])
    if ~isempty(legendStrings{p})
        legend(legendStrings{p}, 'Location', 'northwest')
    end
    xlabel('Time (hours)')
    ylabel('Normalized cell count')
    title(pLabels{p})
    PrintStyle(ax)
end
end