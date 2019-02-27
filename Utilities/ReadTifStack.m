function oStack = ReadTifStack(aPath)
% Reads all z-slices of a tif stack.
%
% Inputs:
% aPath - Full path of the tif-file, including the extension.
%
% Outputs:
% oStack - 3D array with all slizes of the tif stack. The array has the
%          same type as the tif stack.

info = imfinfo(aPath);
numImages = numel(info);
intType = sprintf('uint%d', info(1).BitDepth);
oStack = zeros(info(1).Height, info(1).Width, numImages, intType);
for i = 1:numImages
    oStack(:,:,i) = imread(aPath, i);
end
end