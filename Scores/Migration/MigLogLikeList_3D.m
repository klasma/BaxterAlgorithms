function oList = MigLogLikeList_3D(aBlobSeq, aImData, aMaxArcs)
% Computes migration log-likelihoods in 3D image stacks.
%
% The function computes the log-likelihoods of possible migrations
% between detections (blobs) in consecutive frames of 3D image stacks.
%
% In the motion model it is assumed that the x-, y-, and z-velocities
% are independent and distributed according to Gaussian distributions. The
% migration probabilities in one time step are assumed to be independent of
% the migration probabilities of other time steps. Clutter is assumed to
% follow a uniform distribution. The function is equivalent to
% MigLogLikeList_uniformClutter, but works on 3D images.
%
% Only the aMaxArcs most likely migrations in each time direction are
% returned. This means that the aMaxArcs most likely migrations that move
% from a given detection and the aMaxArcs most likely migrations that end
% in a given detection are returned. A migration is only returned once,
% even if it is among the most likely outgoing migrations from one
% detection and among the most likely incoming migrations to another
% detection.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - Image data object associated with the image sequence.
% aMaxArcs - The number of outgoing and incoming migrations considered for
%            every detection.
%
% Properties in aImData:
% TrackMotionModel - Name of mat-file where a mean and a covariance matrix
%                    of the x-, y-, and z-displacements have been saved.
%                    The mean and the covariance should be saved in
%                    variables named 'means' and 'covariance'. If
%                    'TrackMotionModel' is 'none' the mean will be set to 0
%                    and the covariance matrix will be defined by
%                    TrackXSpeedStd and TrackZSpeedStd.
% TrackXSpeedStd - Standard deviation of Brownian motion in the x- and
%                  y-dimensions. This value is used if TrackMotionModel has
%                  not been defined. The unit is pixels (voxel widths). If
%                  TrackXSpeedStd is a two element vector, the covariance
%                  matrix will be time-varying. In that case the first
%                  element defines the standard deviation in the first
%                  frame and the second element defined the standard
%                  deviation in the last frame. The standard deviation in
%                  intermediate frames are computed using linear
%                  interpolation.
% TrackZSpeedStd - Standard deviation of Brownian motion in the
%                  z-dimension. This value is used if TrackMotionModel has
%                  not been defined. The unit is pixels (voxel widths).
%                  This means that the motion will be isotropic if
%                  TrackXSpeedStd and TrackZSpeedStd are the same, even if
%                  the voxel height is different from the voxel width. A
%                  TrackXSpeedStd with two elements will make the
%                  covariance matrix time-varying, in the same way as
%                  TrackXSpeedStd.
%
% Outputs:
% oList - N x 5 matrix, where N is the number of returned migrations.
%         The elements of the matrix are:
%    oList(:,1) - Frame index of the first detection in the migration.
%    oList(:,2) - The index of the detection in image oList(:,1).
%    oList(:,3) - The index of the detection in image oList(:,1)+1.
%    oList(:,4) - Log-likelihood of the migration NOT occurring.
%    oList(:,5) - Log-likelihood of the migration occurring.
%
% See also:
% MigrationScores_generic, MigLogLikeList_uniformClutter

MIGRATION_PRIOR = 0.8;  % TODO: FIND A WAY TO COMPUTE THIS.

% Z-stack volume in voxels.
volume = aImData.imageWidth * aImData.imageHeight * aImData.numZ;

