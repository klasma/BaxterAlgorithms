function Plot_LineageTree(aCells, aAxes, varargin)
% Plots the lineage trees associated with an array of cells.
%
% Separate clones are plotted next to each other. The leaf nodes of the
% tree are equally spaced at integer values from 1 to the total leaf node
% count. By default, the branches in the tree are plotted in the colors of
% the cells.
%
% Inputs:
% aCells - Array of cells.
% aAxes - Axes object to plot the tree in.
%
% Property/Value inputs:
% XUnit - The unit to be used on the x-axis. ['hours'] or 'frames'.
% Vertical - Plots the tree vertically from the top of the axes to the
%            bottom. In this case the axes are rotated so that the x-axis
%            points downward and the y-axis points to the right. true or
%            [false].
% Black - Plots all the branches in black, for overview plots. true or
%         [false].
% MaxIteration - Plots a lineage tree where the cell fragments that were
%                added in iteration MaxIteration are plotted in red and all
%                other cell fragments are plotted in blue. If MaxIteration
%                is set to NaN or is omitted, the normal cell tree is
%                plotted. This input is used to visualized intermediate
%                tracking results during track linking, for debug purposes.
% StyleFunction - Function handle to a function which takes the axes
%                 object as input and changes the plot style by altering
%                 line thicknesses, font sizes, and other parameters.
%
% See also
% PlotTrajectories, Cell, ManualCorrectionPlayer

% Parse property/value inputs.
[aXUnit, aVertical, aBlack, aMaxIteration, aStyleFunction] = GetArgs(...
    {'XUnit', 'Vertical', 'Black', 'MaxIteration', 'StyleFunction'},...
    {'hours', false, false, nan, []},...
    false,...
    varargin);

if ~isempty(aCells)
    imData = aCells(1).imageData;
end

cells = AreCells(aCells);

% Remove the contents of the axes.
cla(aAxes)
hold(aAxes, 'off')

% Find the y-values at which branches should be plotted.
Y1 = nan(size(cells));  % y-values where the branches start.
Y2 = nan(size(cells));  % y-values where the branches end.
maxY = 0;  % Largest y-value currently assigned to a branch.
for i = 1:length(cells)
    if isempty(cells(i).parent) && isnan(Y2(i))
        FindY(cells(i));
    end
end

% Store the y-coordinates in the cell objects, so that
% ManualCorrectionPlayer can keep track of which cell is which in the
% lineage tree.
for i = 1:length(cells)
    cells(i).Y2 = Y2(i);
end

% Plot lines.
for i = 1:length(cells)
    c = cells(i);
    ff = c.firstFrame;
    lf = c.lastFrame;
    
    if ~isnan(aMaxIteration)
        % Slow plotting code to plot cell fragments from different track
        % linking iterations in different colors.
        
        for t = ff:lf
            % The cell branch is plotted frame by frame, so that different
            % time intervals can be colored in different colors.
            
            if t == ff && ~isempty(c.parent)
                % 90 degree angle or straight line (if the cell is the only
                % child cell of its parent).
                x = [ff ff ff+1];
                y = [Y1(i) Y2(i) Y2(i)];
            else
                % Straight line.
                x = [t t+1];
                y = [Y2(i) Y2(i)];
            end
            
            if strcmpi(aXUnit, 'hours');
                x = imData.FrameToT(x);
            end
            
            % Determine plotting color.
            if c.iterations(t-ff+1) == aMaxIteration ||...
                    (t<lf && c.iterations(t-ff+2) == aMaxIteration)
                % This interval of the branch is from the last iteration.
                % Lines are made red in the time steps both before and
                % after a detection that was added to a track in the last
                % iteration.
                color = 'r';
            else
                % This interval of the branch is from earlier iterations.
                color = 'b';
            end
            
            plot(aAxes, x, y, 'LineWidth', 2, 'Color', color)
            hold(aAxes, 'on')
        end
    else
        % Faster code to plot lineage trees where each branch has a single
        % color.
        
        % 90 degree angle or straight line.
        x = [c.firstFrame c.firstFrame c.lastFrame+1];
        y = [Y1(i) Y2(i) Y2(i)];
        
        if strcmpi(aXUnit, 'hours')
            x = imData.FrameToT(x);
        end
        
        % Determine plotting color.
        if aBlack
            color = 'k';
        else
            color = c.color;
        end
        
        plot(aAxes, x, y, 'LineWidth', 2, 'Color', color);
        hold(aAxes, 'on')
    end
