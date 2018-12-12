function oGradMag = GradMagMean(aBlob, aImProcessor)
% Feature which measures the average gradient magnitude.
%
% This feature has been replaced by Texture_gradient_mean in new
% classifiers, it is still used in some old classifiers. The features are
% not identical, because Texture_gradient_mean uses background subtraction
% while this function does not.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oGradMag - The computed feature value.
%
% See also:
% ISBI2012Features, Texture

[gradXIm, gradYIm] = aImProcessor.GetGradIm();
gradx = aBlob.GetPixels(gradXIm);
grady = aBlob.GetPixels(gradYIm);
oGradMag = mean(sqrt(gradx.^2 + grady.^2));
end
