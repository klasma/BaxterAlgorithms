function PlotOutlines(aAxes, aCells, aFrame, aTLength, varargin)
% Plots the outlines of all cells in an image or z-stack.
%
% The outlines are plotted using a line connecting the centers of all
% boundary pixels in the regions. If the cells are from a 3D data set, the
% outlines are first either projected on a coordinate plane, or cut using a
% plane which is orthogonal to one of the coordinate axes.
%
% Inputs:
% aAxes - Axes object to plot in.
% aCells - Array of cell objects for which the outlines will be plotted.
% aFrame - The index of the plotted image or z-stack.
% aTLength - The number of outlines that will be plotted for each cell. If
%            the parameter is greater than one, aTLength-1 outlines from
%            prior time points will be plotted in addition to the current
%            outline.
%
% Property/Value inputs:
% Options - struct with plotting options (LineWidth and fpColor). This
%           parameter is optional, as there are default options.
% MaxIteration - The index of the Viterbi-iteration which created the last
%                cell. If this property is specified, the outlines of the
%                last cell is colored red and all others are colored blue.
% Plane - The plane in which the outlines will be displayed. The parameter
%         can have the values 'xy', 'xz' and 'yz'. 'xy' is the default
%         value. The parameter has no effect on 2D data.
% MaxProj - Binary variable specifying if 3D outlines should be projected
%           onto the desired plane. If this parameter is false, the
%           outlines are instead cut in a plane parallel the the desired
%           coordinate plane.
% Slice - The index of the voxel slice which will be used to cut 3D
%         outlines. The slice is parallel to the plane specified in Plane.
%         If MaxProj is set to true, this parameter has no effect.
% TrackGraphics - If this is set to true, all of the graphics objects drawn
%                 are added to the Cell property 'graphics', so that they
%                 can be deleted at a later stage.

% Get Parameter/Value inputs.
[aOpts, aMaxIteration, aPlane, aMaxProj, aSlice, aTrackGraphics] = GetArgs(...
    {'Options', 'MaxIteration', 'Plane', 'MaxProj', 'Slice', 'TrackGraphics'},...
    {[], nan, 'xy', true, 1, false},...
    true,...
    varargin);

% Default plotting options.
opts = struct(...
    'LineWidth', 1,...  % Line width of the plotted outlines.
    'fpColor', [0 0 0]);  % The color of false positive cells.

% Insert user specified plotting options.
if ~isempty(aOpts)
    fields = fieldnames(aOpts);
    for fIndex = 1:length(fields)
        opts.(fields{fIndex}) = aOpts.(fields{fIndex});
    end
end

if isempty(aCells)
    return
end

alive = AliveCells(aCells, [aFrame-aTLength+1 aFrame]);
for cIndex = 1:length(alive)
    cCell = alive(cIndex);
    % First timepoint to draw.
    start = max(cCell.firstFrame, aFrame - aTLength + 1);
    % Last timepoint to draw.
    stop = min(cCell.lastFrame, aFrame);
    
    graphics = [];
    for t = start : stop
        % Determine the color of the next outline.
        if cCell.isCell
            if isnan(aMaxIteration) || isempty(cCell.iterations)
                col = cCell.color;
            else
                if cCell.iterations(t-cCell.firstFrame+1) == aMaxIteration
                    col = 'r';
                else
                    col = 'b';
                end
            end
        else
            % False positive.
            col = opts.fpColor;
        end
        
        blob = cCell.GetBlob(t);
        
        if isfield(opts, 'x1')
            % The user has zoomed in on a sub-volume, so everything outside
            % the sub-volume needs to be cut away.
            blob = CropBlobs(blob,...
                opts.x1, opts.x2,...
                opts.y1, opts.y2,...
                opts.z1, opts.z2);
            if isempty(blob)
                continue
            end
        end
        
        bb = blob.boundingBox;
        if any(isnan(bb))
            % The detection has no segment.
            continue
        end
        
        if cCell.imageData.numZ == 1  % 2D
            B = bwboundaries(blob.image);
            for k = 1:length(B)
                b = B{k};
                h = plot(aAxes, bb(1)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                    'Color', col,...
                    'LineWidth', opts.LineWidth);
                graphics = [graphics h]; %#ok<AGROW>
            end
        else  % 3D
            % Project the outlines on a plane or make a cut through the
            % outlines. The 2D contours are created by first rearranging
            % the coordinates in the desired order and then either summing
            % over the last index or selecting a plane in the last index.
            % This is done to avoid problems caused by squeeze when all
            % voxels of the 3D outline lies in a plane.
            switch aPlane
                case 'xy'
                    if aMaxProj
                        slice = sum(blob.image,3) > 0;
                    else
                        if  bb(3) > aSlice || bb(3) + bb(6) < aSlice
                            continue
                        end
                        slice = blob.image(:, :, aSlice - bb(3) + 0.5);
                    end
                case 'xz'
                    if aMaxProj
                        im = permute(blob.image, [3 2 1]);
                        slice = sum(im,3) > 0;
                    else
                        if  bb(2) > aSlice || bb(2) + bb(5) < aSlice
                            continue
                        end
                        im = permute(blob.image, [3 2 1]);
                        slice = im(:, :, aSlice - bb(2) + 0.5);
                    end
                case 'yz'
                    if aMaxProj
                        im = permute(blob.image, [1 3 2]);
                        slice = sum(im,3) > 0;
                    else
                        if  bb(1) > aSlice || bb(1) + bb(4) < aSlice
                            continue
                        end
                        im = permute(blob.image, [1 3 2]);
                        slice = im(:, :, aSlice - bb(1) + 0.5);
                    end
            end
            
            % Plot the outlines.
            B = bwboundaries(slice);
            for k = 1:length(B)
                b = B{k};
                switch aPlane
                    case 'xy'
                        h = plot(aAxes, bb(1)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                            'Color', col,...
                            'LineWidth', opts.LineWidth);
                        graphics = [graphics h]; %#ok<AGROW>
                    case 'xz'
                        h = plot(aAxes, bb(1)-0.5+b(:,2), bb(3)-0.5+b(:,1),...
                            'Color', col,...
                            'LineWidth', opts.LineWidth);
                        graphics = [graphics h]; %#ok<AGROW>
                    case 'yz'
                        h = plot(aAxes, bb(3)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                            'Color', col,...
                            'LineWidth', opts.LineWidth);
                        graphics = [graphics h]; %#ok<AGROW>
                end
            end
        end
    end
    
    if aTrackGraphics
        cCell.graphics = [cCell.graphics graphics];
    end
end
end