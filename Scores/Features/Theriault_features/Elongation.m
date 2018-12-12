function oElongation = Elongation(aBlob, aImProcessor)
% Feature for elongation of the binary mask of a blob.
%
% Measure of blob elongation based on the fist 2 Hu invariant moments of
% the binary mask of the blob. The feature is 0 for shapes with 3-fold or
% greater rotational symmetry.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oElongation - Elongation of the Blob.
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
% Dispersion, Extension, Hu, ComputeFeatures

hu1 = Hu(aBlob, aImProcessor, 1);
hu2 = Hu(aBlob, aImProcessor, 2);

lambda1 = 2*pi*(hu1 + sqrt(hu2));
lambda2 = 2*pi*(hu1 - sqrt(hu2));

oElongation = log2(sqrt(lambda1/lambda2));
end