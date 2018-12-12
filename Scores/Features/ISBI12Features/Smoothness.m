function oVal = Smoothness(aBlob, aImProcessor)
% Feature which measures how different a blob is from a smoothed version.
%
% The function returns the mean absolute difference between the image and a
% smoothed version of it, inside the segmentation mask of the blob. The
% smoothed version of the image is created by convolving the image with
% a Gaussian kernel with a standard deviation of 5 pixels.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oVal - The computed feature value.
%
% See also:
% ComputeFeatures

im = aBlob.GetPixels(aImProcessor.GetNormIm());
smooth = aBlob.GetPixels(aImProcessor.GetSmoothIm());
oVal = mean(abs(im - smooth));
end