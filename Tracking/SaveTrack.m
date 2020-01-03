function SaveTrack(aImData, varargin)
% Tracks cells in an image sequence and saves the results to a file.
%
% The cell data will be saved to a folder named CellData[aImData.version],
% in the analysis folder of the experiment. Tracking results are always
% saved to mat-files, as arrays of Cell objects. Depending on the settings
% of the image sequences, tracking results may however also be saved to the
% format of the ISBI Particle Tracking Challenge or the ISBI Cell Tracking
% Challenge (CTC). It is also possible to select a subset of cells based on
% manually marked cells in the first image. The manual marking needs to be
% in the format of the CTC, and is currently used only for the
% Fluo-N3DL-DRO dataset of CTC 2015.
%
% Inputs:
% aImData - ImageData object of the image sequence to be processed.
%
% Property/Value inputs:
% Algorithm - The tracking function to be called. In general, this will be
%             'Track', but it can also be changed to other functions which
%             are used for development. The default value is 'Track'.
% SegmentationCores - The number of cores to be used for segmentation of
%                     the images. If this is set to a number larger than 1,
%                     the segmentation will be parallelized over the
%                     images, using the specified number of cores. This
%                     parameter should be set to 1 if the function is
%                     called from a parfor-loop. The default is 1.
%
% See also:
% Track, SaveCells, SaveCellsXML, SaveCellsTif, SaveSelectedGTCells

% Get property/value inputs.
[aAlgorithm, aSegmentationCores] = GetArgs(...
    {'Algorithm', 'SegmentationCores'},...
    {'Track', 1},...
    true, varargin);

if aImData.Get('TrackSaveCSB')
    blobSeq = SegmentSequence(aImData, 'NumCores', aSegmentationCores);
    SaveSegmentationCSB(aImData, blobSeq, aImData.version, false)
    return
end

% Call the appropriate tracking algorithm.
switch aAlgorithm
    case 'Track'
        % Default tracking algorithm.
        cells = Track(aImData, 'SegmentationCores', aSegmentationCores);
    otherwise
        error('Unknown tracking algorithm %s.', aAlgorithm)
end

if aImData.Get('TrackSavePTC')
    % ISBI Challenge 2012.
    SaveCellsXML(cells, aImData.seqPath, aImData.version);
end

if aImData.Get('TrackSaveCTC')
    % Save label images as tifs. This data is used for the performance
    % evaluation in the ISBI 2014 Cell Tracking Challenge. Setting
    % 'CompressCopy', to false when calling SaveCells removes all blobs, so
    % the saving of results for the CTC must come before calling SaveCells.
    % SaveCellsTif removes point blobs, and therefore we need to get the
    % possibly altered cells as an output from SaveCellsTif, to make sure
    % that the same cells are saved in the mat-file.
    cells = SaveCellsTif(aImData, cells, aImData.version, false);
end

% Save the results to a mat-file, as an array of Cell objects.
SaveCells(cells, aImData.seqPath, aImData.version, 'CompressCopy', false);

if aImData.Get('TrackSelectFromGT')
    % Select manually tracked cells and save them to a separate version.
    SaveSelectedGTCells(aImData, aImData.version, [aImData.version '_sel'],...
        'Relink', aImData.Get('TrackRelinkSelectedCells'))
end
end