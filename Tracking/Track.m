function oCells = Track(aImData, varargin)
% Tracks cells or particles in a sequence of images or z-stacks.
%
% The function performs tracking of cells or subcellular particles and 2D
% and 3D. The function will first segment/detect the objects in all images
% or z-stacks and compute scores associated with different linking options.
% Then, the function will use a global track linking algorithm to link the
% detections into tracks. Finally, the function can perform different kinds
% of post-processing on the tracks. The function performs all processing
% steps necessary to find tracks and outlines of cells in images or
% z-stacks. Image stabilization and cropping of circular microwells are
% however not done by this function. Those operations can be performed by
% StabilizeLK and Cut before Track is called. The function will always
% return tracks for the cells or particles that were found, but it can also
% return tracks corresponding to objects that were classified as debris.
% Such objects can easily be turned into cells or particles in the manual
% correction user interface.
%
% This function was used to produce the tracking results presented in
% [1-6]. Those publications provide details about the different processing
% steps. The function may not reproduce the results presented in the
% papers exactly, because of improvements and bug-fixes, but the results
% should be similar, as long as the same settings file is used.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
%
% Parameter/Value inputs:
% CreateOutputFiles - Setting this parameter to false prevents Track from
%                     from generating any files. This is used in the the
%                     Cell Tracking Challenges, were there are rules
%                     against putting files outside the program directory.
% SegmentationCores - The number of cores to be used for segmentation of
%                     the images. If this is set to a number larger than 1,
%                     the segmentation will be parallelized over the
%                     images, using the specified number of cores. This
%                     parameter should be set to 1 if the function is
%                     called from a parfor-loop. The default is 1.
%
% Outputs:
% oCells - Array of Cell objects that contain information about the
%          cell/particle tracks, and tracks that are considered to be
%          debris.
%
% References:
% [1] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian particles
%     using the Viterbi algorithm Proc. 2015 IEEE Int. Symp. Biomed.
%     Imaging (ISBI), 2015, 380-384
%
% [2] Magnusson, K. E. G.; Jaldén, J.; Gilbert, P. M. & Blau, H. M. Global
%     linking of cell tracks using the Viterbi algorithm IEEE Trans. Med.
%     Imag., 2015, 34, 1-19
%
% [3] Maška, M.; Ulman, V.; Svoboda, D.; Matula, P.; Matula, P.; Ederra,
%     C.; Urbiola, A.; Espa na, T.; Venkatesan, S.; Balak, D. M. W.; Karas,
%     P.; Bolcková, T.; Štreitová, M.; Carthel, C.; Coraluppi, S.; Harder,
%     N.; Rohr, K.; Magnusson, K. E. G.; Jaldén, J.; Blau, H. M.;
%     Dzyubachyk, O.; K?ížek, P.; Hagen, G. M.; Pastor-Escuredo, D.;
%     Jimenez-Carretero, D.; Ledesma-Carbayo, M. J.; Mu noz-Barrutia, A.;
%     Meijering, E.; Kozubek, M. & Ortiz-de-Solorzano, C. A benchmark for
%     comparison of cell tracking algorithms Bioinformatics, Oxford Univ
%     Press, 2014, 30, 1609-1617
%
% [4] Chenouard, N.; Smal, I.; de Chaumont, F.; Maška, M.; Sbalzarini, I.
%     F.; Gong, Y.; Cardinale, J.; Carthel, C.; Coraluppi, S.; Winter, M.;
%     Cohen, A. R.; Godinez, W. J.; Rohr, K.; Kalaidzidis, Y.; Liang, L.;
%     Duncan, J.; Shen, H.; Xu, Y.; Magnusson, K. E. G.; Jaldén, J.; Blau,
%     H. M.; Paul-Gilloteaux, P.; Roudot, P.; Kervrann, C.; Waharte, F.;
%     Tinevez, J.-Y.; Shorte, S. L.; Willemse, J.; Celler, K.; van Wezel,
%     G. P.; Dan, H.-W.; Tsai, Y.-S.; Ortiz de Solórzano, C.; Olivo-Marin,
%     J.-C. & Meijering, E. Objective Comparison of Particle Tracking
%     Methods Nat. Methods, 2014, 11, 281-289
%
% [5] Magnusson, K. E. G. & Jaldén, J. A batch algorithm using iterative
%     application of the Viterbi algorithm to track cells and construct
%     cell lineages Proc. 2012 IEEE Int. Symp. Biomed. Imaging (ISBI),
%     2012, 382-385
%
% [6] Gilbert, P. M.; Havenstrite, K. L.; Magnusson, K. E. G.; Sacco, A.;
%     Leonardi, N. A.; Kraft, P.; Nguyen, N. K.; Thrun, S.; Lutolf, M. P. &
%     Blau, H. M. Substrate elasticity regulates skeletal muscle stem cell
%     self-renewal in culture Science, American Association for the
%     Advancement of Science, 2010, 329, 1078-1081
%
% See also:
% Cell, SegmentSequence, ViterbiTrackLinking, SaveTrack, TrackingGUI,
% BaxterAlgorihtm, BaxterAlgorihtmTerminal, StabilizeLK, Cut,
% ManualCorrectionPlayer

