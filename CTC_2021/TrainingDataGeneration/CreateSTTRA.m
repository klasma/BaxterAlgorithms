function CreateSTTRA(aSeqPath)
% Create a tracking ground truth in the ST-folder to evaluate DET on.
%
% The tracking ground truth should have one cell for each segmented object
% and no links between the cells.

imData = ImageData(aSeqPath);

pathST = imData.GetGroundTruthPath('_ST', true);
pathSEG = fullfile(pathST, 'SEG');
pathTRA = fullfile(pathST, 'TRA');

if ~exist(pathTRA, 'dir')
    mkdir(pathTRA)
end

if imData.sequenceLength <= 1000
    fmtSEG = 'man_seg%03d.tif';
    fmtTRA = 'man_track%03d.tif';
else
    digits = ceil(log10(imData.sequenceLength));
    fmtSEG = ['man_seg%0' num2str(digits) 'd.tif'];
    fmtTRA = ['man_track%0' num2str(digits) 'd.tif'];
end

totalCellCount = 0;
frameCellCounts = zeros(1, imData.sequenceLength);
for t = 1:imData.sequenceLength
    fprintf('Converting frames to tracking format %d / %d\n',...
        t, imData.sequenceLength)
    
    imPathSEG = fullfile(pathSEG, sprintf(fmtSEG, t-1));
    
    % Read label image.
    if imData.numZ == 1  % 2D data.
        oldIm = imread(imPathSEG);
    else  % 3D data.
        oldIm = zeros(imData.imageHeight, imData.imageWidth, imData.numZ, 'uint16');
        if exist(imPathSEG, 'file')
            for z = 1:imData.numZ
                oldIm(:,:,z) = imread(imPathSEG, z);
            end
        end
    end
    
    % Convert labels to unique consecutive cell identifiers.
    indices = unique(oldIm(:));
    indices = setdiff(indices, 0);
    newIm = zeros(size(oldIm), 'uint16');
    for i = 1:length(indices)
        oldIndex = indices(i);
        newIndex = totalCellCount + i;
        newIm(oldIm == oldIndex) = newIndex;
    end
    
    frameCellCounts(t) = length(indices);
    totalCellCount = totalCellCount + frameCellCounts(t);
    
    imPathTRA = fullfile(pathTRA, sprintf(fmtTRA, t-1));
    
    % Save the modified label image.
    if imData.numZ == 1  % 2D data.
        imwrite(newIm, imPathTRA, 'Compression', 'lzw')
    else  % 3D data.
        for slice = 1:size(newIm,3)
            if slice == 1
                % Overwrite the existing file.
                imwrite(newIm(:,:,slice), imPathTRA,...
                    'Compression', 'lzw')
            else
                % Append to the new file.
                imwrite(newIm(:,:,slice), imPathTRA,...
                    'WriteMode', 'append',...
                    'Compression', 'lzw')
            end
        end
    end
end

% Create a res_track.txt file.
fid = fopen(fullfile(pathTRA, 'man_track.txt'), 'w');
cellIndex = 1;
for t = 1:imData.sequenceLength
    for i = 1:frameCellCounts(t)
        fprintf(fid, '%d %d %d %d\r\n', cellIndex, t-1, t-1, 0);
        cellIndex = cellIndex + 1;
    end
end
fclose(fid);
end