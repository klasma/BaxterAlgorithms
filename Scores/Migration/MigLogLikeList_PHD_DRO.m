function [oList, oBlobSeq, oPHD] =...
    MigLogLikeList_PHD_DRO(aBlobSeq, aImData, aMaxArcs, varargin)
% Computes migration scores for tracking of Drosophila nuclei with GM-PHDs.
%
% This function was used for tracking of fluorescent nuclei in a Drosophila
% melanogaster embryo, in the third Cell Tracking Challenge at ISBI 2015.
% The function is very similar to MigLogLikeList_PHD_ISBI_tracks, which is
% used for tracking of particles in the ISBI 2012 Particle Tracking
% Challenge. The main difference between the functions is that an error in
% the density of detections from other targets has been corrected in this
% file. Another difference is that the hard coded maximum migration
% distance has been increased from 15 to 30 pixels. Hopefully, this
% function and MigLogLikeList_PHD_ISBI_tracks can be replaced by a single
% file in the future.
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
%                     is false.
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
%            point.
% oPHD - Array where each element is a measurement updated GM-PHD for one
%        time point.
%
% See also:
% MigLogLikeList_PHD_ISBI_tracks, MigLogLikeList_generic, ComputeGMPHD,
% Track
%
% TODO:
% Replace this file and MigLogLikeList_PHD_ISBI_tracks by a single file.

% Parse property/value inputs.
aCreateOutputFiles =...
    GetArgs({'CreateOutputFiles'}, {false}, true, varargin);

% Run GM-PHD filtering.
oPHD = ComputeGMPHD(aBlobSeq, aImData,...
    'CreateOutputFiles', aCreateOutputFiles);

% Create blobs from the components of the GM-PHD filter. The outlines are
% thrown away.
oBlobSeq = cell(length(oPHD),1);
for t = 1:length(oPHD)
    w = oPHD(t).w;
    z = oPHD(t).z;
    m = oPHD(t).m;
    for i = 1:size(m,2)
        b = Blob(struct(...
            'BoundingBox', nan(1,aImData.GetDim()*2),...
            'Image', nan,...
            'Centroid', m(1:aImData.GetDim(),i)'),...
            't', t,...
            'index', i,...
            'features', struct('weight', w(i)));
        
        % Assign a super-blob.
        if isnan(z(i))
            % No detection was used to update the object. A point blob is
            % used as super-blob.
            b = b.CreateSub();
            b.super.index = nan;
        else
            % Use the detection that gave rise to the object.
            b.super = aBlobSeq{t}(z(i));
        end
        
        oBlobSeq{t} = [oBlobSeq{t} b];
    end
end

% Image volume in voxels.
volume = aImData.imageWidth * aImData.imageHeight * aImData.numZ;

% Parameters for the GM-PHD recursion.
params = Parameters_GMPHD(aImData);
% Kalman filter parameters.
F = params.F;
Q = params.Q;
n_obs = size(params.H,1);

% Compute probabilities for migration between pairs of Gaussian components.
oList = [];
for t = 1:length(aBlobSeq)-1
    fprintf('Computing migration scores for image %d / %d.\n',...
        t, length(aBlobSeq)-1)
    
    phd1 = oPHD(t);       % PHD in frame t.
    phd2 = oPHD(t+1);     % PHD in frame t+1.
    
    n1 = length(phd1.w);  % The number of Gaussian components in frame t.
    n2 = length(phd2.w);  % The number of Gaussian components in frame t+1.
    
    if n1 == 0 || n2 == 0
        continue
    end
    
    % Prior for migration to a particular Gaussian component in frame t+1.
    prior_pos = 1/n2;
    % Prior that that migration does not occur.
    prior_neg = 1-prior_pos;
    
    % Compute the migration probabilities one at a time.
    pos_score = -inf(n1,n2);
    for i = 1:n1
        % Propagate the mean one time step forward in time.
        eta = F * phd1.m(:,i);
        % Propagate the covariance one time step forward.
        P = Q + F * phd1.P(:,:,i) * F';
        
        % Exclude all migrations longer than 30 pixels to save computation.
        dist2 = sum((phd2.m(1:n_obs,:) -...
            repmat(phd1.m(1:n_obs,i),1,phd2.J)).^2);
        candidates = find(dist2 <= 30^2);
        
        for candIndex = 1:length(candidates)
            j = candidates(candIndex);
            
            % PHD intensity of other particles.
            switch phd2.n
                case {2 3}  % constant position
                    f_neg = 1 / volume;
                case {4 6}  % constant velocity
                    % The velocity of other targets has the same
                    % distribution as appearing targets.
                    % TODO: Try to replace 5 by aImData.Get('TrackGMStdV').
                    if phd2.n == 4
                        S_vel = 5^2 * eye(2);
                    else
                        S_vel = 5^2 * diag([1 1 1/aImData.voxelHeight^2]);
                    end
                    f_neg = 1 / volume *...
                        GaussPDF(phd2.m(n_obs+1:2*n_obs,j), zeros(n_obs,1), S_vel);
                otherwise
                    error('The state vector must have 2, 3, 4 or 6 elements.')
            end
            
            % Add covariance related to measurement uncertainty.
            S = P + phd2.P(:,:,j);
            % Probability density given the migration.
            f_pos = GaussPDF(phd2.m(:,j), eta, S);
            
            % Log of probability of migration.
            pos_score(i,j) = log(f_pos*prior_pos)...
                - log(f_pos*prior_pos + f_neg*prior_neg);
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