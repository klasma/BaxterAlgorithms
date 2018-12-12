function [...
    oFeatures,...
    oCounts,...
    oSplits,...
    oDeaths,...
    oFeatureNames,...
    oSequenceNames,...
    oSequences,...
    oFrames,...
    oIndices,...
    oCentroids,...
    oBoundingBoxes] =...
    DataSet(aSeqPaths, aVer, aFeatureNames)
% Compiles blob features and ground truths for counts, splits and deaths.
%
% The function generates a feature matrix where each row represents a blob
% and each column represents a feature. The feature columns are in the same
% order as the feature names that are given as input. The first time the
% function is called for a particular image sequence and tracking version,
% this file will save a mat-file in the location specified by
% ImgageData.GetDataSetFileName(). When the data is requested again, it
% will be read from the file to save time. If the requested features are
% not present in the blobs or in the saved files, the function will compute
% the features. The computed features are then added to the the mat-file.
% No changes are made to the saved cell or blob objects.
%
% Inputs:
% aSeqPaths - A character array with the path of a single image sequence or
%             a cell array with multiple paths.
% aVer - Tracking version.
% FeatureNames - Cell array with feature names.
%
% Outputs:
% oFeatures - Feature matrix.
% oCounts - Column vector with the cell count of each blob.
% oSplits - Binary column vector indicating which blobs have mitosis.
% oDeaths - Binary column vector indicating which blobs have apoptosis.
% oFeatureNames - The names of the features in the columns of oFeatures.
% oSequenceNames - Cell array with the names of the image sequences.
% oSequences - Column vector with the sequence index of each blob.
% oFrames - Column vector with the frame of each blob.
% oIndices - Column vector with the index of each blob in its frame.
% oCentroids - Matrix where each row is the xy coordinate of a Blob
%              centroid.
% oBoundingBoxes - Matrix where each row is the boundingbox of a Blob.

% Default empty outputs.
oFeatureNames = aFeatureNames;
oSequenceNames = FileEnd(aSeqPaths);
oFeatures = zeros(0,length(aFeatureNames));
oCounts = zeros(0,1);
oSplits = zeros(0,1);
oDeaths = zeros(0,1);
oSequences = zeros(0,1);
oFrames = zeros(0,1);
oIndices = zeros(0,1);
oCentroids = zeros(0,2);
oBoundingBoxes = zeros(0,4);

if iscell(aSeqPaths)
    % Data from multiple image sequences are combined.
    for i = 1:length(aSeqPaths)
        fprintf('Getting classification data for image sequence %d / %d\n',...
            i, length(aSeqPaths))
        [features,...
            counts,...
            splits,...
            deaths,...
            ~,...
            ~,...
            ~,...
            frames,...
            indices,...
            centroids,...
            boundingBoxes] =...
            DataSet(aSeqPaths{i}, aVer, aFeatureNames);
        oFeatures = [oFeatures; features]; %#ok<AGROW>
        oCounts = [oCounts; counts]; %#ok<AGROW>
        oSplits = [oSplits; splits]; %#ok<AGROW>
        oDeaths = [oDeaths; deaths]; %#ok<AGROW>
        oSequences = [oSequences; i*ones(size(features,1),1)]; %#ok<AGROW>
        oFrames = [oFrames; frames]; %#ok<AGROW>
        oIndices = [oIndices; indices]; %#ok<AGROW>
        oCentroids = [oCentroids; centroids]; %#ok<AGROW>
        oBoundingBoxes = [oBoundingBoxes; boundingBoxes]; %#ok<AGROW>
    end
    return
end

% Get data from a single image sequence.

imData = ImageData(aSeqPaths);
dataSetFile = imData.GetDataSetFileName(aVer);

