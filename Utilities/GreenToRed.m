function oMap = GreenToRed(aLength)
% Color map which goes from dark green to yellow to red.
%
% The color map has a dark green in the beginning, yellow in the middle,
% and red at the end. The transitions between the colors are linear.
%
% Inputs:
% aLength - The number of colors in the color map.
%
% Outputs:
% oMap - aLength x 3 matrix which defines a color map. Each row is an
%        RGB-triplet with values between 0 and 1.

green = [0 1 0]*0.5;
yellow = [1 1 0];
red = [1 0 0];

% Linear scale from 0 to 1 with aLength elements.
scale = (0:1/(aLength-1):1)';

oMap = nan(aLength,3);

i1 = scale <= 0.5;
i2 = scale > 0.5;
% Create colors from green to yellow.
oMap(i1,:) = (1-scale(i1)*2)*green + scale(i1)*2*yellow;
% Create colors from yellow to red.
oMap(i2,:) = (1-scale(i2))*2*yellow + (scale(i2)*2-1)*red;
end