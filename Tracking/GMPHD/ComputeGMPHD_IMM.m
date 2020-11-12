function oPHD_u = ComputeGMPHD_IMM(aBlobSeq, aImData)
% Runs a GM-PHD filter with an IMM motion model on a set of blobs.
%
% A constant position motion model is combined with a constant velocity
% motion model using CellPHD_IMM. The GM-PHD filter is applied to the
% centroids of the blobs, and the function returns the updated hypothesis
% densities for each time point. The function is intended for tracking of
% particles in the ISBI 2012 Particle Tracking Challenge. The computed
% GM-PHD in each image is saved, so that they can be loaded if the
% processing needs to be resumed later.
%
% Inputs:
% aBlobSeq - Cell array where each cell has a vector of blobs segmented in
%            the corresponding image.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oPHD_u - Array where each element is a measurement updated GM-PHD for one
%          time point. The Gaussian components with the constant position
%          motion model are placed before the components with the constant
%          velocity model.
%
% See also:
% ComputeGMPHD, Track, MigLogLikeList_PHD_ISBI_IMM, Parameters_GMPHD

% Make a copy so that the input object is not changed.
imData = aImData.Clone();

% Parameters for the constant position (Brownian) motion model.
imData.Set('TrackGMModel', 'ConstantPosition');
params1 = Parameters_GMPHD(imData);

% Half of the entering particles will have motion model 1.
params1.gamma.w(2:end) = params1.gamma.w(2:end) / 2;
params1.Jmax = floor(params1.Jmax / 2);

% Parameters for the constant velocity motion model.
imData.Set('TrackGMModel', 'ConstantVelocity');
params2 = Parameters_GMPHD(imData);

% No particles in the first image have motion model 2.
params2.gamma_start.w = zeros(size(params2.gamma_start.w));
params2.gamma.w = zeros(size(params2.gamma.w));
% Half of the entering particles will have motion model 2.
params2.gamma.w(2:end) = params2.gamma.w(2:end) / 2;
params2.Jmax = floor(params2.Jmax / 2);

% Transition matrix for the Markov chain which determines the motion model.
transMat = [0.9 0.1; 0.15 0.85];

phd_start = CellPHD_IMM(params1, params2, transMat);

% Deal with the first image separately.
filename = fullfile(...
    imData.GetResumePath(),...
    'GM-PHD',...
    sprintf('phd%04d.mat', 1));
if exist(filename, 'file')
    % Load a previously saved PHD.
    tmp = load(filename);
    phd_u(1) = tmp.updatedPHD;
    phd_p(1) = tmp.propagatedPHD;
else
    phd_p(1) = phd_start.Gamma_start();  % First birth event.
    phd_u(1) = phd_p(1).Update(aBlobSeq{1});
    phd_u(1) = phd_u(1).Prune();
    
    % Save the updated phd to a file.
    propagatedPHD = phd_p(1);
    updatedPHD = phd_u(1);
    if ~exist(fileparts(filename), 'dir')
        mkdir(fileparts(filename))
    end
    save(filename, 'propagatedPHD', 'updatedPHD')
end

% Process the remaining images.
for t = 2:length(aBlobSeq)
    filename = fullfile(...
        imData.GetResumePath(),...
        'GM-PHD',...
        sprintf('phd%04d.mat', t));
    
    if exist(filename, 'file')
        % Load a previously saved PHD.
        tmp = load(filename);
        phd_u(t) = tmp.updatedPHD; %#ok<AGROW>
        phd_p(t) = tmp.propagatedPHD; %#ok<AGROW>
    else
        fprintf('Iteration %d, the phd has %d components\n', t, phd_u(t-1).J)
        phd_p(t) = phd_u(t-1).Propagate(); %#ok<AGROW>
        phd_p(t) = phd_p(t) + phd_start.Gamma(); %#ok<AGROW>
        phd_u(t) = phd_p(t).Update(aBlobSeq{t}); %#ok<AGROW>
        phd_u(t) = phd_u(t).Prune(); %#ok<AGROW>
        
        % Save the updated phd to a file.
        propagatedPHD = phd_p(t);
        updatedPHD = phd_u(t);
        save(filename, 'propagatedPHD', 'updatedPHD')
    end
end

% Remove Gaussian components from birth events if they were not detected.
for t = 1:length(phd_u)
    phd_u(t).RemoveUndetected();
end

oPHD_u = phd_u;
end