if exist(dataSetFile, 'file')
    % Read previously computed data from file.
    tmp = load(dataSetFile);
    features = tmp.features;
    featureNames = tmp.featureNames;
    counts = tmp.counts;
    splits = tmp.splits;
    deaths = tmp.deaths;
    frames = tmp.frames;
    indices = tmp.indices;
    centroids = tmp.centroids;
    boundingBoxes = tmp.boundingBoxes;
    
    % Features that that have not been computed previously.
    missingFeatureNames = setdiff(aFeatureNames, featureNames);
    
    if ~isempty(missingFeatureNames)
        % Compute missing features and save them to the file.
        cells = LoadCells(aSeqPaths, aVer);
        if isempty(cells)
            return
        end
        
        blobSeq = Cells2Blobs(cells, imData);
        blobSeq = RemovePointBlobs(blobSeq);
        IndexBlobs(blobSeq)
        
        % Pre-compute function names and arguments for features.
        [featureFunctions, featureArguments] =...
            GetExtraArguments(missingFeatureNames);
        
        % Add features to the blobs.
        for t = 1:length(blobSeq)
            imProcessor = ImageProcessor(imData, t);
            
            % Add the segmentation mask to the ImageProcessor.
            bwIm = ReconstructSegmentsBlob(blobSeq{t}, imData.GetSize()) > 0;
            imProcessor.SetBwIm(bwIm);
            
            ComputeFeatures(...
                imProcessor,...
                blobSeq{t},...
                missingFeatureNames,...
                featureFunctions,...
                featureArguments)
        end
        
        blobs = [blobSeq{:}];
        
        missingFeatures = FeatureMatrix(blobs, missingFeatureNames);
        features = [features missingFeatures];
        featureNames = [featureNames; missingFeatureNames];
        
        % Save data to file.
        if ~exist(fileparts(dataSetFile), 'dir')
            mkdir(fileparts(dataSetFile))
        end
        save(dataSetFile,...
            'featureNames',...
            'features',...
            'counts',...
            'splits',...
            'deaths',...
            'frames',...
            'indices',...
            'centroids',...
            'boundingBoxes')
    end
    
    oFeatures = SelectFeatures(features, featureNames, aFeatureNames);
else
    % The variable featureNames will be saved later.
    featureNames = aFeatureNames;
    
    % Compute data and save it to a file.
    cells = LoadCells(aSeqPaths, aVer);
    if isempty(cells)
        return
    end
    
    blobSeq = Cells2Blobs(cells, imData);
    blobSeq = RemovePointBlobs(blobSeq);
    IndexBlobs(blobSeq)
    
    blobs = [blobSeq{:}];
    
    % Pre-compute function names and arguments for features.
    [featureFunctions, featureArguments] = GetExtraArguments(featureNames);
    
    % Add features to the blobs.
    for t = 1:length(blobSeq)
        imProcessor = ImageProcessor(imData, t);
        
        % Add the segmentation mask to the ImageProcessor.
        bwIm = ReconstructSegmentsBlob(blobSeq{t}, imData.GetSize()) > 0;
        imProcessor.SetBwIm(bwIm);
        
        ComputeFeatures(...
            imProcessor,...
            blobSeq{t},...
            featureNames,...
            featureFunctions,...
            featureArguments)
    end
    
    % Extract the features from the blobs.
    features = FeatureMatrix(blobs, featureNames);
    
    % Compute ground truths.
    counts = CountCells(blobSeq, cells);
    counts = cat(2,counts{:})';
    splits = FindSplits(blobSeq, cells);
    splits = cat(2,splits{:})';
    deaths = FindDeaths(blobSeq, cells);
    deaths = cat(2,deaths{:})';
    
    % Compute other blob-data.
    frames = cat(1, blobs.t);
    indices = cat(1, blobs.index);
    centroids = cat(1, blobs.centroid);
    boundingBoxes = cat(1, blobs.boundingBox);
    
    % Save data to file.
    if ~exist(fileparts(dataSetFile), 'dir')
        mkdir(fileparts(dataSetFile))
    end
    save(dataSetFile,...
        'featureNames',...
        'features',...
        'counts',...
        'splits',...
        'deaths',...
        'frames',...
        'indices',...
        'centroids',...
        'boundingBoxes')
    
    oFeatures = features;
end

% Assign outputs.
oCounts = counts;
oSplits = splits;
oDeaths = deaths;
oFrames = frames;
oIndices = indices;
oCentroids = centroids;
oBoundingBoxes = boundingBoxes;
end