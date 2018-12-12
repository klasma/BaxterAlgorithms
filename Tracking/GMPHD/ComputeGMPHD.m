function oPHD_u = ComputeGMPHD(aBlobSeq, aImData, varargin)
% Runs a GM-PHD filter on blobs from an image sequence.
%
% The GM-PHD filter is applied to the centroids of the blobs, and the
% function returns the updated hypothesis densities for each time point.
% The function is intended for tracking of particles in the ISBI 2012
% Particle Tracking Challenge and for tracking of nuclei in Drosophila
% embryos in the ISBI 2015 Cell Tracking Challenge. The computed GM-PHD in
% each image is saved, so that they can be loaded if the processing needs
% to be resumed later.
%
% Inputs:
% aBlobSeq - Cell array where each cell contains an array blobs segmented
%            in the corresponding image.
% aImData - ImageData object of the image sequence.
%
% Property/Value inputs:
% CreateOutputFiles - If this parameter is set to true, the function will
%                     not save any files to disk. This is a requirement in
%                     the cell tracking challenges.
%
% Outputs:
% oPHD_u - Array where each element is a measurement updated GM-PHD for one
%          time point.
%
% See also:
% ComputeGMPHD_IMM, Track, MigLogLikeList_PHD_ISBI_tracks,
% MigLogLikeList_PHD_DRO, Parameters_GMPHD

% Parse property/value inputs.
aCreateOutputFiles =...
    GetArgs({'CreateOutputFiles'}, {true}, true, varargin);

params = Parameters_GMPHD(aImData);

% Do the GM-PHD recursion to estimate the state vectors of all blobs.

% Process the first time point.
filename = fullfile(...
    aImData.GetResumePath(),...
    'GM-PHD',...
    sprintf('phd%04d.mat', 1));
if exist(filename, 'file')
    % Load a previously saved PHD.
    tmp = load(filename);
    phd_u(1) = tmp.updatedPHD;
    phd_p(1) = tmp.propagatedPHD;
else
    phd_p(1) = params.gamma_start;  % First birth event.
    phd_u(1) = phd_p(1).Update(aBlobSeq{1}, params);
    phd_u(1) = phd_u(1).Prune(params);
    
    if aCreateOutputFiles
        % Save the updated phd to a file.
        propagatedPHD = phd_p(1); %#ok<NASGU>
        updatedPHD = phd_u(1); %#ok<NASGU>
        if ~exist(fileparts(filename), 'dir')
            mkdir(fileparts(filename))
        end
        save(filename, 'propagatedPHD', 'updatedPHD')
    end
end

% Process the remaining time points.
for t = 2:aImData.sequenceLength
    % Un-commenting the plots will show level sets of the predicted PHD in
    % blue, the PHD after the measurement update in green and the reduced
    % (pruned) PHD in red.
    
    %         figure();
    %         ax = axes();
    %         imshow(aImData.GetShownImage(t))
    %         hold on
    
    filename = fullfile(...
        aImData.GetResumePath(),...
        'GM-PHD',...
        sprintf('phd%04d.mat', t));
    
    if exist(filename, 'file')
        % Load a previously saved PHD.
        tmp = load(filename);
        phd_u(t) = tmp.updatedPHD; %#ok<AGROW>
        phd_p(t) = tmp.propagatedPHD; %#ok<AGROW>
    else
        fprintf('Iteration %d, the phd has %d components\n', t, phd_u(t-1).J)
        phd_p(t) = phd_u(t-1).Propagate(params); %#ok<AGROW>
        phd_p(t) = phd_p(t) + params.gamma; %#ok<AGROW>
        phd_u(t) = phd_p(t).Update(aBlobSeq{t}, params); %#ok<AGROW>
        %     phd_u(t).PlotContour(params, ax, 1:aImData.imageHeight, 1:aImData.imageWidth, 'g')
        phd_u(t) = phd_u(t).Prune(params); %#ok<AGROW>
        
        %     phd_p(t).PlotContour(params, ax, 1:aImData.imageHeight, 1:aImData.imageWidth, 'b')
        %     phd_u(t).PlotContour(params, ax, 1:aImData.imageHeight, 1:aImData.imageWidth, 'r')
        
        if aCreateOutputFiles
            % Save the PHDs to a file.
            propagatedPHD = phd_p(t); %#ok<NASGU>
            updatedPHD = phd_u(t); %#ok<NASGU>
            save(filename, 'propagatedPHD', 'updatedPHD')
        end
    end
end

% Remove Gaussian components from birth events if they were not detected.
for t = 1:length(phd_u)
    phd_u(t).RemoveUndetected();
end

oPHD_u = phd_u;
end