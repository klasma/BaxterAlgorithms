function [oPx, oPy] = PixelsBetween(aX1, aY1, aX2, aY2)
% Finds all of the pixels on a line between a two specified pixels.
%
% The pixels on the line are found by starting at the first endpoint and
% taking horizontal, vertical, or diagonal steps to get closer to the
% second endpoint. In each step, the direction is chosen so that the next
% pixel is as close as possible to the straight line that goes between the
% two endpoints. The regions separated by the line will not be 4-connected,
% but may be 8-connected. The endpoint pixels are not included in the
% output.
%
% Inputs:
% aX1 - x-coordinate of first pixel.
% aY1 - y-coordinate of first pixel.
% aX2 - x-coordinate of second pixel.
% aY2 - y-coordinate of second pixel.
%
% Outputs:
% oPx - Column vector with x-coordinates of line pixels.
% oPy - Column vector with y-coordinates of line pixels.

% Array where line pixel coordinates will be entered. The first column is
% for x-coordinates and the second column is for y-coordinates.
pixels = zeros(0,2);

% Define a coordinate system where the first point is at the origin.
offset = [aX1; aY1];
p1 = [0; 0];
p2 = [aX2; aY2] - [aX1; aY1];
if all(p2 == 0)
    % Return empty vectors if point 1 and point 2 are the same.
    oPx = [];
    oPy = [];
    return
end
% Unit vector pointing from point 1 to point 2.
v = p2 / norm(p2);

% Two axis-aligned unit vectors that have v between them.
e1 = [sign(aX2-aX1+eps); 0];
e2 = [0; sign(aY2-aY1+eps)];

% Start in p1 and take steps in the directions of e1, e2, or e1+e2 until we
% get to p2. In every step we go to the pixel which is closest to the line.
p = p1;
while true
    % Candidates for the next pixel on the line.
    q = [p+e1 p+e2 p+e1+e2]';
    
    % Compute distances between the candidate points and the line.
    dvec = q - (q*v)*v';
    d = sum(dvec.*dvec,2);
    
    % Pick the candidate point closest to the line.
    [~,index] = min(d);
    p = q(index,:)';
    
    if all(p==p2)
        % Stop when we have reached p2.
        break
    end
    pixels = [pixels; p'+offset']; %#ok<AGROW>
end

oPx = pixels(:,1);
oPy = pixels(:,2);
end