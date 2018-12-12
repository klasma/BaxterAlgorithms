function LiveCount(aCells, aFigure)
% Plots the number of live cells as a function of time.
%
% One curve is created for each experimental condition. The counts are
% normalized to starting populations of 100 cells. The function PrintStyle
% is called to make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% DeadCount, DivisionCount, SurvivingCount, PlotGUI, PrintStyle

[numFrames, t] = TimeSpan(aCells);

% Group the cells by experimental condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

% Create axes to plot in.
ax = axes('Parent', aFigure);

maxValue = 0;  % Maximum y-value plotted (used to set limits).
for p = 1:length(pCellVec)
    % Count the number of cells.
    numberOfCells = zeros(numFrames, 1);
    for i = 1:length(pCellVec{p})
        c = pCellVec{p}(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        % Increase the cell count.
        numberOfCells(ff:lf) = numberOfCells(ff:lf) + 1;
    end
    
    % Normalize to 100 starting cells.
    numberOfCells = numberOfCells / numberOfCells(1) * 100;
    maxValue = max(maxValue, max(numberOfCells));
    
    plot(ax, t, numberOfCells)
    hold(ax, 'all')
end

xlim(ax, [t(1) t(end)])
ylim(ax, [0 1.1*max(maxValue,1)])

xlabel(ax, 'Time (hours)')
ylabel(ax, 'Normalized cell count')
legend(ax, pLabels, 'Location', 'northwest')

PrintStyle(ax)
end