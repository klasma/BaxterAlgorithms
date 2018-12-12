function ColorLineageTree(aCells)
% Colors cells by mapping a rainbow to the branches of their lineage tree.
%
% The cells are colored with colors taken from a rainbow. The hue is mapped
% to the y-values of the cells (the dimension of the lineage tree which is
% not time), and all cells get the maximum saturation and value in HSV
% color space.
%
% Inputs:
% aCells - Array of cells to be colored. The colors of the inputed Cell
%          objects are altered, so there is no need for an output argument.
%
% See also:
% Cell, ColorCells, Plot_LineageTree

% The function is recursive and to make sure that a deep lineage tree does
% not crash MATLAB, the recursion limit is increased.
set(0, 'RecursionLimit', 50000)

cells = AreCells(aCells);

% Find the y-values at which to plot the branches in the lineage tree.
Y2 = nan(size(cells));  % y-values where the branches end.
maxY = 0;  % Largest y-value currently assigned to a branch.
for i = 1:length(cells)
    if isnan(Y2(i))
        FindY(cells(i));
    end
end

% Color the cells.
for i = 1:length(cells)
    if ~strcmp(cells(i).coloring, 'manual')
        cells(i).color = hsv2rgb([Y2(i)/(maxY+1) 1 1]);
    end
end

    function oY = FindY(aCell)
        % Computes the y-coordinate at which to plot a lineage tree branch.
        %
        % The computed coordinate is both inserted into Y2 and returned.
        % The algorithm is recursive, so that the y-value of a parent cell
        % is set to the mean y-value of the two child cells.
        %
        % Inputs:
        % aCell - The cell for which to compute the y-value.
        %
        % Outputs:
        % oY - The y-value at which the branch ends.
        
        if isempty(aCell.children)
            % Leaf cells in the tree are given integer y-values from 1 to
            % the total leaf count.
            oY = maxY + 1;
            maxY = oY;
        elseif length(aCell.children) == 1
            % There is no branching, the single child gets the same y-value
            % as the parent cell.
            oY = FindY(aCell.children(1));
        else
            % Cell branches end in the middle of the two daughter
            % cells.
            oY = (FindY(aCell.children(1)) + FindY(aCell.children(2))) / 2;
        end
        Y2(cells == aCell) = oY;
    end
end