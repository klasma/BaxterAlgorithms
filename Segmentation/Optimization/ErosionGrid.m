function oGrid = ErosionGrid(aR)
% Defines a grid of erosion values where the structuring element changes.
%
% Inputs:
% aR - Maximum radius to be included in the array of radii. All returned
%      radii will be smaller than or equal to this value.
%
% Outputs:
% oGrid - Array of structuring element radii which result in unique
%         structuring elements. For each unique structuring element, the
%         smallest possible radius is included. The radii are sorted in
%         increasing order. The array only contains radii which are smaller
%         than or equal to aR.

[Y, X] = meshgrid(-aR:aR, -aR:aR);
D = sqrt(X.^2 + Y.^2);  % Distance from center.
oGrid = unique(D(:));
oGrid(oGrid > aR) = [];
end