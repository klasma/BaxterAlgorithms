function oBoundaries = GetBoundaries(aRegion, varargin)
% Finds region outlines that go around the pixel borders.
%
% The function works in the same way as bwboundaries, but instead of
% returning a boundary that goes through the pixel centers, it returns a
% boundary that follows the outsides of the pixel borders. The function
% first computes an outline that goes through the pixel centers, and then
% goes from pixel to pixel in the outline and finds the pixel corners that
% lie just outside the outline. The pixel coordinates are treated as
% complex numbers, where the y-coordinate is the imaginary part. This makes
% it easy to rotate and add vectors to find the pixel corners. The
% boundaries are always computed using 4-connectivity.
%
% Inputs:
% aRegion - Either a Blob object or a binary mask of the same size as the
%           original image.
%
% Property/Value inputs:
% AllowHoles - If this is set to true, the algorithm will include holes in
%              the regions in the returned boundaries. By default, the
%              algorithm will not include the holes. The algorithm runs
%              faster when holes are not returned.
%
% Outputs:
% oBoundaries - Cell array with boundaries of regions and holes. Each cell
%               contains a N+1x2 matrix where N is the length of the
%               outline. The first column is the y-coordinates of the
%               outline and the second column is the x-coordinates. The
%               first coordinate is repeated at the end, so that the
%               outline is closed when the columns are plotted. The outline
%               is traversed clockwise, assuming that the direction of the
%               y-axis is reversed, as when images are displayed.

% Parse property/value inputs.
aAllowHoles = GetArgs({'AllowHoles'}, {false}, true, varargin);

if isa(aRegion, 'Blob')
    mask = aRegion.image;
    bb = aRegion.boundingBox;
    % Shift which transforms from local coordinates of the Blob to global
    % coordiantes in the original image.
    offset = (bb(1)-0.5) + 1i*(bb(2)-0.5);
else
    % The input is a binary image with the same size as the original image.
    mask = aRegion;
    offset = 0;
end

% Compute boundaries that go through the centers of the pixels.
if aAllowHoles
    [boundaries, labels, num] = bwboundaries(mask, 4);
    
    % The holes are outlined with 8-connectivity even though 4-connectivity
    % has been specified. Therefore, new boundaries are computed for the
    % holes using 4-connectivity.
    if length(boundaries) > num
        holes = labels > num;
        holeboundaries = bwboundaries(holes, 4, 'noholes');
        boundaries = [boundaries(1:num); holeboundaries];
    end
else
    [boundaries, ~, ~, adjacencies] = bwboundaries(mask, 4, 'noholes');
    
    % Remove objects that are inside other objects, as these objects would
    % merge with the objects that they are inside if holes were filled.
    boundaries(any(adjacencies,2)) = [];
end
oBoundaries = cell(size(boundaries));

for i = 1:length(boundaries)
    boundary = boundaries{i};
    
    if size(boundary,1) == 2
        % Special case with a single pixel. The algorithm is based on
        % vectors that go between the pixels in the outline, and therefore
        % regions with a single pixel must be treated separately.
        oBoundaries{i} = [...
            1.5 1.5
            0.5 1.5
            0.5 0.5
            1.5 0.5
            1.5 1.5] +...
            repmat(boundary(1,:) - 1 + [imag(offset) real(offset)], 5, 1);
        continue
    end
    
    % Convert the coordinate matrix to a vector of complex numbers. The
    % y-coordinate is the imaginary part. The computations are done in a
    % coordinate system where the y-axis points upward, so therefore the
    % outlines from bwboundaries are traversed counterclockwise.
    p = boundary(:,2) + 1i*boundary(:,1) + offset;
    % Add the last point of the outline to the beginning, so that we don't
    % need to deal with modulus operations in the for-loop. The last point
    % of the outline is the second to last element of p, as the first point
    % has already been concatenated at the end.
    p = [p(end-1); p]; %#ok<AGROW>
    % Allocate too many elements for the new outline.
    outline = zeros(4*length(p),1);
    % The element where the next outline coordinate should be inserted.
    index = 1;
    for t = 2:length(p)-1
        p0 = p(t-1);  % Previous pixel.
        p1 = p(t);    % Current pixel.
        p2 = p(t+1);  % Next pixel.
        
        d1 = p1 - p0;  % Vector from previous to current.
        d2 = p2 - p1;  % Vector from current to next.
        
        % Offset to the next potential corner coordinate. The direction is
        % 45 degrees to the right of the forward direction when the outline
        % is traversed counterclockwise. The distance is from the pixel
        % center to the pixel corner.
        d = d1 / sqrt(2) * exp(-1i*pi/4);
        
        % Add corner pixels and turn 90 degrees to the next corner pixel
        % until we reach 45 degrees to the left of the vector d2 which
        % leads to the next pixel.
        while mod(angle(d/d2), 2*pi) > pi/2
            outline(index) = p1 + d;
            index = index + 1;
            % Turn 90 degrees to the left.
            d = d * exp(1i*pi/2);
        end
    end
    % Convert from complex numbers to xy-coordinates.
    oBoundaries{i} = [imag(outline(1:index-1)) real(outline(1:index-1))];
    % Concatenate the first coordinate at the end to close the outline.
    oBoundaries{i} = [oBoundaries{i}; oBoundaries{i}(1,:)];
end
end