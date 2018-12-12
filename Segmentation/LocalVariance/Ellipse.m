function oEllipse = Ellipse(aA)
% Creates logical array with a 2- or 3-dimensional ellipsoid.
%
% Inputs:
% aA - Vector with the lengths of the ellipsoid semi-axes. If the vector
%      has length 2, a 2-dimensional ellipsoid is returned and if it has
%      length 3, a 3-dimensional ellipsoid is returned. Dimension d will
%      have 2*aA(d)+1 elements.
%
% Outputs:
% oEllipse - Matrix with an ellipsoid of ones and a background of zeros.

fA = floor(aA);

switch length(aA)
    case 2
        [Y, X] = meshgrid(-fA(2):fA(2), -fA(1):fA(1));
        D = sqrt((X/aA(1)).^2 + (Y/aA(2)).^2);  % Distance from center.
    case 3
        [Y, X, Z] = meshgrid(-fA(2):fA(2), -fA(1):fA(1), -fA(3):fA(3));
        % Distance from center.
        D = sqrt((X/aA(1)).^2 + (Y/aA(2)).^2 + (Z/aA(3)).^2);
    otherwise
        error('aA must have length 2 or 3.')
end

oEllipse = zeros(2*fA+1);
oEllipse(D <= 1) = 1;
end