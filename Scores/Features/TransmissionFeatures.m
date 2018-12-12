function oFeatures = TransmissionFeatures()
% Feature set used for tracking in transmission microscopy.
%
% The feature set is an extension of TheriaultFeatures. In [1] it was used
% to classify cell counts, cell divisions, and cell deaths in segmented
% regions in bright field microscopy. The feature set adds some additional
% texture features, GradientComponent_tangential and
% GradientComponent_radial to TheriaultFeatures. It also replaces the x-
% and y-coordinates of the blob by the distance to the center of the
% microwell. The added texture features contain features computed from the
% differences between images, and therefore the features can be used to
% detect temporal events, such as cell division and cell death. The cells
% are assumed to be in a circular microwell.
%
% Outputs:
% oFeatures - Cell array with feature names.
%
% References:
% [1] Magnusson, K. E. G.; Jaldén, J.; Gilbert, P. M. & Blau, H. M. Global
%     linking of cell tracks using the Viterbi algorithm IEEE Trans. Med.
%     Imag., 2015, 34, 1-19
%
% See also:
% TheriaultFeatures, ISBI2012Features, ComputeFeatures, NecessaryFeatures,
% SubstituteFeatureNames, FeatureMatrix, Blob, Train, Classify

extra_texture_features = {
    'Texture_im_min'
    'Texture_im_max'
    'Texture_im_absmean'
    'Texture_gradient_min_1'
    'Texture_gradient_min_2'
    'Texture_gradient_min_3'
    'Texture_gradient_max_1'
    'Texture_gradient_max_2'
    'Texture_gradient_max_3'
    'Texture_laplacian_min_1'
    'Texture_laplacian_min_2'
    'Texture_laplacian_min_3'
    'Texture_laplacian_max_1'
    'Texture_laplacian_max_2'
    'Texture_laplacian_max_3'
    'Texture_bg_mean'
    'Texture_bg_std'
    'Texture_bg_skew'
    'Texture_bg_min'
    'Texture_bg_max'
    'Texture_prevdiff_mean'
    'Texture_prevdiff_std'
    'Texture_prevdiff_skew'
    'Texture_prevdiff_min'
    'Texture_prevdiff_max'
    'Texture_prevdiff_absmean'
    'Texture_nextdiff_mean'
    'Texture_nextdiff_std'
    'Texture_nextdiff_skew'
    'Texture_nextdiff_min'
    'Texture_nextdiff_max'
    'Texture_nextdiff_absmean'};

oFeatures = [setdiff(TheriaultFeatures(), {'CentroidX'; 'CentroidY'})
    extra_texture_features
    'CenterDistance'
    'GradientComponent_tangential'
    'GradientComponent_radial'];
end