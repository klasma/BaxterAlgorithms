function PlotMitosis(aAxes, aCells, aFrame, aTLength, varargin)
% Plots mitotic events as circles.
%
% The function marks the locations of mitotic events in an image with
% circles in the parent cell color. The function can also plot the mitotic
% events in red or blue depending on in which iteration the events were
% added. The function does not plot mitotic events in cells that are
% considered to be false positives.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of Cell objects for which to mark mitotic events.
% aFrame - The index of the frame which is displayed. Mitotic events that
%          occur later will not be marked.
% aTLength - The maximum age of mitotic events to be marked. If aTLength is
%            1, only mitotic events in frame aFrame will be marked.
%
% Property/Value inputs:
% MaxIteration - The index of the Viterbi-iteration which created the last
%                cell. If this property is specified, the mitotic event
%                which created the last cell is colored red and all other
%                mitotic events are colored blue.
% Plane - The plane on which the mitotic events should be projected before
%         they are plotted. The value can be 'xy', 'xz', or 'yz'. The
%         default is 'xy'.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.
%
% The function also takes additional Paramter/Value input arguments to the
% built in function plot, which plots locations of the mitotic events.
%
% See also:
% PlotApoptosis, PlotTrajectories, PlotOutlines

% Get additional input arguments.
[plotMitosisArgs, plotArgs] = SelectArgs(varargin,...
    {'MaxIteration', 'Plane', 'TrackGraphics'});
[aMaxIteration, aPlane, aTrackGraphics] = GetArgs(...
    {'MaxIteration', 'Plane', 'TrackGraphics'},...
    {[], 'xy', false},...
    true,...
    plotMitosisArgs);

for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    if c.isCell && ~isempty(c.children) && c.lastFrame <= aFrame &&...
            c.lastFrame >= aFrame - aTLength + 1
        
        if ~isempty(aMaxIteration)
            % Color based on iteration.
            if c.children(1).iterations(1) == aMaxIteration ||...
                    c.children(2).iterations(1) == aMaxIteration
                col = 'r';
            else
                col = 'b';
            end
        else
            % Color based on the parent cell color.
            col = c.color;
        end
        
        switch aPlane
            case 'xy'
                x = c.cx(end);
                y = c.cy(end);
            case 'xz'
                x = c.cx(end);
                y = c.cz(end);
            case 'yz'
                x = c.cz(end);
                y = c.cy(end);
        end
        
        h = plot(aAxes, x, y, 'o',...
            'MarkerEdgeColor', col,...
            'MarkerSize', 20,...
            plotArgs{:});
        
        if aTrackGraphics
            c.graphics = [c.graphics h];
        end
    end
end
end