function oExtension = Extension(aBlob, aImProcessor)
% Feature which measures how extended (non-compact) a blob is.
%
% Measure of how spread out a blob is compared to a circle. The lower
% bound on the extension is 0 and is attained by by a circular disc, but
% there is no upper bound. The extension is the sum of the dispersion and
% the elongation.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oExtension - Extension of the Blob.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% [2] Dunn et al. Alignment of fibroblasts on grooved surfaces described by
% a simple geometric transformation.
%
% See also:
% Dispersion, Elongation, ComputeFeatures

hu1 = Hu(aBlob, aImProcessor, 1);
hu2 = Hu(aBlob, aImProcessor, 2);
lambda1 = 2*pi*(hu1 + sqrt(hu2));
oExtension = log2(lambda1);
end