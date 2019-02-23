function oList = MigLogLikeList_uniformClutter(aBlobSeq, aImData, aMaxArcs)
% Computes migration scores assuming a uniform clutter density.
%
% The function computes the log likelihoods of possible migrations between
% detections (blobs) in consecutive frames. Only the aMaxArcs most likely
% migrations in each direction are returned. This means that the aMaxArcs
% most likely migrations that move from a given detection and the aMaxArcs
% most likely migrations that end in a given detection are returned. A
% migration is only returned once, even if it is among the most likely
% outgoing migrations from one detection and among the most likely incoming
% migrations to another detection.
%
% As a motion model it is assumed that the x-velocity and the y-velocity
% are independent and distributed according to a Gaussian distribution with
% zero mean. The migration probabilities in one time step are assumed to be
% independent of the migration probabilities of other time steps. Clutter
% is assumed to follow a uniform distribution.
%
% Inputs:
% aBlobSeq - Cell array where cell t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - Image data object associated with the image sequence.
% aMaxArcs - The number of outgoing and incoming migrations considered for
%            every detection.
%
% Properties of aImData:
% TrackMotionModel - Name of mat-file with a saved covariance matrix of the
%                    x- and y- displacements from one frame to the next.
%                    Set this to 'none' to use Brownian motion instead.
% TrackXSpeedStd - Standard deviation of Brownian motion in x- and
%                  y-directions. This is used if no motion model has been
%                  defined.
%
% Outputs:
% oList - N x 5 matrix, where N is the number of returned migrations.
%         The elements of the matrix are:
%    oList(:,1) - Frame count of the first detection in the migration.
%    oList(:,2) - The index of the detection in image oList(:,1).
%    oList(:,3) - The index of the detection in image oList(:,1)+1.
%    oList(:,4) - Log likelihood of the migration NOT occurring.
%    oList(:,5) - Log likelihood of the migration occurring.
%
% See also:
% MigrationScores_generic, MigLogLikeList_3D

% Prior probability that a cell migrates away from any given detection.
MIGRATION_PRIOR = 0.8;  % TODO: FIND A WAY TO COMPUTE THIS.

area = aImData.imageWidth * aImData.imageHeight;

% Find covariance matrix for the x- and y-displacements between two frames.
if ~strcmpi(aImData.Get('TrackMotionModel'), 'none')
    % Saved covariance matrix.
    
    trackClassifierPath = FindFile('Classifiers', 'Migration',...
        aImData.Get('TrackMotionModel'));
    tmp = load(trackClassifierPath);
    E = tmp.covarianceMatrix;
    isotropicMotion = false;
else
    % Isotropic Brownian motion.
    
    % Standard deviations of x and y displacements in pixel units.
    rmsSpeed = aImData.Get('TrackXSpeedStd');
    E = rmsSpeed^2 * eye(2);
    isotropicMotion = true;
end

