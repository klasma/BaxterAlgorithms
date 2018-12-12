function SurvivingCount(aCells, aFigure)
% Plots the number of cells that will be in the last frame, over time.
%
% In each frame, the function counts the number of cells that will be
% present in the last frame of the experiment. Cells that divide, die or
% disappear in some other way before the last frame are not counted. The
% cell count is normalized to percent of the starting population. Large
% values early in a long experiment may indicate that a significant number
% of cells have exited the cell cycle. The function PrintStyle is called to
% make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% LiveCount, DeadCount, DivisionCount, PlotGUI, PrintStyle

[numFrames, t] = TimeSpan(aCells);

% Group the cells by experimental condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

% Create axes to plot in.
ax = axes('Parent', aFigure);

maxValue = 0;  % Maximum y-value plotted (used to set limits).
for p = 1:length(pCellVec)
    % Count the total number of cells and the number of surviving cells.
    numberOfCells = zeros(numFrames, 1);
    numberOfSurviving = zeros(numFrames, 1);
    for i = 1:length(pCellVec{p})
        c = pCellVec{p}(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        % Increase the cell count.
        numberOfCells(ff:lf) = numberOfCells(ff:lf) + 1;
        if c.survived
            % Increase the surviving cell count.
            numberOfSurviving(ff:lf) = numberOfSurviving(ff:lf) + 1;
        end
    end
    
    % Normalize to 100 starting cells.
    numberOfSurviving = numberOfSurviving / numberOfCells(1) * 100;
    maxValue = max(maxValue, max(numberOfSurviving));
    
    plot(ax, t, numberOfSurviving)
    hold(ax, 'all')
end

xlim(ax, [t(1) t(end)])
ylim(ax, [0 1.1*max(maxValue,1)])

xlabel(ax, 'Time (hours)')
ylabel(ax, 'Normalized cell count')
legend(ax, pLabels, 'Location', 'northwest')

PrintStyle(ax)
end