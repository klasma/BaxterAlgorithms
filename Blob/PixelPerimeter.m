function oPerimeter = PixelPerimeter(aMask)
% Computes the perimeter of a binary pixel region.
%
% The perimeter is computed as the length of the shortest path which goes
% around all pixels in the region on the the outside. This value is
% different from the perimeter value returned by regionprops, which
% measures the length of a path which goes through the centers of the
% boundary pixels. If the mask has multiple connected components, the
% perimeter is the sum of the perimeters of the individual components. The
% perimeter is computed by counting the number of boundary pixels that are
% 4-adjacent to each foreground pixel and summing these numbers. The number
% of boundary pixels are counted using filtering with a 3x3 cross filter.
%
% Inputs:
% aMask - Binary matrix where foreground pixels are 1:s.
%
% Outputs:
% oPerimeter - Perimeter length of the foreground region in pixel units.

padMask = padarray(aMask, [1 1]);
connFilter = [0 1 0; 1 1 1; 0 1 0];
numBackgroundNeighbors = conv2(double(~padMask), connFilter, 'same');
numEdges = numBackgroundNeighbors .* padMask;
oPerimeter = sum(numEdges(:));
end