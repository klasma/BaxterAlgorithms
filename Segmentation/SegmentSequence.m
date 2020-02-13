function oBlobSeq = SegmentSequence(aImData, varargin)
% Segments cells in an entire image sequence.
%
% The function segments all images in an image sequence by calling either
% Segment_generic or Segment_generic3D. The function can also save
% mat-files with segmentation results to the analysis folder of the
% experiment. Such files can be loaded later if an interrupted processing
% session is resumed, or if segmentation results from an old tracking
% result should be reused. The function also computes all features that are
% necessary for classification of cell counts, mitosis, and apoptosis.
%
% Inputs:
% aImData - ImageData object for the image sequence.
%
% Property/Value inputs:
% Features - Cell array with a list of features that should be computed.
%            This can be used to compute more features than the features
%            that are required by the current classifiers. This can be
%            useful for development of new classifiers. The caller must
%            make sure that the features required for classification are
%            included in the feature list.
% CreateOutputFiles - If this parameter is set to false, the program will
%                     not create any files with segmentation results or any
%                     other files. This can be used in tracking challenges
%                     when there are rules against creating new files in
%                     the data directories.
% NumCores - The number of processor cores to be used for processing. If
%            this is set to more than 1, the segmentation and the feature
%            computation will be parallelized over the images of the image
%            sequence.
%
% Outputs:
% oBlobSeq - Cell array with one cell per frame, where each cell contains
%            an array of Blob objects that were segmented out in that
%            frame.
%
% See also:
% Track, Segment_generic, Segment_generic3D, ComputeFeatures

% Parse property/value inputs.
[aFeatures, aCreateOutputFiles, aNumCores] = GetArgs(...
    {'Features', 'CreateOutputFiles', 'NumCores'},...
    {{}, true, 1},...
    true,...
    varargin);

% Create a list of features that will be sent to ComputeFeatures.
if ~isempty(aFeatures)
    featureNames = aFeatures;
else
    featureNames = NecessaryFeatures(aImData);
end
% The feature 'weight' can be used in particle tracking, but if it is
% needed by the classifiers, it has already been computed by the function
% that computes migration scores, so it should not be included in list of
% features sent to ComputeFeatures.
featureNames = setdiff(featureNames, 'weight');
% Separate the feature names into feature function names and input
% arguments for the feature functions.
[featureFunctions, featureArguments] = GetExtraArguments(featureNames);

oBlobSeq = cell(1,aImData.sequenceLength);
if aNumCores == 1
    % A single processor core is used for segmentation in a for-loop.
    for t = 1:aImData.sequenceLength
        oBlobSeq{t} = SegmentImage(aImData, t, featureNames,...
            featureFunctions, featureArguments, aCreateOutputFiles);
    end
else
    % Multiple processor cores are used for segmentation in a parfor-loop.
    StartWorkers(aNumCores)
    parfor t = 1:aImData.sequenceLength
        oBlobSeq{t} = SegmentImage(aImData, t, featureNames,...
            featureFunctions, featureArguments, aCreateOutputFiles);
    end
end

% Sort the blobs based on their positions in the image. Not sure if this is
% necessary.
oBlobSeq = SortBlobs(oBlobSeq);

% Index the blobs.
for t = 1:length(oBlobSeq)
    for index = 1:length(oBlobSeq{t})
        oBlobSeq{t}(index).index = index;
    end
end

fprintf('Segmentation Done.\n\n')
end

function oBlobs = SegmentImage(aImData, aT, aFeatureNames,...
    aFeatureFunctions, aFeatureArguments, aCreateOutputFiles)
% Segments a single frame and returns an array of Blob objects.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aT - Index of the frame that should be segmented.
% aFeatureNames - Cell array of full feature names.
% aFeatureFunctions - Cell array with the names of the feature functions
%                     corresponding to the feature names.
% aFeatureArguments - Input arguments for the feature functions, extracted
%                     from the feature names.
% aCreateOutputFiles - Binary input indicating whether or not mat-files
%                      with blob objects should be saved. These mat-files
%                      make it possible to load a segmentation, and save
%                      time if processing is resumed.
%
% Outputs:
% oBlobs - Array of segmented Blob objects.

% Path where mat-files with blobs may be saved.
writePath = fullfile(aImData.GetResumePath(), 'Segmentation');

% Path from which mat-files with blobs could be read.
oldVersion = aImData.Get('SegOldVersion');
if ~strcmpi(oldVersion, 'none')
    % Read blobs from a previously saved segmentation.
    readPath = fullfile(aImData.GetResumePath('Version', oldVersion),...
        'Segmentation');
else
    % Read blobs from the resume-folder, if the processing was interrupted.
    readPath = writePath;
end

% Generate blobs.
imProcessor = ImageProcessor(aImData, aT);
readBlobFile = fullfile(readPath, sprintf('blobs%04d.mat', aT));
if exist(readBlobFile, 'file')
    % Load blobs from file.
    tmp = load(readBlobFile);
    blobs = tmp.blobs;
    IndexBlobs({blobs})
    
    if ~isempty(aFeatureNames)
        % Compute features for classification. Features which have been
        % computed previously are not re-computed.
        bwIm = ReconstructSegmentsBlob(blobs, aImData.GetSize()) > 0;
        imProcessor.SetBwIm(bwIm);
        ComputeFeatures(...
            imProcessor,...
            blobs,...
            aFeatureNames,...
            aFeatureFunctions,...
            aFeatureArguments)
    end
else
    % Create blobs by performing segmentation.
    fprintf('Segmenting image %d / %d\n', aT, aImData.sequenceLength)
    if aImData.GetDim() == 2
        [blobs, bw, preThresh] = Segment_generic(aImData, aT);
    else
        [blobs, bw, preThresh] = Segment_generic3D(aImData, aT);
    end
    
    if ~isempty(aFeatureNames)
        % Compute features for classification.
        imProcessor.SetBwIm(bw);
        imProcessor.SetPreThresholdIm(preThresh);
        ComputeFeatures(...
            imProcessor,...
            blobs,...
            aFeatureNames,...
            aFeatureFunctions,...
            aFeatureArguments)
    end
end

% Save blobs.
writeBlobFile = fullfile(writePath, sprintf('blobs%04d.mat', aT));
if ~exist(writeBlobFile, 'file') && aImData.Get('SegSave') && aCreateOutputFiles
    if ~exist(fileparts(writeBlobFile), 'dir')
        mkdir(fileparts(writeBlobFile))
    end
    save(writeBlobFile, 'blobs')
end

oBlobs = blobs;
end