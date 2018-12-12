function [oList, oBlobSeq, oPHD] =...
    MigLogLikeList_PHD_ISBI_IMM(aBlobSeq, aImData, aMaxArcs, varargin)
% Computes migration scores using GM-PHD filtering with an IMM-model.
%
% In the IMM-model, the particles switch between a constant position model
% and a constant velocity model. The migration probabilities are computed
% in the same way as in MigLogLikeList_PHD_ISBI_tracks, when the Gaussian
% components in frame t and t+1 are from the same motion model. If the
% Gaussian components are from different motion models, the component in
% frame t is converted so that it can be compared to the component in image
% t+1.Gaussian. This method to compute migration scores is described in
% [1].
%
% Inputs:
% aBlobSeq - Cell array where cell t contains an array with all Blob
%            objects created through segmentation of frame t.
% aImData - ImageData object associated with the image sequence.
% aMaxArcs - The number of outgoing and incoming migrations considered for
%            every Gaussian component in a GM-PHD.
%
% Property/Value inputs:
% CreateOutputFiles - If this parameter is set to true, the function will
%                     save the computed list of migration scores to the
%                     mat-file migrations.mat in the resume folder. This
%                     file can be used for development, but is not
%                     necessary for further processing. The default value
%                     is true.
%
% Outputs:
% oList - N x 5 matrix, where N is the number of returned migrations.
%         The elements of the matrix are:
%    oList(:,1) - Frame index of the first Gaussian component in the
%                 migration.
%    oList(:,2) - Index of the Gaussian component in image oList(:,1).
%    oList(:,3) - Index of the Gaussian component in image oList(:,1)+1.
%    oList(:,4) - Log likelihood of the migration NOT occurring.
%    oList(:,5) - Log likelihood of the migration occurring.
% oBlobSeq - Cell array of blobs generated from the Gaussian components of
%            the GM-PHD filter. Each cell contains the blobs of one time
%            point. The Blob objects are placed in the same order as the
%            corresponding Gaussian components in the GM-PHDs of oPHD.
% oPHD - Array where each element is a measurement updated GM-PHD for one
%        time point. Each GM-PHD is a CellPHD_IMM object which combines
%        motion models for constant position and constant velocity. The
%        Gaussian components with the constant position motion model are
%        placed before the components with the constant velocity model.
%
% References:
% [1] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian particles
%     using the Viterbi algorithm Proc. 2015 IEEE Int. Symp. Biomed.
%     Imaging (ISBI), 2015, 380-384
%
% See also:
% MigrationScores_generic, MigLogLikeList_PHD_ISBI_tracks,
% ComputeGMPHD_IMM, Track

% Parse property/value inputs.
aCreateOutputFiles =...
    GetArgs({'CreateOutputFiles'}, {false}, true, varargin);

% Perform GM-PHD filtering.
oPHD = ComputeGMPHD_IMM(aBlobSeq, aImData);

