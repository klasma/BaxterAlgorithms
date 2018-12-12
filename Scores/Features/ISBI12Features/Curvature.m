function oCurvature = Curvature(aBlob, ~)
% Feature which measures the amount of curvature in the outline of a blob.
%
% For each point in the blob outline, the curvature is computed by fitting
% a circle to that point and its two neighbors and taking the inverse of
% the radius of the circle. The feature is a weighted sum of the
% point curvatures, where each weight is the mean of the distance to the
% preceding point and the distance to the following point. Maybe it would
% have been better to normalize the weights so that they sum to 1. That
% would have made the feature less dependent on the size if the blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
%
% Outputs:
% oCurvature - The computed feature value.
%
% See also:
% ComputeFeatures

B = bwboundaries(aBlob.image);
curv = 0;
% Sum over components of the blob boundary.
for i = 1:length(B)
    n = size(B{i},1);
    % Sum over individual boundary points.
    for j = 1:n
        % The 3 points to fit a circle to.
        x1 = B{i}(mod(j-2,n)+1,:);
        x2 = B{i}(j,:);
        x3 = B{i}(mod(j,n)+1,:);
        
        pl = PerimeterLength(x1, x2, x3) / 2;  % weight
        cr = CurvatureRadius(x1, x2, x3);  % curvature radius
        curv = curv + pl/cr;
    end
end
oCurvature = curv;
end

function oLength = PerimeterLength(aX1, aX2, aX3)
% The total length of two lines that connect 3 points.
%
% The first line goes from the first point to the second point and the
% second line goes from the second point to the third point.
%
% Inputs:
% aX1 - Row vector with the coordinates of the first point.
% aX2 - Row vector with the coordinates of the second point.
% aX3 - Row vector with the coordinates of the third point.
%
% Outputs:
% oLength - The total length of the two lines.

oLength = norm(aX3-aX2) + norm(aX2-aX1);
end

function oRadius = CurvatureRadius(aX1, aX2, aX3)
% Computes the radius of a circle that goes through 3 points.
%
% To fit a circle to the 3 points, we start from the equation for the
% circle (x-xc)^2+(y-yc)^2=r^2. Then we expand the squares on the left side
% and get a system of equations where we can solve for the 3 unknown
% quantities f(1)=r^2-xc^2-yc^2, f(2)=xc, and f(3)=yc.
%
% Inputs:
% aX1 - Row vector with the coordinates of the first point.
% aX2 - Row vector with the coordinates of the second point.
% aX3 - Row vector with the coordinates of the third point.
%
% Outputs:
% oRadius - Radius of a circle that has been fitted to the 3 points.

A = [ones(3,1), 2*[aX1; aX2; aX3]];
if rank(A) == 2
    % The 3 points are on a line (a circle with an infinite radius).
    oRadius = inf;
else
    % Fit a circle to the 3 points and compute its radius.
    b = sum([aX1; aX2; aX3].^2, 2);
    f = A\b;
    xc = f(2);
    yc = f(3);
    oRadius = sqrt(f(1) + xc^2 + yc^2);
end
end