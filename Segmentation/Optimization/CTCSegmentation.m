function CTCSegmentation(aImData, aVer, varargin)
% Saves segmentation results in frames with manual segmentation.
%
% The function segments only the images which have a segmentation ground
% truth, and saves label images to a faked tracking result in format of the
% ISBI Cell Tracking Challenges. No empty images are saved for un-segmented
% frames and no text file with track information is created. This can be
% useful for testing of segmentation parameters in cases where it takes a
% long time to produce complete tracking results.
%
% Inputs:
% aImData - ImData the image sequence to segment.
% aVer - Name of the generated tracking version.
%
% Property/Value inputs:
% NumImages - The number of images to segment. Only images with
%             segmentation ground truth are segmented. If this parameter is
%             set to NaN, all images with a segmentation ground truth will
%             be segmented.
% MostCells - If this parameter is set to true, the NumImages images with
%             most ground truth cells will be segmented. Otherwise the
%             images will be sampled evenly from the set of images with
%             ground truth segmentations.
% aScoringFunction - This parameter specifies the scoring function that
%                    should be optimized. The available options are 'SEG',
%                    and '(SEG+TRA)/2'. The SEG and TRA measures are the
%                    performance measures that were used to evaluate
%                    segmentation and tracking performance in the ISBI 2015
%                    Cell Tracking Challenge publication [1]. All images in
%                    the sequences have to be segmented to compute TRA, but
%                    for the SEG measure it is enough to segment the images
%                    which have ground truth segmentations. For SEG it is
%                    also possible to use only a subset of the images with
%                    segmentation ground truths. The default is 'SEG'.
% varargin - All valid settings parameters, and values that are fields in
%            AllSettings. The specified values override the values saved in
%            the settings files.
%
% References:
% [1] Ulman, V.; Maška, M.; Magnusson, K. E. G.; Ronneberger, O.; Haubold,
%     C.; Harder, N.; Matula, P.; Matula, P.; Svoboda, D.; Radojevic, M.;
%     Smal, I.; Rohr, K.; Jaldén, J.; Blau, H. M.; Dzyubachyk, O.;
%     Lelieveldt, B.; Xiao, P.; Li, Y.; Cho, S.-Y.; Dufour, A. C.;
%     Olivo-Marin, J.-C.; Reyes-Aldasoro, C. C.; Solis-Lemus, J. A.;
%     Bensch, R.; Brox, T.; Stegmaier, J.; Mikut, R.; Wolf, S.; Hamprecht,
%     F. A.; Esteves, T.; Quelhas, P.; Demirel, Ö.; Malmström, L.; Jug, F.;
%     Tomancak, P.; Meijering, E.; Muñoz-Barrutia, A.; Kozubek, M. &
%     Ortiz-de-Solorzano, C., An objective comparison of cell-tracking
%     algorithms, Nature methods, 2017, 14, 1141–1152

% Parse property/value inputs.
[evaluationArgs, settingsArgs] =...
    SelectArgs(varargin, {'NumImages', 'MostCells', 'ScoringFunction', 'Suffix'});
[aNumImages, aMostCells, aScoringFunction, aSuffix] = GetArgs(...
    {'NumImages', 'MostCells', 'ScoringFunction', 'Suffix'},...
    {nan, false, 'SEG', '_GT'}, true, evaluationArgs);

imData = aImData;

% Overwrite the saved settings with settings specified by the caller.
for i = 1:length(settingsArgs)/2
    imData.Set(settingsArgs{2*i-1}, settingsArgs{2*i});
end

switch aScoringFunction
    case {'SEG' '0.9*SEG+0.1*DET'}
        % Find the frames in which there are segmentation ground truths.
        seqDir = imData.GetSeqDir();
        gtPath = fullfile(imData.GetAnalysisPath(), [seqDir aSuffix], 'SEG');
        if ~exist(gtPath, 'dir')
            % If the ground truth folder is not found, we check if the folder
            % name has been abbreviated.
            gtPath = fullfile(imData.GetAnalysisPath(), [seqDir(end-1:end) aSuffix], 'SEG');
        end
        if ~exist(gtPath, 'dir')
            error('No ground truth exists for %s', imData.seqPath)
        end
        
        % Find the frames with ground truth segmentations.
        gtImages = GetNames(gtPath, 'tif');
        gtStrings = regexp(gtImages, '(?<=man_seg_?)\d+', 'match', 'once');
        gtFramesWithDuplicates = cellfun(@str2double, gtStrings) + 1;
        gtFrames = unique(gtFramesWithDuplicates);
        
        if ~isnan(aNumImages)
            if aMostCells
                % Pick the images with the most cells.
                gtImagePaths = strcat(gtPath, filesep, gtImages);
                numCells = zeros(size(gtFrames));
                % Load the images to see how many cells they have.
                for i = 1:length(gtImages)
                    im = imread(gtImagePaths{i});
                    index = gtFrames == gtFramesWithDuplicates(i);
                    numCells(index) = numCells(index) + max(im(:));
                end
                [~,indices] = sort(numCells, 'descend');
                gtFrames = gtFrames(indices(1:aNumImages));
                gtFrames = sort(gtFrames);
            else
                if length(gtFrames) > aNumImages
                    % Sample images evenly from the first to the last image.
                    if aNumImages == 1
                        indices = 1;
                    else
                        stepLength = (length(gtFrames)-1) / (aNumImages-1);
                        indices = round(1 + (0:aNumImages-1) * stepLength);
                    end
                    gtFrames = gtFrames(indices);
                end
            end
        end
    case '(SEG+TRA)/2'
        gtFrames = 1:imData.sequenceLength;
    otherwise
        error('Unknown scoring function %s', aScoringFunction)