% Parse property/value inputs.
[aCreateOutputFiles, aSegmentationCores] = GetArgs(...
    {'CreateOutputFiles', 'SegmentationCores'},...
    {true, 1},...
    true, varargin);

fprintf('Tracking cells in %s\n', aImData.seqPath)

% Features used to compute linking scores (classify of cell events).
necessaryFeatures = NecessaryFeatures(aImData);

% Segment all images or z-stacks in the sequence.
blobSeq = SegmentSequence(aImData,...
    'NumCores', aSegmentationCores,...
    'Features', necessaryFeatures,...
    'CreateOutputFiles', aCreateOutputFiles);

% Merges segmented regions based on their overlap with regions in adjacent
% frames. This is only used in the Cell Tracking Challenge dataset
% DIC-C2DH-HeLa and is kept for reproducibility.
if aImData.Get('TrackMergeBrokenMaxArea') > 0
    blobSeq = MergeBrokenBlobs(blobSeq,...
        aImData.Get('TrackMergeBrokenMaxArea'),...
        aImData.Get('TrackMergeBrokenRatio'));
end

% Compute scores for different linking options.
if contains(aImData.Get('TrackMigLogLikeList'), 'PHD')
    % Particle tracking using GM-PHD filters.
    
    % Blobs from segmentation. They will be replaced by GM-PHD components
    % in the linking step and then inserted into the final results.
    segBlobSeq = blobSeq;
    
    [migrationScores, blobSeq, phd] = MigrationScores_generic(blobSeq, aImData,...
        'CreateOutputFiles', aCreateOutputFiles);
else
    [migrationScores, blobSeq] = MigrationScores_generic(blobSeq, aImData,...
        'CreateOutputFiles', aCreateOutputFiles);
end
splitScores = SplitScores(blobSeq, aImData, migrationScores, -20);
countScores = CountScores(blobSeq, aImData,...
    'CreateOutputFiles', aCreateOutputFiles);
deathScores = DeathScores(blobSeq, aImData);
if contains(aImData.Get('TrackMigLogLikeList'), 'PHD')
    % Particle tracking using GM-PHD filters.
    appearanceScores = AppearanceScores_PHD(phd, aImData);
    disappearanceScores = DisappearanceScores_PHD(phd, aImData);
else
    appearanceScores = AppearanceScores(blobSeq, aImData);
    disappearanceScores = DisappearanceScores(blobSeq, aImData);
end

numDets = cellfun(@length, blobSeq);

if sum(numDets) == 0
    % If there are no detections, there will be no cells.
    oCells = [];
    return
end

% Specify the name of a folder where information about intermediate
% tracking results will be saved in binary files. These files can be used
% to reconstruct intermediate tracking results for debug purposes.
if aImData.Get('TrackSaveIterations') && aCreateOutputFiles
    iterationFolder = fullfile(aImData.GetCellDataDir(),...
        'Iterations', aImData.GetSeqDir());
    if ~exist(iterationFolder, 'dir')
        mkdir(iterationFolder)
    end
else
    % No binary files will be saved.
    iterationFolder = '';
end

% Specify the name of a log-file where progress messages from the track
% linking process will be saved.
if aCreateOutputFiles
    trackLogFile = fullfile(aImData.GetCellDataDir(),...
        'Tracking_log',...
        [aImData.GetSeqDir() '.txt']);
    if ~exist(fileparts(trackLogFile), 'dir')
        mkdir(fileparts(trackLogFile))
    end
else
    % No log-file will be saved.
    trackLogFile = '';
end

[cellMat, divMat, deathMat] = ViterbiTrackLinking(...
    numDets,...
    countScores,...
    migrationScores,...
    splitScores,...
    deathScores,...
    appearanceScores,...
    disappearanceScores,...
    aImData.Get('TrackSingleIdleState'),...
    aImData.Get('TrackMaxMigScore'),...
    iterationFolder,...
    trackLogFile);

% Create Cell objects for tracks created by ViterbiTrackLinking.
trueCells = Matrix2Cell(cellMat, divMat, deathMat, blobSeq, aImData);

% Split blobs that contain multiple cells using k-means clustering and
% change assignments using bipartite matching.
if aImData.Get('TrackBipartiteMatch')
    if contains(aImData.Get('TrackMigLogLikeList'), 'PHD')
        warndlg(['Bipartite matching cannot (currently) be performed '...
            'if the migration scores are computed using GM-PHDs.'],...
            'Not performing bipartite matching')
    else
        trueCells = BipartiteMatch(trueCells, aImData);
    end
else
    if contains(aImData.Get('TrackMigLogLikeList'), 'PHD')
        % Replace the Gaussian components by the original blobs.
        blobSeq = GMSegments(trueCells, segBlobSeq, aImData);
    end
    BreakAllClusters(trueCells, blobSeq, aImData)
end

% Find blobs that were not included in any tracks.
falseBlobSeq = FalseBlobs(blobSeq, trueCells);

