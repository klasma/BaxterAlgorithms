function ISBICellGT(aExPath, varargin)
% ISBICellGT(aExPath) converts ground truth track data from the format used
% in the ISBI 2013 cell tracking challenge into the MATLAB format used by
% the Baxter Algorithms. The tracking version will be saved in a folder
% named CellDataGT.
%
% Inputs:
% aExPath - Full path name of the experiment folder which contains the
% image sequence folders.

aFullNames = GetArgs({'FullNames'}, {false}, true, varargin);

% Add necessary paths.
subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter',pathsep);
addpath(subdirs{1}{:});

% Image sequence information in Baxter Algorithms format.
seqDirs = GetSeqDirs(aExPath);

for seq = 1:length(seqDirs)
    % Folder containing all images.
    seqPath = fullfile(aExPath, seqDirs{seq});
    % Folder containing images with manually labeled pixels.
    if aFullNames
        gtDir = [seqDirs{seq} '_GT'];
    else
        gtDir = [seqDirs{seq}(end-1:end) '_GT'];
    end
    gtPath = fullfile(aExPath, 'Analysis', gtDir, 'TRA');
    % File with information about cell parents.
    trackInfoFile = fullfile(aExPath, 'Analysis', gtDir, 'TRA', 'man_track.txt');
    
    imData = ImageData(seqPath);  % Image data for the image sequence.
    gtImData = ImageData(gtPath);  % Image data with manually labeled pixels.
    gtImData.Set('zStacked', imData.Get('zStacked'))
    gtImData.Set('numZ', imData.Get('numZ'))
    
    % Generate cell array where every cell contains a cell array with the blobs
    % in one of the images. Cell i in nested cell arrray t will contain the
    % blob associated with cell i, or be empty if that cell is not present in
    % image t.
    blobSeq = cell(gtImData.sequenceLength,1);
    for t = 1:gtImData.sequenceLength
        fprintf('Creating blobs for image %d / %d.\n', t, gtImData.sequenceLength)
        
        % Image with cell labels
        if gtImData.numZ == 1
            mask = gtImData.GetImage(t);
        else
            mask = gtImData.GetZStack(t);
        end
        
        rawProps = regionprops(...
            mask,...
            'BoundingBox',...
            'Image',...
            'Centroid',...
            'Area');
        
        % Create the blobs.
        blobSeq{t} = cell(length(rawProps),1);
        for i = 1:length(rawProps)
            if rawProps(i).Area > 0
                blobSeq{t}{i} = Blob(rawProps(i));
            end
        end
    end
    
    % Link the blobs into cell trajectories.
    numCells = max(cellfun(@length,blobSeq));
    clear('cells');  % Clear the variable on each iteration.
    cells(numCells) = Cell();  % Preallocation.
    for t = 1:gtImData.sequenceLength
        fprintf('Creating cells for image %d / %d.\n', t, gtImData.sequenceLength)
        
        for i = 1:length(blobSeq{t})
            if isempty(blobSeq{t}{i})
                continue
            end
            if(cells(i).lifeTime == 0)
                cells(i) = Cell(...
                    'imageData', imData,...
                    'firstFrame', t,...
                    'blob', []);
            end
            b = blobSeq{t}{i}.CreateSub();
            cells(i).AddFrame(b);
        end
    end
    
    % Connect daughter cell to parent cells. Every row in the file has 4
    % numbers. The first number is the cell index, the second is the fist
    % frame of the cell, the third is the last frame of the cell and the
    % fourth is the index of the parent cell. When a cell disappers, and
    % reappears, the competition organizers define the first track be the
    % parent of the second. For now the tracks will be treated as two
    % separate tracks.
    fid = fopen(trackInfoFile, 'r');
    while ~feof(fid)
        line = fgetl(fid);
        if isequal(line, -1)
            break
        end
        line = strtrim(line);
        % There seems to be a single space between the numbers, but I allow
        % an arbitrary number of separation charachters.
        strings = regexp(line, '\s+', 'split');
        numbers = cellfun(@str2double, strings);
        child = numbers(1);
        parent = numbers(4);
        if parent ~= 0
            cells(parent).AddChild(cells(child));
        end
    end
    fclose(fid);
    
    % Check that there are no cells with only one child.
    for i = 1:length(cells)
        if length(cells(i).children) == 1
            warning('Cell %d has only one child.', i)
            cells(i).children.parent = [];
            cells(i).children = [];
        end
    end
    
    % Remove cells that were not in the processed images.
    emptyIndices = arrayfun(@(c)c.lifeTime==0, cells);
    cells(emptyIndices) = [];
    
    % Changes the order of the cells and colors them.
    cells = ColorCells(cells, 'Coloring', 'Rainbow');
    
    SaveCells(cells, seqPath, 'GT')
end
fprintf('Done converting cell data.\n')
end