oList = [];
for t = 1:length(aBlobSeq)-1
    % Blobs in current image.
    allTBlobs1 = aBlobSeq{t};
    allPos1 = cat(1, allTBlobs1.centroid);
    
    % Blobs in next image.
    allTBlobs2 = aBlobSeq{t+1};
    allPos2 = cat(1, allTBlobs2.centroid);
    for xBin = 1:10
        for yBin = 1:10
            xMin1 = 0.5 + (xBin-1)*aImData.imageWidth/10;
            xMax1 = 0.5 + xBin*aImData.imageWidth/10;
            yMin1 = 0.5 + (yBin-1)*aImData.imageHeight/10;
            yMax1 = 0.5 + yBin*aImData.imageHeight/10;
            
            xMin2 = 0.5 + (xBin-2)*aImData.imageWidth/10;
            xMax2 = 0.5 + (xBin+1)*aImData.imageWidth/10;
            yMin2 = 0.5 + (yBin-2)*aImData.imageHeight/10;
            yMax2 = 0.5 + (yBin+1)*aImData.imageHeight/10;

            blobIndices1 = find(...
                allPos1(:,1) >= xMin2 & allPos1(:,1) < xMax2 &...
                allPos1(:,2) >= yMin2 & allPos1(:,2) < yMax2);
            tBlobs1 = allTBlobs1(blobIndices1);
            
            blobIndices2 = find(...
                allPos2(:,1) >= xMin2 & allPos2(:,1) < xMax2 &...
                allPos2(:,2) >= yMin2 & allPos2(:,2) < yMax2);
            tBlobs2 = allTBlobs2(blobIndices2);
            
            n1 = length(tBlobs1);
            n2 = length(tBlobs2);
            
            if isempty(tBlobs1) || isempty(tBlobs2)
                continue
            end
            
            posPrior = MIGRATION_PRIOR * 1/length(allTBlobs2);  % Prior for migration.
            negPrior = 1-posPrior;
            
            % Displacements.
            pos1 = cat(1, tBlobs1.centroid);
            X1 = repmat(pos1(:,1), 1, n2);
            Y1 = repmat(pos1(:,2), 1, n2);
            pos2 = cat(1, tBlobs2.centroid);
            X2 = repmat(pos2(:,1)', n1, 1);
            Y2 = repmat(pos2(:,2)', n1, 1);
            Dx = X2 - X1;
            Dy = Y2 - Y1;
            X = [Dx(:) Dy(:)]';
            
            % Compute probability density of the previously observed cell.
%             if isotropicMotion
%                 log_f_pos = -log(2*pi) - 2*log(rmsSpeed) - 1/2 * 1/rmsSpeed^2 * sum(X.*X);
%             else
                log_f_pos = -(size(E,1)/2)*log(2*pi) - 1/2*log(det(E)) - 1/2 * sum(X.*(E\X));
                %log_f_pos = -log(2*pi) - 1/2*log(det(E)) - 1/2 * sum(X.*(E\X));
%             end
            log_f_pos = reshape(log_f_pos, n1, n2);
            
            % Model probability density of other cells as a uniform distribution.
            log_f_neg = log(1/area)*ones(n1,n2);
            
            % Compute logarithm of posteriors using Bayes' rule. The computations
            % are done in the log-domain to avoid underflow.
            log_pos = log(posPrior) + log_f_pos;
            log_neg = log(negPrior) + log_f_neg;
            % Avoid log(0) if exp(log_p_pos) and exp(log_p_neg) are both 0.
            z = max(log_pos, log_neg);
            log_denominator = z + log(exp(log_pos-z) + exp(log_neg-z));
            neg_score = log_neg - log_denominator;
            pos_score = log_pos - log_denominator;
            
            % Fill the output matrix.
            [closest1, closest2] = NClosest(-(pos_score - neg_score), aMaxArcs);

            keep = allPos1(:,1) >= xMin1 & allPos1(:,1) < xMax1 &...
                allPos1(:,2) >= yMin1 & allPos1(:,2) < yMax1;
            keep = keep(blobIndices1(closest1));

            closest1 = closest1(keep);
            closest2 = closest2(keep);

            tList = nan(length(closest2),5);
            tList(:,1) = t;
            tList(:,2) = blobIndices1(closest1);
            tList(:,3) = blobIndices2(closest2);
            tList(:,4) = neg_score(sub2ind(size(neg_score), closest1, closest2));
            tList(:,5) = pos_score(sub2ind(size(neg_score), closest1, closest2));
            oList = [oList; tList]; %#ok<AGROW>
            fprintf('%d\n', sum(tList(:,1) == 1 & tList(:,2) == 16))
        end
    end
end

[~, order1] = sort(oList(:,2));
oList = oList(order1,:);
[~, order2] = sort(oList(:,3));
oList = oList(order2,:);
[~, order3] = sort(oList(:,1));
oList = oList(order3,:);