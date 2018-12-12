function PlotDisappearance(aAxes, aCells, aFrame, aTLength, varargin)
% Plots disappearance events in as triangles in the colors of the cells.
%
% A disappearance event is when a cell disappears from the field of view
% without going through apoptosis. The function does not show disappearance
% events in cells that are considered to be false positives.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of Cell objects for which to mark disappearance events.
% aFrame - The index of the frame which is displayed. Disappearance events
%          that occur later will not be marked.
% aTLength - The maximum age of disappearance events to be marked. If
%            aTLength is 1, only disappearance events in frame aFrame will
%            be marked.
%
% Property/Value inputs:
% Plane - The plane on which the disappearance events should be projected
%         before they are plotted. The value can be 'xy', 'xz', or 'yz'.
%         The default is 'xy'.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.
%
% The function also takes additional Paramter/Value input arguments to the
% built in function plot, which plots locations of the disappearance
% events.
%
% See also:
% PlotMitosis, PlotTrajectories, PlotOutlines, PlotAppearance

% Get additional input arguments.
[plotApoptosisArgs, plotArgs] = SelectArgs(varargin,...
    {'Plane', 'TrackGraphics'});
[aPlane, aTrackGraphics] = GetArgs(...
    {'Plane', 'TrackGraphics'},...
    {'xy', false},...
    true, plotApoptosisArgs);

for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    if c.isCell && c.disappeared &&...
            c.lastFrame <= aFrame && c.lastFrame >= aFrame - aTLength + 1
        
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
        
        h = plot(aAxes, x, y, 'v',...
            'MarkerEdgeColor', c.color,...
            'MarkerSize', 20,...
            plotArgs{:});
        
        if aTrackGraphics
            c.graphics = [c.graphics h];
        end
    end
end
end