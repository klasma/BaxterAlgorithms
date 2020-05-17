function oCells = LoadCellsTif(aSeqPath, aCTCPath)
% Loads tracks from the formats used in the cell tracking challenges.
%
% The function can load both ground truth tracks and computer generated
% results in the formats used in the cell tracking challenges.
%
% Inputs:
% aSeqPath - Full path of the image sequence that the tracks are associated
%            with.
% aCTCPath - Full path of the folder containing tif- and txt-files
%            representing tracks. For ground truth tracks, this is the TRA
%            folder and for computer generated results it is the RES
%            folder.
%
% See also:
% LoadCells, SaveCellsTif

% Image data for the image sequence with microscope images.
imData = ImageData(aSeqPath);
% Image data for the image sequence with cell regions.
labelImData = ImageData(aCTCPath);
labelImData.Set('numZ', imData.numZ)
labelImData.Set('zStacked', 1)

% File with information about cell parents. It is named res_track.txt for
% computer generated results and man_track.txt for ground truth tracks.
trackInfoFile = fullfile(aCTCPath, 'res_track.txt');
if ~exist(trackInfoFile, 'file')
    trackInfoFile = fullfile(aCTCPath, 'man_track.txt');
    if ~exist(trackInfoFile, 'file')
        error('No track information file found.')
    end
end

% Generate cell array where every cell contains a cell array with the blobs
% in one of the images. Cell i in nested cell array t will contain the blob
% associated with cell i, or be empty if that cell is not present in image
% t.
blobSeq = cell(imData.sequenceLength,1);

% Index of the first corrected image. The labelImData object starts the
% indexing from 1 anyway, but the cells will be created correctly due
% to this offset parameter.
firstImage = str2double(regexp(labelImData.filenames{1}{1},...
    '(?<=(mask|man_track))\d+(?=.tif)', 'match', 'once'));

wbar = waitbar(0, '', 'Name', 'Loading cells from tif-files');
for t = 1:labelImData.sequenceLength
    waitbar((t-1)/labelImData.sequenceLength, wbar, 'Creating blobs')
    
    % Image with cell labels.
    if labelImData.numZ == 1
        mask = labelImData.GetImage(t);
    else
        mask = labelImData.GetZStack(t);
    end
    
    rawProps = regionprops(...
        mask,...
        'BoundingBox',...
        'Image',...
        'Centroid',...
        'Area');
    
    % Create the blobs.
    blobSeq{firstImage+t} = cell(length(rawProps),1);
    for prop = 1:length(rawProps)
        if rawProps(prop).Area > 0
            blobSeq{firstImage+t}{prop} = Blob(rawProps(prop),...
                'index', prop);
        end
    end
end

% Link the blobs into cell trajectories.
numCells = max(cellfun(@length,blobSeq));
oCells(numCells) = Cell();  % Pre-allocation.
for t = 1:imData.sequenceLength
    waitbar((t-1)/labelImData.sequenceLength, wbar, 'Creating cells')
    
    for bIndex = 1:length(blobSeq{t})
        if isempty(blobSeq{t}{bIndex})
            continue
        end
        if(oCells(bIndex).lifeTime == 0)
            oCells(bIndex) = Cell(...
                'imageData', imData,...
                'firstFrame', t,...
                'blob', []);
        end
        b = blobSeq{t}{bIndex}.CreateSub();
        oCells(bIndex).AddFrame(b);
    end
end

% Connect daughter cell to parent cells. Every row in the file has 4
% numbers. The first number is the cell index, the second is the first
% frame of the cell, the third is the last frame of the cell and the fourth
% is the index of the parent cell. When a cell disappears, and reappears,
% the first track becomes the parent of the second.
fid = fopen(trackInfoFile, 'r');
while ~feof(fid)
    line = fgetl(fid);
    if isequal(line, -1)
        break
    end
    line = strtrim(line);
    % There should be a single space between the numbers, but I allow an
    % arbitrary number of separation characters.
    strings = regexp(line, '\s+', 'split');
    numbers = cellfun(@str2double, strings);
    child = numbers(1);
    parent = numbers(4);
    if parent ~= 0
        oCells(parent).AddChild(oCells(child), 'GapsOk', true);
    end
end
fclose(fid);

% By default, none of the cells that end before the last frame die.
for i = 1:length(oCells)
    c = oCells(i);
    if isempty(c.children) && c.lastFrame < imData.sequenceLength
        c.disappeared = true;
    end
end

% Read information about which cells died from a text file.
deathFile = fullfile(aCTCPath, 'deaths.txt');
if exist(deathFile, 'file')
    fid_death = fopen(deathFile, 'r');
    while ~feof(fid_death)
        line = fgetl(fid_death);
        if isequal(line, -1)
            break
        end
        line = strtrim(line);
        % There should be a single space between the numbers, but I allow
        % an arbitrary number of separation characters.
        strings = regexp(line, '\s+', 'split');
        numbers = cellfun(@str2double, strings);
        c = oCells(numbers(1));
        if isempty(c.children) &&...
                c.lastFrame < imData.sequenceLength &&...
                numbers(2) == 1
            c.disappeared = false;
        end
    end
    fclose(fid_death);
end

% Read information about dummy tracks and remove them.
dummyPath = fullfile(aCTCPath, 'dummy_tracks.txt');
if exist(dummyPath, 'file')
    fid_dummy = fopen(dummyPath, 'r');
    dummyIndices = [];
    while ~feof(fid_dummy)
        line = fgetl(fid_dummy);
        if isequal(line, -1)
            break
        end
        line = strtrim(line);
        strings = regexp(line, '\s+', 'split');
        numbers = cellfun(@str2double, strings);
        dummyIndices = [dummyIndices numbers(1)]; %#ok<AGROW>
    end
    oCells(dummyIndices) = [];
    fclose(fid_dummy);
end

% Remove cells that were not in the processed images.
emptyIndices = arrayfun(@(c)c.lifeTime==0, oCells);
oCells(emptyIndices) = [];

% Load false positive tracks, if such tracks have been saved.
fpFolder = fullfile(aCTCPath, 'false_positives');
if exist(fpFolder, 'dir')
    fpCells = LoadCellsTif(aSeqPath, fpFolder);
    for i = 1:length(fpCells)
        fpCells(i).isCell = false;
    end
    oCells = [oCells fpCells];
end

% Changes the order of the cells and colors them.
oCells = ColorCells(oCells, 'Coloring', 'Rainbow');

delete(wbar)
end