% Merge blobs without cells into cells, based on overlap in nearby frames.
% This makes it possible to place seemingly disconnected pieces of
% cytoplasm in the same cell outline. This is only used in the Cell
% Tracking Challenge dataset Fluo-C2DL-MSC and is kept for reproducibility.
mergeIter = 0;
while mergeIter < aImData.Get('TrackMergeOverlapMaxIter')
    % When the cells are altered, they can overlap more with other blobs
    % and therefore the function is run multiple times. A while loop is
    % used to allow an infinite iteration limit.
    [falseBlobSeq, numMerged] = MergeOverlappingFP(...
        trueCells,...
        falseBlobSeq,...
        aImData.Get('TrackMergeOverlapThresh'),...
        aImData.Get('TrackMergeOverlapDeltaT'));
    if numMerged == 0
        % No more segments can be merged after this.
        break
    end
    mergeIter = mergeIter + 1;
end

% Merge blobs without cells into adjacent cells. This is useful to reduce
% over segmentation caused by watershed transforms.
if aImData.Get('TrackMergeWatersheds')
    if aImData.numZ == 1  % 2D
        falseBlobSeq = MergeFPWatersheds(aImData, trueCells, falseBlobSeq);
    else  % 3D
        falseBlobSeq = MergeFPWatersheds3D(aImData, trueCells, falseBlobSeq);
    end
end

% Re-apply morphological operators to the blobs, if the blobs have been
% altered after the segmentation. The super-blobs are not changed.
% TODO: Deal with super-blobs.
if ~strcmpi(aImData.Get('SegCellMorphOp'), 'none') &&...
        (aImData.Get('TrackMergeOverlapMaxIter') > 0 ||...
        aImData.Get('TrackMergeWatersheds'))
    
    trueBlobSeq = Cells2Blobs(trueCells, aImData, 'Sub', true);
    % The operations are applied directly to the Blob objects in the cells.
    % TODO: Handle blobs which disappear in this operation.
    for i = 1:length(trueBlobSeq)
        fprintf(['Applying morphological operators to the blobs '...
            'in image %d / %d\n'], i, length(trueBlobSeq))
        BlobMorphOp(...
            trueBlobSeq{i},...
            aImData.Get('SegCellMorphOp'),...
            aImData.Get('SegCellMorphMask'),...
            aImData);
        
        % Fill holes in segmentation after closing.
        if strcmp(aImData.Get('SegCellMorphOp'), 'close') &&...
                aImData.Get('SegFillHoles')
            for j = 1:length(trueBlobSeq{i})
                trueBlobSeq{i}(j).image =...
                    imfill(trueBlobSeq{i}(j).image, 'holes');
            end
        end
    end
end

% Turn false positive blobs into false positive cells (debris).
if aImData.Get('TrackFalsePos') == 1
    % Link false positive detections into tracks.
    falseCells = FPTrack(falseBlobSeq, aImData);
    
    if aImData.Get('TrackSaveFPAsCells')
        for i = 1:length(falseCells)
            falseCells(i).isCell = true;
        end
    end
    
    oCells = [trueCells, falseCells];
elseif aImData.Get('TrackFalsePos') == 2
    % Create a separate false positive cell for each detection.
    numBlobs = sum(cellfun(@length, falseBlobSeq));
    if numBlobs > 0
        falseCells(numBlobs) = Cell();
        index = 1;
        for t = 1:length(falseBlobSeq)
            for i = 1:length(falseBlobSeq{t})
                b = falseBlobSeq{t}(i);
                if aImData.GetDim() == 3  % 3D
                    cz = b.centroid(3);
                else  % 2D
                    cz = 0;
                end
                c = Cell(...
                    'imageData', aImData,...
                    'blob', b.CreateSub(),...
                    'cx', b.centroid(1),...
                    'cy', b.centroid(2),...
                    'cz', cz,...
                    'firstFrame', t,...
                    'lifeTime', 1,...
                    'isCell', false);
                falseCells(index) = c;
                index = index + 1;
            end
        end
    else
        falseCells = [];
    end
    oCells = [trueCells, falseCells];
else
    % Do not include false positive detections in the results.
    oCells = trueCells;
end

% Pre-compute properties of the cell blobs.
if ~aImData.Get('TrackSaveCTC')
    % We do not want to do this in the Cell Tracking Challenge.
    % TODO: Make the condition nicer. This should work for now.
    ComputeRegionPropsCells(oCells, aImData)
end

% Offset the estimated position for the MICROTUBULE data set in the ISBI
% 2012 Particle Tracking Challenge.
if aImData.Get('TrackCentroidOffset') > 0
    ApplyOffsets(oCells, aImData.Get('TrackCentroidOffset'))
end

% Remove cell regions that do not have pixels far enough away from the
% image borders.
if aImData.Get('foiErosion') > 0
    oCells = ErodeFOI(oCells, aImData.Get('foiErosion'), aImData);
end

oCells = ColorCells(oCells, 'Coloring', 'Rainbow');
end