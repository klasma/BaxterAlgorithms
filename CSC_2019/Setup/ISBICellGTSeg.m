function ISBICellGTSeg(aExPath)
% ISBICellGT(aExPath) generates cell tracks for the ISBI 2013 Cell Tracking
% challenge, with outlines taken from the ground truth segmentations. Cell
% positions that don't have outlines in the ground truth segmentation are
% left as point blobs. The tracking version will be saved in a folder named
% CellDataGTSeg.
%
% Inputs:
% aExPath - Full path name of the experiment folder which contains the
% image sequence folders.

% Add necessary paths.
subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter',pathsep);
addpath(subdirs{1}{:});

% Image sequence information in Baxter Algorithms format.
seqDirs = GetSeqDirs(aExPath);

for seq = 1:length(seqDirs)
    % Folder containing all images.
    seqPath = fullfile(aExPath, seqDirs{seq});
    
    if HasVersion(seqPath, 'GTSeg')
        continue
    end
    
    % Folder containing images with manually labeled pixels.
    gtPath = fullfile(aExPath, 'Analysis', [seqDirs{seq}(end-1:end) '_GT'], 'SEG');
    
    imData = ImageData(seqPath);  % Image data for the image sequence.
    gtImData = ImageData(gtPath);  % Image data with manually labeled pixels.
    if strcmp(FileEnd(aExPath), 'Fluo-C3DH-A549')
        gtImData.Set('numZ', imData.numZ);
        gtImData.Set('zStacked', imData.Get('zStacked'));
    end
    % Not all frames have a ground truth segmentation, but the ImageData
    % objects do not know about this. gtImData can therefore have a shorter
    % sequenceLength.
    
    % Generate cell array where every cell contains a cell array with the blobs
    % in one of the images. Cell i in nested cell arrray t will contain the
    % blob associated with cell i, or be empty if that cell is not present in
    % image t.
    blobSeq = cell(imData.sequenceLength,1);
    for t = 1:gtImData.sequenceLength
        fprintf('Creating blobs for image %d / %d.\n', t, gtImData.sequenceLength)
        
        % mask is an image with cell labels
        % frame is the time point associated with ground truth segmentation
        % t.
        if imData.numZ == 1
            frame = str2double(regexp(gtImData.filenames{1}{t},...
                '(?<=man_seg)\d+(?=.tif)', 'match', 'once')) + 1;
            mask = gtImData.GetImage(t);
        elseif gtImData.numZ > 1  % 3D data where all z-planes have been segmented.
            frame = str2double(regexp(gtImData.filenames{1}{t},...
                '(?<=man_seg)\d+(?=.tif)', 'match', 'once')) + 1;
            mask = gtImData.GetZStack(t);
        else  % 3D data where only one z-plane is segmented.
            frame = str2double(regexp(gtImData.filenames{1}{t},...
                '(?<=man_seg_)\d+(?=_\d+.tif)', 'match', 'once')) + 1;
            zIndex = str2double(regexp(gtImData.filenames{1}{t},...
                '(?<=man_seg_\d+_)\d+(?=.tif)', 'match', 'once')) + 1;
            mask = zeros(imData.imageHeight, imData.imageWidth, imData.numZ);
            mask(:,:,zIndex) = gtImData.GetImage(t);
        end
        
        rawProps = regionprops(...
            mask,...
            'BoundingBox',...
            'Image',...
            'Centroid',...
            'Area');
        
        % Create the blobs.
        tblobs = cell(length(rawProps),1);
        for i = 1:length(rawProps)
            if rawProps(i).Area > 0
                tblobs{i} = Blob(rawProps(i), 'index', i);
            end
        end
        blobSeq{frame} = [tblobs{:}];  % Avoids creating dummy Blobs for missing labels.
    end
    
    gtCells = LoadCells(seqPath, 'GT');
    if imData.numZ > 1 && gtImData.numZ == 1
        ExpandCellsInZDirection(gtCells, imData);
    end
    cells = SwitchSegmentation(imData, gtCells, blobSeq);
    
    % Split blobs where two separate cell regions have been given the same
    % ground truth label by mistake.
    UpdateSegmentation(cells, imData)
    
    % Changes the order of the cells and colors them.
    cells = ColorCells(cells, 'Coloring', 'Rainbow');
    
    SaveCells(cells, seqPath, 'GTSeg')
end
fprintf('Done converting cell data.\n')
end