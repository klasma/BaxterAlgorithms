function oHeight = HeightMean(aBlob, aImProcessor)
% The mean height of a smoothed intensity profile of a blob.
%
% First, the image is smoothed with a kernel with a standard deviation of 5
% pixels. Then the minimum value inside the blob is subtracted. Finally,
% the average intensity (height) inside the blob is computed.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, Height

smooth = aBlob.GetPixels(aImProcessor.GetSmoothIm());
height = smooth - min(smooth);
oHeight = mean(height);
end