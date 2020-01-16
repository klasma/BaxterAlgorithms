function PlotIndices(aAxes, aCells, aFrame, aTLength, varargin)
% Displays indices of cells in an image or z-stack.
%
% The index of a cell should always be the index of the cell in the saved
% array of cells that it belongs to. The index is meant to be used to
% identify the cell when the raw tracking results are analyzed.
%
% Inputs:
% aAxes - Axes object to add indices in.
% aCells - Array of cell objects for which the indices will be displayed.
% aFrame - The index of the plotted image or z-stack.
% aTLength - The number of time points that will be plotted for each cell.
%            If a cell is present in the current frame, the index is
%            plotted at its position in the current frame. Otherwise, the
%            index is plotted at its position in the last frame if the last
%            frame is one of the aTLength-1 prior frames points.
%
% Property/Value inputs:
% Options - struct with plotting options (textColor, fontSize and
%           fontWeight). This parameter is optional, as there are default
%           options.
% Plane - The plane in which the indices will be displayed. The parameter
%         can have the values 'xy', 'xz' and 'yz'. 'xy' is the default
%         value.
% TrackGraphics - If this is set to true, all of the graphics objects
%                 created are added to the Cell property 'graphics', so
%                 that they can be deleted at a later stage.

% Get Property/Value inputs.
[aOpts, aPlane, aTrackGraphics] = GetArgs(...
    {'Options', 'Plane', 'TrackGraphics'},...
    {struct(), 'xy', false},...
    true,...
    varargin);

% Default plotting options.
opts = struct(...
    'textColor', [0 0 0],...
    'fontSize', 12,...
    'fontWeight', 'normal');  % The color of false positive cells.

% Insert user specified plotting options.
if ~isempty(aOpts)
    fields = fieldnames(aOpts);
    for fIndex = 1:length(fields)
        opts.(fields{fIndex}) = aOpts.(fields{fIndex});
    end
end

for cIndex = 1:length(aCells)
    c = aCells(cIndex);
    
    if c.firstFrame > aFrame
        % The cell starts after the plotted time interval.
        continue
    end
    if c.lastFrame < aFrame - aTLength + 1
        % The cell ends before the plotted time interval.
        continue
    end
    
    if c.lastFrame < aFrame
        x_cell = c.GetCx(c.lastFrame);
        y_cell = c.GetCy(c.lastFrame);
        z_cell = c.GetCz(c.lastFrame);
    else
        x_cell = c.GetCx(aFrame);
        y_cell = c.GetCy(aFrame);
        z_cell = c.GetCz(aFrame);
    end
    
    % Convert from cell coordinates to coordinates in the image.
    switch(aPlane)
        case 'xy'
            x_text = x_cell;
            y_text = y_cell;
        case 'xz'
            x_text = x_cell;
            y_text = z_cell;
        case 'yz'
            x_text = z_cell;
            y_text = y_cell;
    end
    
    h = text(aAxes, x_text, y_text, num2str(c.index),...
        'Color', opts.textColor,...
        'FontSize', opts.fontSize,...
        'FontWeight', opts.fontWeight);
    
    if aTrackGraphics
        c.graphics = [c.graphics h];
    end
end
end