function oC = Circularity(aBlob, aImProcessor)
% Circularity feature based on normalized central moments of the blob mask.
%
% This is a circularity measure from [1], based on the normalized central
% moments of the binary mask. The value is greater than or equal to 1.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oC - Circularity of the blob.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% See also:
% ComputeFeatures

% Get the normalized central moments.
n02 = aImProcessor.GetEta(aBlob,0,2);
n11 = aImProcessor.GetEta(aBlob,1,1);
n20 = aImProcessor.GetEta(aBlob,2,0);

m = 1/2*(n20+n02);
n = 1/2*sqrt(4*n11^2+(n20-n02)^2);

oC = (m-n)/(m+n);
end