function oShapeFactor = ShapeFactor(aBlob, ~)
% Ratio of blob area and the area of a circle with the same perimeter.
%
% Equal to the old feature InvCompactness.
%
% Inputs:
% aBlob - Blob object for which the shape factor should be computed.
%
% Outputs:
% oShapeFacor - Shape factor.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% See also:
% Dispersion, Elongation, Extension, ComputeFeatures

bw = aBlob.image;
props = regionprops(double(bw), 'Perimeter');
perimeter = max(props.Perimeter, 1);
area = sum(bw(:));
oShapeFactor = 4*pi*area / perimeter^2;
end