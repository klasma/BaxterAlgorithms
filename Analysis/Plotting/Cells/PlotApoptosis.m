function PlotApoptosis(aAxes, aCells, aFrame, aTLength, varargin)
% Plots apoptotic events as x:es in the colors of the cells.
%
% The function does not plot apoptotic events for cells that are considered
% to be false positives.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of Cell objects for which to mark apoptotic events.
% aFrame - The index of the frame which is displayed. Apoptotic events that
%          occur later will not be marked.
% aTLength - The maximum age of apoptotic events to be marked. if aTLength
%            is 1, only apoptotic events in frame aFrame will be marked.
%
% Property/Value inputs:
% Plane - The plane on which the apoptotic events should be projected
%         before they are plotted. The value can be 'xy', 'xz', or 'yz'.
%         The default is 'xy'.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.
%
% The function also takes additional paramter/value input arguments to the
% built in function plot, which plots the x:es using the marker 'x'.
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
    if c.isCell && c.died &&...
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
        
        h = plot(aAxes, x, y, 'x',...
            'MarkerEdgeColor', c.color,...
            'MarkerSize', 20,...
            plotArgs{:});
        
        if aTrackGraphics
            c.graphics = [c.graphics h];
        end
    end
end
end