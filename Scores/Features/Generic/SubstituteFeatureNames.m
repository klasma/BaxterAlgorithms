function oNewFeatures = SubstituteFeatureNames(aOldFeatures)
% Substitutes old feature names that have been changed.
%
% This is done so that old classifiers can be used when a feature name is
% changed.
%
% Inputs:
% aOldFeatures - Cell array of feature names which may contain old feature
%                names.
%
% Outputs:
% oNewFeatures - Cell array where the old feature names (aliases) have been
%                replaced by new feature names.
%
% See also:
% NecessaryFeatures, FeatureMatrix

oNewFeatures = aOldFeatures;

% Locate old feature names and replace them.
oNewFeatures(strcmpi(oNewFeatures, 'EdgeDistMean'))                     = {'DistTo_boundary_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'TangGrad'))                         = {'GradientComponent_tangential'};
oNewFeatures(strcmpi(oNewFeatures, 'IMax'))                             = {'Texture_im_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IInner05'))                         = {'IFraction_inner_50'};
oNewFeatures(strcmpi(oNewFeatures, 'INextDiffMax'))                     = {'Texture_nextdiff_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IPrevDiffAbsMean'))                 = {'Texture_prevdiff_absmean'};
oNewFeatures(strcmpi(oNewFeatures, 'IAbsMean'))                         = {'Texture_im_absmean'};
oNewFeatures(strcmpi(oNewFeatures, 'IBgMax'))                           = {'Texture_bg_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IMean'))                            = {'Texture_im_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'RadGrad'))                          = {'GradientComponent_radial'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuter05'))                         = {'IFraction_outer_50'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuterCube'))                       = {'IDistPower_outer_3'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuterSquare'))                     = {'IDistPower_outer_2'};
oNewFeatures(strcmpi(oNewFeatures, 'IPrevDiffMin'))                     = {'Texture_prevdiff_min'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromCenterNorm'))     = {'MeanDistBetween_neg_center_1'};
oNewFeatures(strcmpi(oNewFeatures, 'PixelVariance'))                    = {'Texture_im_var'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromCentroid'))       = {'MeanDistBetween_neg_centroid_0'};
oNewFeatures(strcmpi(oNewFeatures, 'LocVarMean'))                       = {'Texture_locvar_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'IInner10'))                         = {'IFraction_inner_100'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromCentroidNorm'))   = {'MeanDistBetween_abs_centroid_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromCentroidNorm'))   = {'MeanDistBetween_pos_centroid_1'};
oNewFeatures(strcmpi(oNewFeatures, 'LocVarMax'))                        = {'Texture_locvar_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IBgAbsMean'))                       = {'Texture_bg_absmean'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromCenter'))         = {'MeanDistBetween_abs_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromCentroid'))       = {'MeanDistBetween_pos_centroid_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromBoundaryNorm'))   = {'MeanDistBetween_pos_centerboundary_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromBoundaryNorm'))   = {'MeanDistBetween_neg_centerboundary_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromCentroid'))       = {'MeanDistBetween_abs_centroid_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromCenterNorm'))     = {'MeanDistBetween_abs_center_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromCenterNorm'))     = {'MeanDistBetween_pos_center_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromBoundary'))       = {'MeanDistBetween_abs_boundary_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToAbsIFromBoundaryNorm'))   = {'MeanDistBetween_abs_boundary_1'};
oNewFeatures(strcmpi(oNewFeatures, 'CenterDistMean'))                   = {'DistTo_center_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'EdgeDistMax'))                      = {'DistTo_boundary_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IBgMean'))                          = {'Texture_bg_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'IInner50'))                         = {'IFraction_inner_500'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuter50'))                         = {'IFraction_outer_500'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuter75'))                         = {'IFraction_outer_750'};
oNewFeatures(strcmpi(oNewFeatures, 'IInner25'))                         = {'IFraction_inner_250'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuter25'))                         = {'IFraction_outer_250'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromBoundary'))       = {'MeanDistBetween_neg_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromCentroidNorm'))   = {'MeanDistBetween_neg_centroid_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToNegIFromCenter'))         = {'MeanDistBetween_neg_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'CentroidDistMean'))                 = {'DistTo_centroid_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'IInner75'))                         = {'IFraction_inner_750'};
oNewFeatures(strcmpi(oNewFeatures, 'IMin'))                             = {'Texture_im_min'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromBoundary'))       = {'MeanDistBetween_pos_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'IPrevDiffMax'))                     = {'Texture_prevdiff_max'};
oNewFeatures(strcmpi(oNewFeatures, 'IInnerCube'))                       = {'IDistPower_inner_3'};
oNewFeatures(strcmpi(oNewFeatures, 'INextDiffMean'))                    = {'Texture_nextdiff_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'IInnerSquare'))                     = {'IDistPower_inner_2'};
oNewFeatures(strcmpi(oNewFeatures, 'IPrevDiffMean'))                    = {'Texture_prevdiff_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuter10'))                         = {'IFraction_outer_100'};
oNewFeatures(strcmpi(oNewFeatures, 'IOuterLinear'))                     = {'IDistPower_outer_1'};
oNewFeatures(strcmpi(oNewFeatures, 'INextDiffMin'))                     = {'Texture_nextdiff_min'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToPosIFromCenter'))         = {'MeanDistBetween_pos_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromCenter'))            = {'MeanDistBetween_val_center_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromCentroidNorm'))      = {'MeanDistBetween_val_centroid_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromBoundary'))          = {'MeanDistBetween_val_boundary_0'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromBoundaryNorm'))      = {'MeanDistBetween_val_boundary_1'};
oNewFeatures(strcmpi(oNewFeatures, 'INextDiffAbsMean'))                 = {'Texture_nextdiff_absmean'};
oNewFeatures(strcmpi(oNewFeatures, 'IInnerLinear'))                     = {'IDistPower_inner_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromCenterNorm'))        = {'MeanDistBetween_val_center_1'};
oNewFeatures(strcmpi(oNewFeatures, 'MeanDistToIFromCentroid'))          = {'MeanDistBetween_val_centroid_0'};
oNewFeatures(strcmpi(oNewFeatures, 'BgVarMean'))                        = {'Texture_bgvar_mean'};
oNewFeatures(strcmpi(oNewFeatures, 'BgVarMax'))                         = {'Texture_bgvar_max'};

end