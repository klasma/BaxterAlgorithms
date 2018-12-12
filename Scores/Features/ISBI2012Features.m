function oFeatures = ISBI2012Features()
% The features set used in the the conference paper at ISBI 2012.
%
% The feature set consists of the 89 features that were used for tracking
% of muscle stem cells in [1]. The features are used for classification of
% cell counts, mitosis, and apoptosis in segmented blobs. The features are
% computed from both the pixels of the image and from the binary
% segmentation masks of the blobs. Some features are also computed from the
% difference between the current and the previous or the following image.
%
% Outputs:
% oFeautres - Cell array of strings with the feature names.
%
% References:
% [1] Magnusson, K. E. G. & Jaldén, J. A batch algorithm using iterative
%     application of the Viterbi algorithm to track cells and construct
%     cell lineages Proc. 2012 IEEE Int. Symp. Biomed. Imaging (ISBI),
%     2012, 382-385
%
% See also:
% TransmissionFeatures, ComputeFeatures, NecessaryFeatures,
% SubstituteFeatureNames, FeatureMatrix, Blob, Train, Classify

% Comments to the right of feature names are old feature names which refer
% to the same feature.

oFeatures = {...
    'Area'
    'AxisRatio'
    'CenterDistance'
    'Compactness'
    'ConvCompHeightMean'
    'ConvexArea'
    'ConvexAreaNorm'
    'ConvHeightMean'
    'ConvHeightNorm'
    'ConvVolMean'
    'Curvature'
    'DistTo_boundary_max'               % EdgeDistMax1
    'DistTo_boundary_mean'              % EdgeDistMean1
    'DistTo_center_mean'                % CenterDistMean1
    'DistTo_centroid_mean'              % CentroidDistMean1
    'EdgeDistMaxNorm'
    'EdgeDistMeanNorm'
    'GradientComponent_radial'          % RadGrad1
    'GradientComponent_tangential'      % TangGrad1
    'Height'
    'HeightMean'
    'IBoundary'
    'ICenter'
    'ICentroid'
    'IDistPower_inner_1'                % IInnerLinear
    'IDistPower_inner_2'                % IInnerSquare
    'IDistPower_inner_3'                % IInnerCube
    'IDistPower_outer_1'                % IOuterLinear
    'IDistPower_outer_2'                % IOuterSquare
    'IDistPower_outer_3'                % IOuterCube
    'IFraction_inner_100'               % IInner10
    'IFraction_inner_250'               % IInner25
    'IFraction_inner_50'                % IInner05
    'IFraction_inner_500'               % IInner50
    'IFraction_inner_750'               % IInner75
    'IFraction_outer_100'               % IOuter10
    'IFraction_outer_250'               % IOuter25
    'IFraction_outer_50'                % IOuter05
    'IFraction_outer_500'               % IOuter50
    'IFraction_outer_750'               % IOuter75
    'InvCompactness'
    'MeanDistBetween_abs_boundary_0'    % MeanDistToAbsIFromBoundary
    'MeanDistBetween_abs_boundary_1'    % MeanDistToAbsIFromBoundaryNorm
    'MeanDistBetween_abs_center_0'      % MeanDistToAbsIFromCenter
    'MeanDistBetween_abs_center_1'      % MeanDistToAbsIFromCenterNorm
    'MeanDistBetween_abs_centroid_0'    % MeanDistToAbsIFromCentroid
    'MeanDistBetween_abs_centroid_1'    % MeanDistToAbsIFromCentroidNorm
    'MeanDistBetween_neg_boundary_0'    % MeanDistToNegIFromBoundary
    'MeanDistBetween_neg_boundary_1'    % MeanDistToNegIFromBoundaryNorm
    'MeanDistBetween_neg_center_0'      % MeanDistToNegIFromCenter
    'MeanDistBetween_neg_center_1'      % MeanDistToNegIFromCenterNorm
    'MeanDistBetween_neg_centroid_0'    % MeanDistToNegIFromCentroid
    'MeanDistBetween_neg_centroid_1'    % MeanDistToNegIFromCentroidNorm
    'MeanDistBetween_pos_boundary_0'    % MeanDistToPosIFromBoundary
    'MeanDistBetween_pos_boundary_1'    % MeanDistToPosIFromBoundaryNorm
    'MeanDistBetween_pos_center_0'      % MeanDistToPosIFromCenter
    'MeanDistBetween_pos_center_1'      % MeanDistToPosIFromCenterNorm
    'MeanDistBetween_pos_centroid_0'    % MeanDistToPosIFromCentroid
    'MeanDistBetween_pos_centroid_1'    % MeanDistToPosIFromCentroidNorm
    'MeanDistBetween_val_boundary_0'    % MeanDistToIFromBoundary
    'MeanDistBetween_val_boundary_1'    % MeanDistToIFromBoundaryNorm
    'MeanDistBetween_val_center_0'      % MeanDistToIFromCenter
    'MeanDistBetween_val_center_1'      % MeanDistToIFromCenterNorm
    'MeanDistBetween_val_centroid_0'    % MeanDistToIFromCentroid
    'MeanDistBetween_val_centroid_1'    % MeanDistToIFromCentroidNorm
    'Perimeter'
    'PerimeterNorm'
    'Smoothness'
    'Texture_bg_absmean'                % IBgAbsMean
    'Texture_bg_max'                    % IBgMax
    'Texture_bg_mean'                   % IBgMean
    'Texture_bgvar_max'                 % BgVarMax
    'Texture_bgvar_mean'                % BgVarMean
    'Texture_gradient_mean'             % GradMagMean
    'Texture_im_absmean'                % IAbsMean
    'Texture_im_max'                    % IMax
    'Texture_im_mean'                   % IMean
    'Texture_im_min'                    % IMin
    'Texture_im_var'                    % PixelVariance
    'Texture_locvar_max'                % LocVarMax
    'Texture_locvar_mean'               % LocVarMean
    'Texture_nextdiff_absmean'          % INextDiffAbsMean
    'Texture_nextdiff_max'              % INextDiffMax
    'Texture_nextdiff_mean'             % INextDiffMean
    'Texture_nextdiff_min'              % INextDiffMin
    'Texture_prevdiff_absmean'          % IPrevDiffAbsMean
    'Texture_prevdiff_max'              % IPrevDiffMax
    'Texture_prevdiff_mean'             % IPrevDiffMean
    'Texture_prevdiff_min'              % IPrevDiffMin
    };
end