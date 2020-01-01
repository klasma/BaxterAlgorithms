function TrainDROWeightClassifiers(aSeqPath, aVer, aGtVer)
% Trains count classifiers for CTC15 Drosophila tracking.
%
% The classifier will convert weights of Gaussian components in a GM-PHD
% filter into probabilities that the components correspond to real
% particles.
%
% Syntax:
% TrainWeightClassifiers(aSeqPath, aVer, aGtVer)
%
% Inputs:
% aSeqPath - Full path of the image sequence.
% aVer - Tracking version for which a GM-PHD has been saved.
% aGtVer - Ground truth version, with exact positions. This must not be a
%          ground truth version where the segmentation has been changed, as
%          the positions are no longer exact.
%
% Comments are up to date.

imData = ImageData(aSeqPath);
phdPath = fullfile(imData.GetResumePath('Version', aVer), 'GM-PHD');
T = imData.sequenceLength;

% Load all the PHDs.
phds = [];
for t = 1:T
    fprintf('Loading file %d / %d\n', t, T)
    filename = fullfile(phdPath, sprintf('phd%04d', t));
    tmp = load(filename);
    phd = tmp.updatedPHD;
    phd.RemoveUndetected;
    if isa(phd, 'CellPHD_IMM')
        phd1 = phd.GetPHD(1);
        phd2 = phd.GetPHD(2).Convert(phd.GetParams(1));
        phds = [phds phd1+phd2];
    else
        phds = [phds phd];
    end
end

% Load the ground truth particles.
gtCells = LoadCells(aSeqPath, aGtVer);

% Threshold corresponding to a uniform distribution over the image.
threshold = 1/(imData.imageHeight*imData.imageWidth);

% Compute the intensities of all Gaussian components in the true particle
% coordinates and pick out the component with the highest intensity for
% each particle. The component with the highest intensity is always picked
% first and then removed so that other particles can not be associated with
% the same component.
matches = cell(T,1);  % Indices of components that correspond to real particles.
for t = 1:T
    fprintf('Processing image %d / %d\n', t, T)
    
    phd = phds(t);
    aliveCells = AliveCells(gtCells, t);
    
    % Compute all intensities.
    intensities = zeros(length(aliveCells), phd.J);
    for i = 1:length(aliveCells)
        c = aliveCells(i);
        imDim = imData.GetDim();
        if imDim == 2
            x = [c.GetCx(t) c.GetCy(t)];
        else
            x = [c.GetCx(t) c.GetCy(t) c.GetCz(t)];
        end
        intensities(i,:) = phd.w .* mvnpdf(repmat(x,phd.J,1), phd.m(1:imDim,:)', phd.P(1:imDim,1:imDim,:))';
    end
    
    % Match the components to particles until there are no more components
    % with intensities above the threshold.
    [maxIntensities, maxIndices] = max(intensities,[],2);
    while max(maxIntensities > threshold)
        [~, particleIndex] = max(maxIntensities);
        gaussIndex = maxIndices(particleIndex);
        
        matches{t} = [matches{t} gaussIndex];
        
        % Update the intensity matrix without recomputing the whole thing.
        intensities(:,gaussIndex) = 0;
        intensities(particleIndex,:) = 0;
        for i = 1:length(maxIndices)
            if maxIndices(i) == gaussIndex
                [maxIntensities(i), maxIndices(i)] = max(intensities(i,:));
            end
        end
    end
end

% Find the weights of true and false Gaussian components.
trueWeights = [];
falseWeights = [];
for t = 1:T
    w = phds(t).w;
    z = phds(t).z;
    
    trueWeights = [trueWeights w(matches{t})];
    matchedZ = z(matches{t});
    falseIndices = false(size(w));
    for i = 1:length(falseIndices)
        falseIndices(i) = any(matchedZ == z(i)) && ~any(matches{t} == i);
    end
    falseWeights = [falseWeights w(falseIndices)];
%     falseWeights = [falseWeights phds(t).w(setdiff(1:phds(t).J,matches{t}))];
end

weights = [trueWeights falseWeights]';
classes = [2*ones(size(trueWeights)) ones(size(falseWeights))]';

% Specify where to save the classifier.
basePath = fileparts(fileparts(fileparts(mfilename('fullpath'))));
saveName = fullfile(basePath, 'BaxterAlgorithm', 'Scores', 'Classifiers', 'Count',...
    [imData.GetSeqDir() '_weight.mat']);

% Train the classifier.
Train_mnr_pca(weights, {'weight'}, classes, 'SaveName', saveName, 'MaxExamples', 1E5, 'Weights', [1 1]);
% Train_gda(weights, {'weight'}, classes, 'SaveName', saveName);

fprintf('Done training weight classifiers.\n')
end