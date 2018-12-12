function CellAge(aCells, aFigure)
% Plots the average cell age as a function of time.
%
% The age of a cell is defined as the time since the cell first appeared in
% the image sequence, and it is measured in hours. Each experimental
% condition is plotted in a different color. The function PrintStyle is
% called to make the plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% AgeHistogram, PlotGUI, PrintStyle

% Sort the cells by condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

[numFrames, t] = TimeSpan(aCells);

ax = axes('Parent', aFigure);
for p = 1:length(pCellVec)
    ageSum = zeros(numFrames,1);
    cellSum = zeros(numFrames,1);
    
    % Add the ages and count the cells.
    for i = 1:length(pCellVec{p})
        c = pCellVec{p}(i);
        ff = c.firstFrame;
        lf = c.lastFrame;
        cellSum(ff:lf) = cellSum(ff:lf) + 1;
        ageSum(ff:lf) = ageSum(ff:lf) + (0:c.lifeTime-1)';
    end
    
    % Compute the average age.
    avgAge = c.imageData.FramesToHours(ageSum ./ cellSum);
    
    plot(ax, t, avgAge)
    hold(ax, 'all')
end

xlim(ax, [t(1) t(end)])

legend(pLabels, 'Location', 'northwest')
xlabel('Time (hours)')
ylabel('Average cell age (hours)')

PrintStyle(ax)
end