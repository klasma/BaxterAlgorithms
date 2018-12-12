function oFeatures = TheriaultFeatures()
% Set of 40 features for cell shape classification in phase contrast.
%
% The feature set was used in [1] to classify fibroblast cells in phase
% contrast microscopy into different shape classes. The feature set
% contains 19 shape based features and 21 appearance based features. In [1]
% the authors say that there are 18 shape based features, but they count
% the cell centroid as a single feature while we have separate features for
% the x- and y-coordinates.
%
% Outputs:
% oFeatures - Cell array with feature names.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% See also:
% TransmissionFeatures, ComputeFeatures, NecessaryFeatures,
% SubstituteFeatureNames, FeatureMatrix, Blob, Train, Classify

oFeatures = {
    'Area'
    'CentroidX'
    'CentroidY'
    'Circularity'
    'Hu_1'
    'Hu_2'
    'Hu_3'
    'Hu_4'
    'Hu_5'
    'Hu_6'
    'Hu_7'
    'Extension'
    'Dispersion'
    'Elongation'
    'BoundaryCentroidDist_mean'
    'BoundaryCentroidDist_std'
    'BoundaryCentroidDist_min'
    'BoundaryCentroidDist_max'
    'ShapeFactor'
    'Texture_im_mean'
    'Texture_im_std'
    'Texture_im_skew'
    'Texture_gradient_mean_1'
    'Texture_gradient_mean_2'
    'Texture_gradient_mean_3'
    'Texture_gradient_std_1'
    'Texture_gradient_std_2'
    'Texture_gradient_std_3'
    'Texture_gradient_skew_1'
    'Texture_gradient_skew_2'
    'Texture_gradient_skew_3'
    'Texture_laplacian_mean_1'
    'Texture_laplacian_mean_2'
    'Texture_laplacian_mean_3'
    'Texture_laplacian_std_1'
    'Texture_laplacian_std_2'
    'Texture_laplacian_std_3'
    'Texture_laplacian_skew_1'
    'Texture_laplacian_skew_2'
    'Texture_laplacian_skew_3'};
end