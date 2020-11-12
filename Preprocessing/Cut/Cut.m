function Cut(aSeqPath, aSaveExPath)
% Cut finds and cuts out all round microwells in an image sequence.
%
% The function saves image sequences with cut out microwells in a folder
% named [aSaveExPath]/[sequence name]. If the folder does not exist it will
% be created. The function also saves mat-files with information about the
% centers and the radii of the microwells, to a folder named Microwells in
% the Analysis folder of the new experiment. This is done so that the
% microwell does not have to be recomputed when the image sequence is
% tracked.
%
% Inputs:
% aSeqPath - Full path of image sequence from which a microwell will be
%            cut.
% aSaveExPath - Experiment folder folder to save the cut sequence to.
%
% See also:
% CuttingGUI, GetWellCircle

% The size of the margins around the microwell given in microwell radii.
MARGIN = 0.20;

imData = ImageData(aSeqPath);

fprintf('Automatically cutting a microwell from %s\n', imData.seqPath)

% Find microwells.
[xAll, yAll, rAll] = FindWellsHough(imData, 1);

saveSeqDirs = arrayfun(@(x)sprintf('%s_w%02d', imData.GetSeqDir(), x),...
    1:length(xAll),...
    'UniformOutput', false)';
saveSeqPaths = strcat(aSaveExPath, filesep, saveSeqDirs);

% Arrays of bounding box pixel coordinates.
x1All = zeros(size(xAll));
x2All = zeros(size(xAll));
y1All = zeros(size(xAll));
y2All = zeros(size(xAll));

for i = 1:length(xAll)
    % Create folders for the cut out image sequences.
    if ~exist(saveSeqPaths{i}, 'dir')
        mkdir(saveSeqPaths{i})
    end
    
    % Save the computed microwell parameters to a mat-file that can be read
    % by GetWellCircle.m.
    microWellFile = fullfile(...
        aSaveExPath,...
        'Analysis',...
        'Microwells',...
        [saveSeqDirs{i} '.mat']);
    if ~exist(fileparts(microWellFile), 'dir')
        mkdir(fileparts(microWellFile))
    end
    
    % Coordinates of the sub-window to save.
    x1All(i) = max(round((xAll(i) - rAll(i)*(1 + MARGIN))), 1);
    x2All(i) = min(round((xAll(i) + rAll(i)*(1 + MARGIN))), imData.imageWidth);
    y1All(i) = max(round((yAll(i) - rAll(i)*(1 + MARGIN))), 1);
    y2All(i) = min(round((yAll(i) + rAll(i)*(1 + MARGIN))), imData.imageHeight);
    
    x = xAll(i) - x1All(i) + 1;
    y = yAll(i) - y1All(i) + 1;
    r = rAll(i);
    save(microWellFile, 'x', 'y', 'r')
end

% Save cut out image sequences.
for t = 1:imData.sequenceLength
    % Cut out a sub-image from each image and save it to the new sequence
    % folder.
    
    for c = 1:length(imData.filenames)
        % Process each channel
        fprintf('Cutting image %d / %d, channel %d\n', t, imData.sequenceLength, c);
        
        for i = 1:length(xAll)
            % Read sub-image.
            subIm = imData.GetImage(t, 'Channel', c,...
                'PixelRegion', {[y1All(i) y2All(i)], [x1All(i) x2All(i)]});
            
            saveFile = fullfile(saveSeqPaths{i}, FileEnd(imData.filenames{c}{t}));
            
            imwrite(subIm, saveFile, 'Compression', 'lzw');
        end
    end
end
end