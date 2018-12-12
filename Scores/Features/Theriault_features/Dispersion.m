function oDispersion = Dispersion(aBlob, aImProcessor)
% Feature for dispersion of the binary mask of a blob.
%
% Measure of blob dispersion based on the fist 2 Hu invariant moments of
% the binary mask of the blob. The feature is 0 for ellipses and is
% invariant to stretching and shearing.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oDispersion - Dispersion of the blob.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% [2] Dunn et al. Alignment of fibroblasts on grooved surfaces described by
%     a simple geometric transformation.
%
% See also:
% Elongation, Extension, Hu, ComputeFeatures

hu1 = Hu(aBlob, aImProcessor, 1);
hu2 = Hu(aBlob, aImProcessor, 2);

lambda1 = 2*pi*(hu1 + sqrt(hu2));
lambda2 = 2*pi*(hu1 - sqrt(hu2));

oDispersion = log2(sqrt(lambda1*lambda2));
end