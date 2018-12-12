function PlotTrajectories(aAxes, aCells, aFrame, aTLength, varargin)
% Plots trajectories of cells in an image or z-stack.
%
% All centroids in a time interval of length aTLength, ending at frame
% aFrame are drawn. Normal centroids are drawn as circles. Centroids that
% have been corrected by the user are drawn as squares. Presumed false
% positives are drawn as asterisks. The centroids that belong to the
% current frame are made bigger than the rest, and the centroids that
% belong to the current and the previous frames are filled if the symbols
% are either circles or squares. Many plotting alternatives can be changed
% using a Property/Value input called Options.

% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array with cell objects to draw trajectories for.
% aFrame - The index of the frame to be drawn.
% aTLength - The length of the time window in which centroids are drawn. 0
%            means that no centroids are drawn and inf means that the
%            trajectories are drawn from the first frame.
%
% Property/Value inputs:
% Options - Struct with plotting options. In the fields of the struct
%           described below, the letter 'x' in the beginning should be
%           replaced by 'd', 'c', or 'f' for original tracks, corrected
%           tracks, and false positive tracks respectively. This parameter
%           is optional, as there are default options.
% Options.LineWidth - Width of trajectories.
% Options.xMarker - Cell array or strings with 3 markers used to plot the
%                   current time point, the pervious time point, and time
%                   points before that (described from right to left.)
% Options.xMarkerSize - 3 element vector with marker sizes of the markers
%                       used to plot the time points described above.
% Options.xMarkerEdgeColor - 3 element cell array with edge colors of the
%                            markers used to plot the time points described
%                            above.
% Options.xMarkerEdgeColor - 3 element cell array with face colors of the
%                            markers used to plot the time points described
%                            above.
% Plane - The plane in which the trajectories will be displayed. The
%         parameter can have the values 'xy', 'xz' and 'yz'. 'xy' is the
%         default value. The parameter has no effect on 2D data.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.

% Get Property/Value inputs.
[aOpts, aPlane, aTrackGraphics] = GetArgs(...
    {'Options', 'Plane', 'TrackGraphics'},...
    {struct(), 'xy', false},...
    true,...
    varargin);

% Default plotting options.
opts = struct(...
    'LineWidth', 1,...
    'dMarker', {{'o', 'o', 'o'}},...
    'dMarkerSize', [3 3 5],...
    'dMarkerEdgeColor', {{[], [], []}},...
    'dMarkerFaceColor', {{'none', [], []}},...
    'cMarker', {{'s', 's', 's'}},...
    'cMarkerSize', [3 3 5],...
    'cMarkerEdgeColor', {{[], [], []}},...
    'cMarkerFaceColor', {{'none', [], []}},...
    'fMarker', {{'*', '*', '*'}},...
    'fMarkerSize', [3 3 5],...
    'fMarkerEdgeColor', {{'k', 'k', 'k'}},...
    'fMarkerFaceColor', {{'none', [], []}});

% Insert user specified plotting options.
fields = fieldnames(aOpts);
for fIndex = 1:length(fields)
    opts.(fields{fIndex}) = aOpts.(fields{fIndex});
end

if isempty(aCells)
    return
end

% Doing 'hold on' becomes time consuming if there are many cells.
% Therefore we only do it once.
holdon = false;

