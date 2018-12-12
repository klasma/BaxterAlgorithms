function MultiAxFig(aFig, aFun, aRows, aCols)
% Creates a grid of subplot axes and passes them to a plotting function.
%
% The function first deletes all of the existing graphics objects in the
% figure.
%
% Inputs:
% aFig - Figure object.
% aFun - Function handle which takes a cell array of axes objects and
%        creates plots in them.
% aRows - Number of rows in the grid of subplot axes.
% aCols - Number of columns in the grid of subplot axes.
%
% See also:
% SingleAxFig, PopulationAnalysisGUI, SaveFigure

delete(get(aFig, 'Children'));
ax = cell(aRows, aCols);
for i = 1:aRows
    for j = 1:aCols
        ax{i,j} = subplot(aRows, aCols, (i-1)*aCols+j, 'Parent', aFig);
    end
end
feval(aFun, ax)
end