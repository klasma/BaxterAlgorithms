function AgeHistogram(aCells, aFigure)
% Plots histograms for the ages of cells in the last frame.
%
% The age of a cell is defined as the time since the cell first appeared in
% the image sequence, and it is measured in hours. The bin size is one
% hour. A separate sub-plot is created for each experimental condition.
% The function PrintStyle is called to make the plotting style consistent
% with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
%
% See also:
% CellAge, PlotGUI, PrintStyle

% Group the cells by experimental condition.
[pCellVec, pLabels] = PartitionCells(aCells, 'condition');
numCond = length(pCellVec);

for p = 1:numCond
    % Find cells that make it to the last frame.
    cells = pCellVec{p};
    survivingCells = cells([cells.survived]);
    
    % Compute the ages of cells in the last frame.
    frameCounts = [survivingCells.lifeTime];
    ages = cells(1).imageData.FramesToHours(frameCounts);
    
    ax = subplot(numCond, 1, p, 'Parent', aFigure);
    
    % Plot a histogram over the cell ages. The bin size is one hour.
    maxAge = ceil(max(ages));
    ageGrid = 0:maxAge;
    histogram(ax, ages, ageGrid);
    
    title(ax, pLabels{p})
    xlabel(ax, 'Age (hours)')
    ylabel(ax, 'Number of cells')
    
    PrintStyle(ax)
end
end