end

% Plot markers for mitosis and death. These are plotted after the lines, so
% that the lines do not cover them.
for i = 1:length(cells)
    c = cells(i);
    lf = c.lastFrame;
    
    if ~aBlack
        % Plot dots at divisions.
        if length(c.children) == 2
            x = lf+1;
            if strcmpi(aXUnit, 'hours');
                x = imData.FrameToT(x);
            end
            y = Y2(i);
            plot (aAxes, x, y, 'o',...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','k',...
                'MarkerSize',5);
        end
    end
    
    if c.died
        x = lf+1;
        if strcmpi(aXUnit, 'hours');
            x = imData.FrameToT(x);
        end
        y = Y2(i);
        % Plot crosses at death events.
        plot(aAxes, x, y, 'kx',...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','k',...
            'LineWidth', 2,...
            'MarkerSize', 10)
    end
end

% Set axis limits.
set(aAxes, 'ylim', [0 maxY+1])
if ~isempty(aCells)
    xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))
    
    title(aAxes, sprintf('Lineage Tree (%s)',...
        SpecChar(imData.GetSeqDir(), 'matlab')))
end

if ~aBlack
    switch aXUnit
        case 'frames'
            xlabel(aAxes, 'Time (frames)')
        case 'hours'
            xlabel(aAxes, 'Time (hours)')
    end
end
ylabel('')

% Show only an x-grid. Y-coordinates are not interesting.
set(aAxes, 'XGrid', 'on')
set(aAxes, 'YGrid', 'off')
set(aAxes, 'YTick', [])

% Rotates the lineage tree so that it is vertical.
if aVertical
    view(aAxes, 90, 90)
end

if ~isempty(aStyleFunction)
    feval(aStyleFunction, aAxes)
end

% Hold should be on even if there were no cells to plot.
hold(aAxes, 'on')

    function oY = FindY(aCell)
        % Computes y-coordinates for a cell branch.
        %
        % FindY computes the y-coordinates at which to plot the branch of a
        % lineage tree, and inserts the values into Y1 and Y2. The
        % algorithm is recursive, so that the y-value of a parent cell is
        % set to the mean y-value of the two daughter cells. The function
        % assumes that only cells without mother cells are given as inputs
        % when the function is called from some other function. The
        % function will call itself with daughter cells as inputs, and by
        % doing that it will traverse the lineage tree using depth first
        % search from bottom to top (in a horizontal lineage tree).
        %
        % Inputs:
        % aCell - The cell for which to compute the y-values.
        %
        % Outputs:
        % oY - The y-value at which the branch ends.
        
        if isempty(aCell.children)
            % Leaf cells in the tree are given integer y-values from 1 to
            % the total leaf count.
            oY = maxY + 1;
            maxY = oY;
        elseif length(aCell.children) == 1
            % There is no branching. The single daughter cell continues the
            % mother cell branch.
            oY = FindY(aCell.children(1));
            Y1(GetIndex(cells, aCell.children(1))) = oY;
        else
            % Mother branches end in the middle between the two daughter
            % branches.
            oY = (FindY(aCell.children(1)) + FindY(aCell.children(2))) / 2;
            Y1(GetIndex(cells, aCell.children(1))) = oY;
            Y1(GetIndex(cells, aCell.children(2))) = oY;
        end
        if isempty(aCell.parent)
            Y1(GetIndex(cells, aCell)) = oY;
        end
        Y2(GetIndex(cells, aCell)) = oY;
    end
end

function oIndex = GetIndex(aCellVec, aCell)
% Returns the index that a cell has in an array of cells.
%
% Inputs:
% aCellVec - Array of cells.
% aCell - Cell to find the index of.
%
% Outputs:
% oIndex - The index (indices) of aCell in aCellVec, or [] if the aCell is
%          not in aCellVec.

oIndex = find(aCellVec == aCell);
end