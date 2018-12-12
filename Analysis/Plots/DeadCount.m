function DeadCount(aCells, aFigure)
% Plots the number of dead cells as a function of time.
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
% LiveCount, DivisionCount, SurvivingCount, PlotGUI, PrintStyle

[numFrames, t] = TimeSpan(aCells);

% Group the cells by experimental condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

% Create axes to plot in.
ax = axes('Parent', aFigure);

maxValue = 0;  % Maximum y-value plotted (used to set limits).
for p = 1:length(pCellVec)
    % Count the number of dead and live cells. The number of live cells is
    % used for normalization.
    numberOfCells = zeros(numFrames, 1);
    numberOfDeadCells = zeros(numFrames, 1);
    for i = 1:length(pCellVec{p})
        c = pCellVec{p}(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        % Increase the live cell count.
        numberOfCells(ff:lf) = numberOfCells(ff:lf) + 1;
        if c.died
            % Increase the dead cell count.
            numberOfDeadCells(lf+1:end) = numberOfDeadCells(lf+1:end) + 1;
        end
    end
    
    % Normalize to 100 starting cells.
    numberOfDeadCells = numberOfDeadCells / numberOfCells(1) * 100;
    maxValue = max(maxValue, max(numberOfDeadCells));
    
    plot(ax, t, numberOfDeadCells)
    hold(ax, 'all')
end

xlim(ax, [t(1) t(end)])
ylim(ax, [0 1.1*max(maxValue,1)])

xlabel(ax, 'Time (hours)')
ylabel(ax, 'Normalized number of dead cells')
legend(ax, pLabels, 'Location', 'northwest')

PrintStyle(ax)
end