% Create blobs from the components of the GM-PHD filter. The outlines are
% thrown away. The arrays of blob objects for the different images are
% sorted so that the blobs from the constant position motion model come
% first, and so that the blobs from a motion model come in the same order
% as the Gaussian components from the corresponding GM-PHD.
oBlobSeq = cell(length(oPHD),1);
for t = 1:length(oPHD)
    for p = 1:2
        phd = oPHD(t).GetPHD(p);
        w = phd.w;
        z = phd.z;
        m = phd.m;
        for i = 1:phd.J
            b = Blob(struct(...
                'BoundingBox', nan(1,aImData.GetDim()*2),...
                'Image', nan,...
                'Centroid', m(1:aImData.GetDim(),i)'),...
                'features', struct('weight', w(i), 'detection', z(i)),...
                'index', i);
            
            % Assign a super-blob.
            if isnan(z(i))
                % No detection was used to update the object. A point blob
                % is used as super-blob.
                b = b.CreateSub();
                b.super.index = nan;
            else
                % Use the detection that gave rise to the object.
                b.super = aBlobSeq{t}(z(i));
            end
            
            oBlobSeq{t} = [oBlobSeq{t} b];
        end
    end
end

% Image volume in voxels.
volume = aImData.imageWidth * aImData.imageHeight * aImData.numZ;

% Compute probabilities for migration between pairs of Gaussian components.
oList = [];
for t = 1:length(aBlobSeq)-1
    fprintf('Computing migration scores for image %d / %d.\n',...
        t, length(aBlobSeq)-1)
    
    pos_score = -inf(oPHD(t).J, oPHD(t+1).J);
    for p2 = 1:2
        phd2 = oPHD(t+1).GetPHD(p2);  % PHD in frame t+1.
        n2 = phd2.J;  % The number of Gaussian components in frame t+1.
        if n2 == 0
            continue
        end
        
        % Offset which will be added to j, the index of the blob in frame
        % t+1, because j indexes a single motion model while the blobs
        % come from 2 different motion models.
        if p2 == 1
            offset2 = 0;
        else
            offset2 = oPHD(t+1).GetPHD(1).J;
        end
        
        % Parameters for the GM-PHD recursion.
        params = oPHD(t).GetParams(p2);
        % Kalman filter parameters.
        F = params.F;
        Q = params.Q;
        n_obs = size(params.H,1);
        
        for p1 = 1:2
            
            phd1 = oPHD(t).GetPHD(p1);  % PHD in frame t.
            n1 = phd1.J;  % The number of Gaussian components in frame t.
            if n1 == 0
                continue
            end
            
            % Offset which will be added to i, the index of the blob in
            % frame t, because i indexes a single motion model while the
            % blobs come from 2 different motion models.
            if p1 == 1
                offset1 = 0;
            else
                offset1 = oPHD(t).GetPHD(1).J;
            end
            
            if p1 ~= p2
                % Convert the first Gaussian component so that it can be
                % compared to the second component. This assumes that a
                % switch in motion model takes place.
                phd1 = phd1.Convert(params);
            end
            
            % Prior for migration to a particular Gaussian component in
            % frame t+1.
            prior_pos = oPHD(t).transMat(p1,p2) / oPHD(t+1).J;
            % Prior that that migration does not occur.
            prior_neg = 1-prior_pos;
            
            % Compute the migration probabilities one at a time.
            for i = 1:n1
                % Propagate the mean one step forward in time.
                eta = F * phd1.m(:,i);
                % Propagate the covariance one step forward in time.
                P = Q + F * phd1.P(:,:,i) * F';
                
                % Exclude all migrations longer than 15 pixels to save
                % computation.
                dist2 = sum((phd2.m(1:n_obs,:)...
                    - repmat(phd1.m(1:n_obs,i),1,phd2.J)).^2);
                candidates = find(dist2 <= 15^2);
                
                for candIndex = 1:length(candidates)
                    j = candidates(candIndex);
                    
                    % PHD intenstiy of other particles.
                    switch phd2.n
                        case {2 3}  % constant position
                            f_neg = 1 / volume;  % PHD intensity of clutter.
                        case {4 6}  % constant velocity
                            % The velocity of other targets has the same
                            % distribution as appearing targets.
                            if phd2.n == 4
                                S_vel = P(n_obs+1:end,n_obs+1:end)...
                                    + aImData.Get('TrackGMStdV')^2 * eye(2);
                            else
                                S_vel = P(n_obs+1:end,n_obs+1:end) +...
                                    aImData.Get('TrackGMStdV')^2 *...
                                    diag([1 1 1/aImData.voxelHeight^2]);
                            end
                            f_neg = 1 / volume *...
                                GaussPDF(phd2.m(n_obs+1:end,j), zeros(n_obs,1), S_vel);
                        otherwise
                            error('The state vector must have 2, 3, 4 or 6 elements.')
                    end
                    
                    % Add covariance related to measurement uncertainty.
                    S = P + phd2.P(:,:,j);
                    % Probability density given the migration.
                    f_pos = GaussPDF(phd2.m(:,j), eta, S);
                    
                    % Log of probability of migration.
                    pos_score(i+offset1,j+offset2) = log(f_pos*prior_pos)...
                        - log(f_pos*prior_pos + f_neg*prior_neg);
                end
            end
        end
    end
    % Fill the output matrix.
    [closest1, closest2] = NClosest(-pos_score, aMaxArcs);
    tList = nan(length(closest2),5);
    tList(:,1) = t;
    tList(:,2) = closest1;
    tList(:,3) = closest2;
    tList(:,4) = 0;
    tList(:,5) = pos_score(sub2ind(size(pos_score), closest1, closest2));
    oList = [oList; tList]; %#ok<AGROW>
end

if ~isempty(oList)
    % Remove rows where the scores are too low.
    oList(oList(:,5)<-100, :) = [];
end

if aCreateOutputFiles
    % Save the migration probabilities.
    filename = fullfile(aImData.GetResumePath(), 'migrations.mat');
    migrations = oList; %#ok<NASGU>
    save(filename, 'migrations')
end
end