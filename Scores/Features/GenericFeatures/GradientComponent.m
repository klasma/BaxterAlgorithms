function oGrad = GradientComponent(aBlob, aImProcessor, aComponent)
% Measures the radial or tangential image gradient in a blob.
%
% This function computes the mean absolute value of the image gradient
% component which is either tangential or radial with respect to the blob
% boundary. A vector is considered to be radial if it is aligned with the
% gradient of the distance transform of the binary mask of the blob.
% Similarly, a vector is considered to be tangential if it is perpendicular
% to the gradient of the distance transform. These two features are useful
% to detect clusters of cells and to detect mitotic events. The features
% were used to classify cell counts, mitotic events, and apoptotic events
% in [1].
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
% aComponent - Specifies which gradient component to analyze ('tangential'
%              or radial).
%
% Outputs:
% oGrad - The mean absolute value of the analyzed gradient component.
%
% References:
% [1] Magnusson, K. E. G.; Jaldén, J.; Gilbert, P. M. & Blau, H. M. Global
%     linking of cell tracks using the Viterbi algorithm IEEE Trans. Med.
%     Imag., 2015, 34, 1-19
%
% See also:
% ComputeFeatures

% Compute the gradient components of the distance image.
[distGradX, distGradY] = aImProcessor.GetDistGradIm();
distGradXPixels = aBlob.GetPixels(distGradX);
distGradYPixels = aBlob.GetPixels(distGradY);

% Compute the gradient magnitude of the distance image.
cutDistGradMagn = sqrt(distGradXPixels.^2 + distGradYPixels.^2);

% Normalize the gradient components of the distance image to unit length.
gX = distGradXPixels ./ (cutDistGradMagn + eps);
gY = distGradYPixels ./ (cutDistGradMagn + eps);

% Compute the gradient components of the intensity image.
[gradX, gradY] = aImProcessor.GetGradIm();
gradXPixels = aBlob.GetPixels(gradX);
gradYPixels = aBlob.GetPixels(gradY);

% Find the components of the intensity image gradient which are
% radial/tangential with respect to the blob boundary.
switch lower(aComponent)
    case 'radial'
        gradIm = gX.*gradXPixels + gY.*gradYPixels;
    case 'tangential'
        gradIm = gY.*gradXPixels - gX.*gradYPixels;
end

% Compute the mean absolute value of the gradient component.
oGrad = mean(abs(gradIm));
end