end

resPath = fullfile(....
    imData.GetCellDataDir('Version', aVer),...
    'RES',...
    [seqDir, '_RES']);

if exist(resPath, 'dir')
    % Remove old files.
    fclose('all'); % rmdir can fail because files are open in Matlab.
    rmdir(resPath, 's')
end
mkdir(resPath)

if imData.sequenceLength <= 1000
    fmt = 'mask%03d.tif';
else
    digits = ceil(log10(imData.sequenceLength));
    fmt = ['mask%0' num2str(digits) 'd.tif'];
end

parfor i = 1:length(gtFrames)
    fprintf('Segmenting frame %d / %d\n', i, length(gtFrames))
    t = gtFrames(i);
    
    % Perform segmentation.
    if imData.GetDim() == 2
        blobs = Segment_generic(imData, t);
    else  % 3D
        blobs = Segment_generic3D(imData, t);
    end
    
    % Write label images to a tracking result folder.
    imPath = fullfile(resPath, sprintf(fmt, t-1));
    imageSize = [imData.imageHeight, imData.imageWidth, imData.numZ];
    im = ReconstructSegmentsBlob(blobs, imageSize);
    if size(im,3) == 1  % 2D data.
        imwrite(uint16(im), imPath, 'Compression', 'lzw')
    else  % 3D data.
        for slice = 1:size(im,3)
            imwrite(uint16(squeeze(im(:,:,slice))), imPath,...
                'WriteMode', 'append',...
                'Compression', 'lzw')
        end
    end
end

% Convert to tracking format if the scoring function is '0.9*SEG+0.1*DET'.
if strcmp(aScoringFunction, '0.9*SEG+0.1*DET')
    totalCellCount = 0;
    frameCellCounts = zeros(1, imData.sequenceLength);
    for i = 1:length(gtFrames)
        fprintf('Converting frames to tracking format %d / %d\n', i, length(gtFrames))
        t = gtFrames(i);

        imPath = fullfile(resPath, sprintf(fmt, t-1));
        
        % Read label image.
        if imData.numZ == 1  % 2D data.
            im = imread(imPath);
        else  % 3D data.
            im = zeros(imData.imageHeight, imData.imageWidth, imData.numZ, 'uint16');
            if exist(imPath, 'file')
                for z = 1:imData.numZ
                    im(:,:,z) = imread(imPath, z);
                end
            end
        end
        
        % Convert labels to unique cell identifiers.
        gtz = im > 0;
        if ~any(gtz)
            continue
        end
        frameCellCounts(t) = max(im(gtz));
        im(gtz) = im(gtz) + totalCellCount;
        totalCellCount = totalCellCount + frameCellCounts(t);
        
        % Save the modified label image.
        if imData.numZ == 1  % 2D data.
            imwrite(im, imPath, 'Compression', 'lzw')
        else  % 3D data.
            for slice = 1:size(im,3)
                if slice == 1
                    % Overwrite the existing file.
                    imwrite(im(:,:,slice), imPath,...
                    'Compression', 'lzw')
                else
                    % Append to the new file.
                    imwrite(im(:,:,slice), imPath,...
                    'WriteMode', 'append',...
                    'Compression', 'lzw')
                end
            end
        end
    end
    
    % Create a res_track.txt file.
    fid = fopen(fullfile(resPath, 'res_track.txt'), 'w');
    cellIndex = 1;
    for t = 1:imData.sequenceLength
        for i = 1:frameCellCounts(t)
            fprintf(fid, '%d %d %d %d\r\n', cellIndex, t-1, t-1, 0);
            cellIndex = cellIndex + 1;
        end
    end
    fclose(fid);
end

fprintf('Done segmenting frames\n')
end