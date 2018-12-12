function [oList, oBlobSeq, oPHD] = MigrationScores_generic(aBlobSeq, aImData, varargin)
% Wrapper which computes migration scores using a user specified function.
%
% The function computes scores for possible migrations between blobs in
% consecutive frames. The scores are usually logarithms of posteriori
% probabilities for migrations under specific assumptions. The settings
% associated with the image sequence determine which function is used to
% compute the scores.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% CreateOutputFiles - If this parameter is set to true, the functions which
%                     compute the migration scores will not save any files
%                     to disk. Otherwise, some of them will save files in
%                     the resume-directory of the image sequence.
%
% Settings in aImData:
% TrackMigLogLikeList - The name of the function that should be used to
%                       compute the migration scores.
%
% Outputs:
% oList - N x 5 matrix, where N is the number of returned migrations.
%         The elements of the matrix are:
%    oList(:,1) - Frame index of the first blob in the migration.
%    oList(:,2) - Index of the detection in image oList(:,1).
%    oList(:,3) - Index of the detection in image oList(:,1)+1.
%    oList(:,4) - Score of the migration NOT occurring.
%    oList(:,5) - Score of the migration occurring.
% oBlobSeq - Blobs generated from the Gaussian components of a GM-PHD
%            filter. This output is only used when a GM-PHD filter is used
%            for preprocessing, as in MigLogLikeList_PHD_ISBI_tracks.
% oPHD - Array where each element is a measurement updated GM-PHD for the
%        corresponding time point. This output is only used when a GM-PHD
%        filter is used for preprocessing, as in
%        MigLogLikeList_PHD_ISBI_tracks.
%
% References:
% [1] Magnusson, K. E. G.; Jaldén, J.; Gilbert, P. M. & Blau, H. M. Global
%     linking of cell tracks using the Viterbi algorithm IEEE Trans. Med.
%     Imag., 2015, 34, 1-19
% [2] Sadanandan, S.K.; Baltekin, O.; Magnusson, K.E.G.; Boucharin, A.;
%     Ranefall, P.; Jalden, J.; Elf, J.; Wahlby, C., Segmentation and
%     Track-analysis in Time-lapse Imaging of Bacteria, IEEE Journal of
%     Selected Topics in Signal Processing , vol.PP, no.99, pp.1-1 doi:
%     10.1109/JSTSP.2015.2491304
%
% See also:
% MigLogLikeList_3D, MigLogLikeList_PHD_ISBI_tracks,
% MigLogLikeList_PHD_ISBI_IMM, MigLogLikeList_PHD_DRO,
% MigLogLikeList_uniformClutter, MigLogLikeList_viterbiPaper,
% MigLogLikeList_Jaccard, Track, ViterbiTrackLinking.cpp

% Parse property/value inputs.
aCreateOutputFiles = GetArgs({'CreateOutputFiles'}, {false}, true, varargin);

oBlobSeq = aBlobSeq;

switch aImData.Get('TrackMigLogLikeList')
    case 'MigLogLikeList_3D'
        % 3D equivalent of MigLogLikeList_uniformClutter.
        oList = MigLogLikeList_3D(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'));
    case 'MigLogLikeList_PHD_ISBI_tracks'
        % First tracks the targets using a GM-PHD filter and then defines
        % scores for migrations between the Gaussian components in the
        % target densities.
        [oList, oBlobSeq, oPHD] = MigLogLikeList_PHD_ISBI_tracks(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'),...
            'CreateOutputFiles', aCreateOutputFiles);
    case 'MigLogLikeList_PHD_ISBI_IMM'
        % The same as MigLogLikeList_PHD_ISBI_tracks, but with multiple
        % motion models.
        [oList, oBlobSeq, oPHD] = MigLogLikeList_PHD_ISBI_IMM(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'),...
            'CreateOutputFiles', aCreateOutputFiles);
    case 'MigLogLikeList_PHD_DRO'
        % Used to track cells in Drosophila embryos. As in
        % MigLogLikeList_PHD_ISBI_tracks, a GM-PHD filter is used for
        % pre-processing.
        [oList, oBlobSeq, oPHD] = MigLogLikeList_PHD_DRO(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'),...
            'CreateOutputFiles', aCreateOutputFiles);
    case 'MigLogLikeList_uniformClutter'
        % 2D function which assumes that clutter is uniformly distributed.
        oList = MigLogLikeList_uniformClutter(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'));
    case 'MigLogLikeList_viterbiPaper'
        % 2D function which matches what is currently described in [1].
        oList = MigLogLikeList_viterbiPaper(...
            aBlobSeq,...
            aImData,...
            aImData.Get('TrackNumNeighbours'));
    case 'MigLogLikeList_Jaccard'
        % Uses logarithms of Jaccard similarity indices between blob
        % outlines in different frames as scores, as described in [2].
        oList = MigLogLikeList_Jaccard(aBlobSeq);
    otherwise
        error('Unknown method for computing migration scores.')
end
end