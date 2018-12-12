function [oW, oM, oP, oZ] =...
    GMMmergeKLdiv(aW, aM, aP, aZ, aJmax, aW_thresh, aKLdiv_thresh)
% Reduces a Gaussian mixture based on KL-divergence between components.
%
% This function is used to reduce the number of components in Gaussian
% mixtures that are used for tracking in Gaussian Mixture Probability
% Hypothesis Density (GM-PHD) filters. The function will first remove
% components which have weights below a threshold. Then the components are
% gone through in order of decreasing weight. For the processed component,
% the Kullback-Leibler (KL) divergences are computed in both directions
% with the components that have lower weights. To reduce the processing
% time, only blob pairs where the spatial distance between the means is
% below 75 are considered for merging. All components for which the
% divergences are below a threshold in both directions are merged with the
% processed component. The weight of the new component is the sum of the
% weights of the merged components and the mean and the covariance of the
% new component is the same as the mean and the covariance of the mixture
% of the merged components. When all components have been processed, the
% components with the smallest weights are removed, so that the number of
% components does not exceed a threshold. This merging procedure is used in
% [1].
%
% Inputs:
% aW - Array with the weights of the components to be merged.
% aM - Matrix where the columns are means of the components to be merged.
% aP - 3D array where the 3D-slices are covariance matrices of the
%      components to be merged.
% aZ - Indices of the measurements (blobs) that were used to update the
%      components to be merged.
% aJmax - The maximum number of components in the merged mixture.
% aW_thresh - Threshold on the component weights. Components with smaller
%             weights are removed before merging.
% aKLdiv_thresh - Threshold on the KL-divergence. Component pairs where the
%                 maximum KL-divergence is below this threshold are merged.
%
% Outputs:
% oW - Array with weights of the components in the reduced mixture.
% oM - Matrix with means of the components in the reduced mixture.
% oP - 3D array with covariances of the components in the reduced mixture.
% oZ - Indices of the measurements (blobs) that were used to update the
%      components of the reduced mixture. In merges, the index of the blob
%      with the highest weight is used.
%
% References:
% [1] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian particles
%     using the Viterbi algorithm Proc. 2015 IEEE Int. Symp. Biomed.
%     Imaging (ISBI), 2015, 380-384
%
% See also:
% CellPHD, CellPHD_IMM

% Binary index vector of components that have been either processed or
% discarded.
used = aW <= aW_thresh;

oW = [];
oZ = [];
oM = [];
oP = [];

switch size(aM,1)
    case 2
        % 2D constant position.
        n_obs = 2;
    case 3
        % 3D constant position.
        n_obs = 3;
    case 4
        % 2D constant velocity.
        n_obs = 2;
    case 6
        % 3D constant velocity.
        n_obs = 3;
    otherwise
        error('The length of the state vectors need to be 2, 3, 4 or 6.')
end

% Pre-compute inverses and determinants.
invP = nan(size(aP));
detP = nan(size(aP,3),1);
for i = 1:size(aP,3)
    if ~used(i)
        invP(:,:,i) = inv(aP(:,:,i));
        detP(i) = det(aP(:,:,i));
    end
end

% Go through the components in order of decreasing weight and merge in
% nearby components.
while any(~used)
    [~, j] = max(aW .* (~used));
    
    dist2 = sum(( aM(1:n_obs,:) - repmat(aM(1:n_obs,j), 1, size(aM,2)) ).^2);
    
    % Compute the maximum KL-divergence with other components.
    kldiv = inf(1, length(aW));
    I = find(~used & dist2 <= 75^2);  % TODO: Do not use a hard coded threshold.
    for index = 1:length(I)
        i = I(index);
        
        K = size(aM,1);
        mi = aM(:,i);
        mj = aM(:,j);
        Ri = aP(:,:,i);
        Rj = aP(:,:,j);
        invRi = invP(:,:,i);
        invRj = invP(:,:,j);
        detRi = detP(i);
        detRj = detP(j);
        
        kldivij = 0.5 * ( trace(invRj*Ri) + (mj-mi)'*invRj*(mj-mi) - K - log(detRi/detRj) );
        kldivji = 0.5 * ( trace(invRi*Rj) + (mi-mj)'*invRi*(mi-mj) - K - log(detRj/detRi) );
        
        kldiv(i) = max(kldivij, kldivji);
    end
    
    % Components to be merged.
    L = find(kldiv <= aKLdiv_thresh);
    
    % Merge components so that the means and covariances are preserved.
    w_newest = sum(aW(L));
    [~, maxIndex] = max(aW(L));
    z_newest = aZ(L(maxIndex));  % Use the label with the largest weight.
    m_newest = aM(:,L) * aW(L)' / w_newest;
    R_newest = zeros(size(aM,1), size(aM,1));
    for index = 1:length(L)
        l = L(index);
        R_newest = R_newest + aW(l)/w_newest * (aP(:,:,l) +...
            (m_newest-aM(:,l)) * (m_newest-aM(:,l))');
    end
    
    oW = [oW w_newest]; %#ok<AGROW>
    oZ = [oZ z_newest]; %#ok<AGROW>
    oM = [oM m_newest]; %#ok<AGROW>
    oP = cat(3, oP, R_newest);
    
    used(L) = true;
end

% Sort the components on weight and keep the largest ones.
[~, order] = sort(oW, 'descend');
numKeep = min(length(oW), aJmax);
oW = oW(order(1:numKeep));
oZ = oZ(order(1:numKeep));
oM = oM(:,order(1:numKeep));
oP = oP(:,:,order(1:numKeep));
end