alive = AliveCells(aCells, [aFrame-aTLength+1 aFrame]);
for cIndex = 1:length(alive)
    cCell = alive(cIndex);
    % First timepoint to draw.
    start = max(cCell.firstFrame, aFrame - aTLength + 1);
    % Last timepoint to draw.
    stop = min(cCell.lastFrame, aFrame);
    t = start : stop;
    
    graphics = [];
    
    % Points on trajectories, projected on a plane.
    switch(aPlane)
        case 'xy'
            x = cCell.GetCx(start : stop);
            y = cCell.GetCy(start : stop);
        case 'xz'
            x = cCell.GetCx(start : stop);
            y = cCell.GetCz(start : stop);
        case 'yz'
            x = cCell.GetCz(start : stop);
            y = cCell.GetCy(start : stop);
    end
    
    % circles - Uncorrected centroids.
    % squares - Corrected centroids.
    % stars - False positive centroids.
    
    if ~cCell.isCell
        circles = zeros(size(t));
        squares = zeros(size(t));
        stars = ones(size(t));
    else
        notes = cCell.GetNote(start : stop);
        circles = notes == 0;
        squares = ~circles;
        stars = zeros(size(t));
    end
    
    largeFilled = (t == aFrame);  % Current frame.
    filled = (t == aFrame - 1); % Previous frame.
    small = (t <= aFrame - 2); % Other frames.
    
    % Use user specified colors if they have been specified. Otherwise use
    % the colors of the cells for plotting.
    cOpts = opts;
    colorOpts = {...
        'dMarkerEdgeColor',...
        'dMarkerFaceColor',...
        'cMarkerEdgeColor',...
        'cMarkerFaceColor',...
        'fMarkerEdgeColor',...
        'fMarkerFaceColor'};
    for oIndex = 1:length(colorOpts)
        for sIndex = 1:length(cOpts.(colorOpts{oIndex}))
            if isempty(cOpts.(colorOpts{oIndex}){sIndex})
                cOpts.(colorOpts{oIndex}){sIndex} = cCell.color;
            end
        end
    end
    
    
    % Link centroids together.
    if cCell.isCell
        h = plot(aAxes, x, y,...
            'Color', cOpts.dMarkerEdgeColor{1},...
            'LineWidth', cOpts.LineWidth);
    else
        h = plot(aAxes, x, y,...
            'Color', cOpts.fMarkerEdgeColor{1},...
            'LineWidth', cOpts.LineWidth);
    end
    graphics = [graphics h]; %#ok<AGROW>
    
    
    if ~isempty(x) && ~holdon
        hold(aAxes, 'on')
        holdon = true;
    end
    
    % Plot centroids.
    if cCell.isCell
        if any(circles)
            h1 = plot(aAxes, x(largeFilled & circles), y(largeFilled & circles),...
                cOpts.dMarker{3},...
                'MarkerEdgeColor', cOpts.dMarkerEdgeColor{3},...
                'MarkerFaceColor', cOpts.dMarkerFaceColor{3},...
                'MarkerSize', cOpts.dMarkerSize(3));
            h2 = plot(aAxes, x(filled & circles), y(filled & circles),...
                cOpts.dMarker{2},...
                'MarkerEdgeColor', cOpts.dMarkerEdgeColor{2},...
                'MarkerFaceColor', cOpts.dMarkerFaceColor{2},...
                'MarkerSize', cOpts.dMarkerSize(2));
            h3 = plot(aAxes, x(small & circles), y(small & circles),...
                cOpts.dMarker{1},...
                'MarkerEdgeColor', cOpts.dMarkerEdgeColor{1},...
                'MarkerFaceColor', cOpts.dMarkerFaceColor{1},...
                'MarkerSize', cOpts.dMarkerSize(1));
            graphics = [graphics h1 h2 h3]; %#ok<AGROW>
        end
        
        if any(squares)
            h1 = plot(aAxes, x(largeFilled & squares), y(largeFilled & squares),...
                cOpts.cMarker{3},...
                'MarkerEdgeColor', cOpts.cMarkerEdgeColor{3},...
                'MarkerFaceColor', cOpts.cMarkerFaceColor{3},...
                'MarkerSize', cOpts.cMarkerSize(3));
            h2 = plot(aAxes, x(filled & squares), y(filled & squares),...
                cOpts.cMarker{2},...
                'MarkerEdgeColor', cOpts.cMarkerEdgeColor{2},...
                'MarkerFaceColor', cOpts.cMarkerFaceColor{2},...
                'MarkerSize', cOpts.cMarkerSize(2));
            h3 = plot(aAxes, x(small & squares), y(small & squares),...
                cOpts.cMarker{1},...
                'MarkerEdgeColor', cOpts.cMarkerEdgeColor{1},...
                'MarkerFaceColor', cOpts.cMarkerFaceColor{1},...
                'MarkerSize', cOpts.cMarkerSize(1));
            graphics = [graphics h1 h2 h3]; %#ok<AGROW>
        end
    else
        h1 = plot(aAxes, x(largeFilled & stars), y(largeFilled & stars),...
            cOpts.fMarker{1},...
            'MarkerEdgeColor', cOpts.fMarkerEdgeColor{3},...
            'MarkerFaceColor', cOpts.fMarkerFaceColor{3},...
            'MarkerSize', cOpts.fMarkerSize(3));
        h2 = plot(aAxes, x(filled & stars), y(filled & stars),...
            cOpts.fMarker{2},...
            'MarkerEdgeColor', cOpts.fMarkerEdgeColor{2},...
            'MarkerFaceColor', cOpts.fMarkerFaceColor{2},...
            'MarkerSize', cOpts.fMarkerSize(2));
        h3 = plot(aAxes, x(small & stars), y(small & stars),...
            cOpts.fMarker{1},...
            'MarkerEdgeColor', cOpts.fMarkerEdgeColor{1},...
            'MarkerFaceColor', cOpts.fMarkerFaceColor{1},...
            'MarkerSize', cOpts.fMarkerSize(1));
        graphics = [graphics h1 h2 h3]; %#ok<AGROW>
    end
    
    % Link children to parents.
    if ~isempty(cCell.parent) && cCell.firstFrame > aFrame - aTLength + 1
        if cCell.isCell
            h = plot(aAxes,...
                [cCell.parent.cx(end) cCell.cx(1)],...
                [cCell.parent.cy(end) cCell.cy(1)],...
                'Color', cOpts.dMarkerEdgeColor{1});
        else
            h = plot(aAxes,...
                [cCell.parent.cx(end) cCell.cx(1)],...
                [cCell.parent.cy(end) cCell.cy(1)],...
                'Color', cOpts.fMarkerEdgeColor{1});
        end
        graphics = [graphics h]; %#ok<AGROW>
    end
    
    if aTrackGraphics
        cCell.graphics = [cCell.graphics graphics];
    end
end
end