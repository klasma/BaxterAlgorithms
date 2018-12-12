function DeadCellRatio(aCells, aFigure)
% Plots the percentage of the cells that are dead as a function of time.
%
% The function counts the number of dead and live cells in each frame. The
% percentage of live cells is then computed as dead/(dead+live)*100. This
% percentage is plotted over time for the different experimental
% conditions.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% LiveDead, LiveDeadGhost, ProfilferationProfile, PlotGUI

% Partition the cells based on experimental condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

[numFrames, t] = TimeSpan(aCells);

% Number of live cells in each frame.
liveCount = zeros(length(pCellVec), numFrames);
% Number of dead cells in each frame.
deadCount = zeros(length(pCellVec), numFrames);

ax = axes('Parent', aFigure);

for i = 1:length(pCellVec)
    cells = pCellVec{i};
    for j = 1:length(cells)
        c = cells(j);
        ff = c.firstFrame;
        lf = c.lastFrame;
        % Increments the live count for all frames where a cell is alive.
        liveCount(i, ff:lf) = liveCount(i, ff:lf) + 1;
        if c.died
            % Increments the dead count for all frames after the death
            % event.
            deadCount(i, lf+1:end) = deadCount(i, lf+1:end) + 1;
        end
    end
    
    % Find the percentage of the cells that are dead in each frame.
    deadFraction = deadCount(i, :) ./...
        (liveCount(i, :) + deadCount(i, :)) * 100;
    
    plot(ax, t, deadFraction);
    hold(ax, 'all');
end

xlim(ax, [t(1) t(end)])

xlabel(ax, 'Time (hours)');
ylabel(ax, '% of cells that are dead');
legend(ax, pLabels, 'Location', 'NorthWest')

PrintStyle(ax)
end