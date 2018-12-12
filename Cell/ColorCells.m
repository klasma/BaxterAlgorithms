function oCells = ColorCells(aCells, varargin)
% Colors an array of cells.
%
% The cells are colored using one of the available coloring schemes.  The
% function changes the coloring property of all cells unless their coloring
% property is set to 'manual'. The colors of such manually colored cells
% are not altered by this function. False positives are always given the
% color black.
%
% If the coloring scheme is set to 'Rainbow', the cells are also sorted
% using the function SortCells, as the color of a cell depends on its
% position in the lineage tree. Sorting is not done for coloring schemes
% other than 'Rainbow', to save time during manual correction.
%
% Inputs:
% aCells - Array of Cell objects.
%
% Property/Value inputs:
% Coloring - The name of the coloring scheme that should be used to color
%            the cells. The following options are available:
%            'Random Colors' - Assigns 6 different fixed colors to the
%                              cells. The function cycles over the colors,
%                              but if the the mother cell or the sister
%                              cell has the same color, the color is saved
%                              for later, so that the mother cell and the
%                              two daughter cells always have different
%                              colors.
%            'Rainbow' - The hue of the cells are determined by he
%                        horizontal positions of the cells in the plotted
%                        lineage tree (the time axis is vertical). The
%                        saturation and the value are both set to 1. The
%                        leaves of the lineage tree are spaced evenly, even
%                        if they are not from the same generation.
%            'Random Hues' - Picks random colors with saturations and
%                            values equal to 1. The colors are not changed
%                            if the function is called multiple times,
%                            unless the 'coloring' property of a cell is
%                            changed to something other than 'randomhues'.
%
% Outputs:
% oCells - Array where the cells from aCells have been recolored.
%
% See also:
% SortCell, Cell

aColoring = GetArgs({'Coloring'}, {'Rainbow'}, true, varargin);

if strcmp(aColoring, 'Rainbow')
    oCells = SortCells(aCells);
else
    oCells = aCells;
end

% Color the true cells.
areCells = AreCells(oCells);
if ~isempty(areCells)
    switch aColoring
        case 'Random Colors'
            
            % Color map with the 6 available colors. The last color is
            % orange instead of yellow, as yellow is hard to see.
            colors = [...
                0 0 1
                0 1 0
                1 0 0
                0 1 1
                1 0 1
                1 0.65 0];
            
            % Set all the colors to black at first so that cells which
            % don't have a color yet don't interfere with the coloring.
            for i = 1:length(areCells)
                areCells(i).color = zeros(1,3);
            end
            
            for i = 1:length(areCells)
                c = areCells(i);
                cnt = 1;
                while true
                    if isempty(c.parent) ||...
                            (~all(c.parent.color == colors(cnt,:)) &&...
                            ~all(c.parent.OtherChild(c).color == colors(cnt,:)))
                        
                        c.color = colors(cnt,:);
                        
                        % Remove the used color and put it at the end.
                        colors = [colors; colors(cnt,:)]; %#ok<AGROW>
                        colors(cnt,:) = [];
                        
                        break
                    else
                        cnt = cnt+1;
                    end
                end
            end
        case 'Rainbow'
            ColorLineageTree(areCells)
        case 'Random Hues'
            for i = 1:length(areCells)
                c = areCells(i);
                % Manually colored cells and cells that have been colored
                % by 'Random Hues' previously are not re-colored. Black
                % cells which were previously false positive cells are
                % recolored though.
                if ~strcmp(c.coloring, 'manual') &&...
                        (~strcmp(c.coloring, 'Random Hues') || all(c.color == 0))
                    c.color = hsv2rgb([rand() 1 1]);
                end
            end
        case 'Lifetimes'
            for i = 1:length(areCells)
                c = areCells(i);
                if c.lifeTime < 165 && ~isempty(c.parent) && ~isempty(c.children)
                    c.color = [1 0 0];
                elseif c.lifeTime >= 350
                    c.color = [0 0 1];
                else
                    c.color = [0 0 0];
                end
            end
        otherwise
            error('Unknown coloring ''%s''.\n', aColoring)
    end
end

% Change the coloring property of all cells not colored manually.
for i = 1:length(oCells)
    if ~strcmp(oCells(i).coloring, 'manual')
        oCells(i).coloring = aColoring;
    end
end
end