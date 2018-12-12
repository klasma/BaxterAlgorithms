function oIm = CutPixelRegion(aIm, aPixelRegion)
% Crops out a sub-image from a 2D gray scale image.
%
% The function extracts the same type of sub-image as the built in function
% imread does for tif-images when the parameter 'PixelRegion' is specified.
% This function is meant to generate the same type of output, when other
% file types have been read.
%
% Inputs:
% aIm - 2D matrix representing the full image.
% PixelRegion - Two element cell array with 2- or 3-element vectors
%               defining a sub-image to be extracted. The two vectors
%               define pixel intervals in the two image dimensions. In a 3
%               element vector, element 2 specifies a step length, so that
%               the image can be down-sampled. The same input can be given
%               to the build in function imread, if the image is a
%               tif-image.
%
% Outputs:
% oIm - 2D matrix representing the cut out subimage.


% Column range.
if length(aPixelRegion{1}) == 2
    y = aPixelRegion{1}(1) : aPixelRegion{1}(2);
elseif length(aPixelRegion{1}) == 3
    y = aPixelRegion{1}(1) : aPixelRegion{1}(2) : aPixelRegion{1}(3);
else
    error('The first cell of PixelRegion is incorrectly formated.')
end

% Row range.
if length(aPixelRegion{2}) == 2
    x = aPixelRegion{2}(1) : aPixelRegion{2}(2);
elseif length(aPixelRegion{2}) == 3
    x = aPixelRegion{2}(1) : aPixelRegion{2}(2) : aPixelRegion{2}(3);
else
    error('The second cell of PixelRegion is incorrectly formated.')
end

oIm = aIm(y,x);
end