oList = [];
for t = 1:length(aBlobSeq)-1
    fprintf('Computing migration scores for image %d / %d.\n',...
        t, length(aBlobSeq)-1)
    
    % Compute the covariance matrix, which may depend on t.
    if ~strcmpi(aImData.Get('TrackMotionModel'), 'none')
        % Saved covariance matrix.
        motionModelPath = FindFile('Classifiers', 'MotionModels',...
            aImData.Get('TrackMotionModel'));
        tmp = load(motionModelPath);
        mu = tmp.means;
        E = tmp.covariance;
    else
        % Covariance matrix defined by TrackXSpeedStd and TrackZSpeedStd.
        
        if length(aImData.Get('TrackXSpeedStd')) == 2
            % The covariance matrix is an affine function of time.
            n = aImData.sequenceLength;
            if aImData.sequenceLength > 1
                trackXSpeedStd = aImData.Get('TrackXSpeedStd');
                xStd = trackXSpeedStd(1) * (n-t) / (n-1) +...
                    trackXSpeedStd(2) * (t-1) / (n-1);
            else
                xStd = mean(aImData.Get('TrackXSpeedStd'));
            end
        else
            % The covariance matrix is the same for all frames.
            xStd = aImData.Get('TrackXSpeedStd');
        end
        
        if length(aImData.Get('TrackZSpeedStd')) == 2
            % The covariance matrix is an affine function of time.
            n = aImData.sequenceLength;
            if aImData.sequenceLength > 1
                trackZSpeedStd = aImData.Get('TrackZSpeedStd');
                zStd = trackZSpeedStd(1) * (n-t) / (n-1) +...
                    trackZSpeedStd(2) * (t-1) / (n-1);
            else
                zStd = mean(aImData.Get('TrackZSpeedStd'));
            end
        else
            % The covariance matrix is the same for all frames.
            zStd = aImData.Get('TrackZSpeedStd');
        end
        
        % Standard deviations of x- and y-displacements in voxels widths.
        rmsXYSpeed = xStd;
        % Standard deviations of z-displacements in voxels widths.
        rmsZSpeed = zStd / aImData.voxelHeight;
        
        mu = zeros(3,1);
        E = diag([rmsXYSpeed rmsXYSpeed rmsZSpeed].^2);
    end
    
    tBlobs1 = aBlobSeq{t};
    tBlobs2 = aBlobSeq{t+1};
    n1 = length(tBlobs1);
    n2 = length(tBlobs2);
    
    if isempty(tBlobs1) || isempty(tBlobs2)
        continue
    end
    
    % Priors of migration and no migration.
    posPrior = MIGRATION_PRIOR * 1/length(tBlobs2);
    negPrior = 1-posPrior;
    
    % Displacements associated with the n1 x n2 possible migrations.
    pos1 = cat(1, tBlobs1.centroid);
    X1 = repmat(pos1(:,1), 1, n2);
    Y1 = repmat(pos1(:,2), 1, n2);
    Z1 = repmat(pos1(:,3), 1, n2);
    pos2 = cat(1, tBlobs2.centroid);
    X2 = repmat(pos2(:,1)', n1, 1);
    Y2 = repmat(pos2(:,2)', n1, 1);
    Z2 = repmat(pos2(:,3)', n1, 1);
    Dx = X2 - X1;
    Dy = Y2 - Y1;
    Dz = Z2 - Z1;
    X = [Dx(:) Dy(:) Dz(:)]';
    
    MU = repmat(mu,1,size(X,2));
    
    % Compute probability density of the cell in the previous frame.
    log_f_pos = -(size(E,1)/2)*log(2*pi) - 1/2*log(det(E)) -...
        1/2 * sum((X-MU).*(E\(X-MU)));
    log_f_pos = reshape(log_f_pos, n1, n2);
    
    % Compute probability density of other cells.
    log_f_neg = log(1/volume)*ones(n1,n2);  % Uniform distribution.
    
    % Compute logarithms of posteriors using Bayes' rule. The computations
    % are done in the log-domain to avoid underflow.
    log_pos = log(posPrior) + log_f_pos;
    log_neg = log(negPrior) + log_f_neg;
    % Avoid log(0) if exp(log_p_pos) and exp(log_p_neg) are both 0.
    z = max(log_pos, log_neg);
    log_denominator = z + log(exp(log_pos-z) + exp(log_neg-z));
    neg_score = log_neg - log_denominator;
    pos_score = log_pos - log_denominator;
    
    % Fill the output list.
    [closest1, closest2] = NClosest(-(pos_score - neg_score), aMaxArcs);
    tList = nan(length(closest2),5);
    tList(:,1) = t;
    tList(:,2) = closest1;
    tList(:,3) = closest2;
    tList(:,4) = neg_score(sub2ind(size(neg_score), closest1, closest2));
    tList(:,5) = pos_score(sub2ind(size(neg_score), closest1, closest2));
    oList = [oList; tList]; %#ok<AGROW>
end