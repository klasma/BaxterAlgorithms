function oProp = Texture(aBlob, aImProcessor, aType, aProp, aScale)
% Texture computes texture features of filtered images, inside Blob masks.
%
% The function can compute the features
%
% mean
% absmean   (mean of the absolute value of an image)
% std       (standard deviation)
% var       (variance)
% skew
% max
% min
%
% of filtered image pixels inside a Blob.
%
% As the filtered image, one can use:
%
% im        (background subtracted image)
% locvar    (local variance image)
% bg        (background image)
% bgvar     (local variance of the background image)
% prevdiff  (difference between the current and the previous image)
% nextdiff  (difference between the next and the current image)
% gradient  (gradient of down-sampled image)
% laplacian (Laplacian of down-sampled image)
% prethresh (intermediate segmentation image before thresholding)
%
% For the gradient- and the Laplacian-images, an additional input argument,
% with a down-sampling factor, can be given. By default this scaling factor
% is set to 1, but if it is set to something else, the image is
% down-sampled by the specified factor in both image directions. The
% gradient- or the Laplacian-image is then scaled up to the original image
% size.
%
% The mean, std and skew of the image, the gradient and the Laplacian are
% used as features for classification in [1]. In [1], scale factors of 1, 2
% and 3 are used for the gradient and the Laplacian, to generate 21 texture
% features in total.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
% aType - The filtered image to compute a statistic on. 'im', 'locvar',
%         'bg', 'bgvar', 'prevdiff', 'nextdiff', 'graident' or 'laplacian'.
% aProp - The statistic to compute on the pixels of the Blob. 'mean',
%         'absmean', 'sum', 'std', 'var', 'skew', 'max' or 'min'.
% aScale - Scale factors used in the gradient and Laplacian features. The
%          images are down-sampled by these factors before the features are
%          computed.
%
% Outputs:
% oProp - The desired statistic on the blob pixels from the desired
%         filtered image.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% See also:
% ComputeFeatures

if nargin == 4
    % By default, no scaling is done for the gradient and the Laplacian.
    aScale = 1;
end

% Get the entire image. Since the image is not modified, only a pointer
% will be sent to this file.
switch lower(aType)
    case 'rawim'
        im = aImProcessor.GetRawIm();
    case 'im'
        im = aImProcessor.GetNormIm();
    case 'locvar'
        im = aImProcessor.GetLocVarIm();
    case 'bg'
        im = aImProcessor.GetBgNormIm();
    case 'bgvar'
        im = aImProcessor.GetBgVarIm();
    case 'prevdiff'
        im = aImProcessor.GetPrevDiffIm();
    case 'nextdiff'
        im = aImProcessor.GetNextDiffIm();
    case 'gradient'
        im = aImProcessor.GetGradientKIm(aScale);
    case 'laplacian'
        im = aImProcessor.GetLaplacianKIm(aScale);
    case 'prethresh'
        im = aImProcessor.GetPreThresholdIm();
    otherwise
        error('%s is not a valid value for aType.', aType)
end

% Extract the desired pixels.
pixels = aBlob.GetPixels(im);

% Compute the desired statistic on the pixel values.
switch lower(aProp)
    case 'mean'
        oProp = mean(pixels);
    case 'absmean'
        oProp = mean(abs(pixels));
    case 'sum'
        oProp = sum(pixels);
    case 'std'
        oProp = std(pixels);
    case 'var'
        oProp = var(pixels);
    case 'skew'
        oProp = skewness(pixels);
    case 'max'
        oProp = max(pixels);
    case 'min'
        oProp = min(pixels);
    otherwise
        error('%s is not a valid value for aProp.', aProp)
end
end