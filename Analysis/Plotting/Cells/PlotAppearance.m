function PlotAppearance(aAxes, aCells, aFrame, aTLength, varargin)
% Plots appearance events in as stars in the colors of the cells.
%
% An appearance event is when a cell appears in the field of view after the
% first frame. Daughter cells in mitotic events do not count as appearing
% cells. The function does not plot appearance events for cells that are
% considered to be false positives.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of Cell objects for which to mark appearance events.
% aFrame - The index of the frame which is displayed. Appearance events
%          that occur later will not be marked.
% aTLength - The maximum age of appearance events to be marked. If aTLength
%            is 1, only appearance events in frame aFrame will be marked.
%
% Property/Value inputs:
% Plane - The plane on which the appearance events should be projected
%         before they are plotted. The value can be 'xy', 'xz', or 'yz'.
%         The default is 'xy'.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.
%
% The function also takes additional Paramter/Value input arguments to the
% built in function plot, which plots the appearance locations.
%
% See also:
% PlotMitosis, PlotTrajectories, PlotOutlines

% Get additional input arguments.
[plotApoptosisArgs, plotArgs] = SelectArgs(varargin,...
    {'Plane', 'TrackGraphics'});
[aPlane, aTrackGraphics] = GetArgs(...
    {'Plane', 'TrackGraphics'},...
    {'xy', false},...
    true, plotApoptosisArgs);

for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    if c.isCell && isempty(c.parent) && c.firstFrame > 1 &&...
            c.firstFrame <= aFrame && c.firstFrame >= aFrame - aTLength + 1
        
        switch aPlane
            case 'xy'
                x = c.cx(1);
                y = c.cy(1);
            case 'xz'
                x = c.cx(1);
                y = c.cz(1);
            case 'yz'
                x = c.cz(1);
                y = c.cy(1);
        end
        
        h = plot(aAxes, x, y, 'p',...
            'MarkerEdgeColor', c.color,...
            'MarkerSize', 20,...
            plotArgs{:});
        
        if aTrackGraphics
            c.graphics = [c.graphics h];
        end
    end
end
end