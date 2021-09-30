function CreateStMinusGt(aSeqPath)

imData = ImageData(aSeqPath);

gtPath = imData.GetGroundTruthPath('_GT', true);
gtSegPath = fullfile(gtPath, 'SEG');
gtTraPath = fullfile(gtPath, 'TRA');
gtSegFiles = GetNames(gtSegPath, 'tif');

stPath = imData.GetGroundTruthPath('_ST', true);
stSegPath = fullfile(stPath, 'SEG');

stMinusGtPath = [stPath '_minus_GT'];
stMinusGtSegPath = fullfile(stMinusGtPath, 'SEG');

if imData.sequenceLength <= 1000
    fmtSeg = 'man_seg%03d.tif';
    fmtTra = 'man_track%03d.tif';
else
    digits = ceil(log10(imData.sequenceLength));
    fmtSeg = ['man_seg%0' num2str(digits) 'd.tif'];
    fmtTra = ['man_track%0' num2str(digits) 'd.tif'];
end

for t = 1:imData.sequenceLength
    fprintf('Processing frame %d / %d\n', t, imData.sequenceLength)
    
    gtTraImPath = fullfile(gtTraPath, sprintf(fmtTra, t-1));
    stSegImPath = fullfile(stSegPath, sprintf(fmtSeg, t-1));
    if ~exist(stSegImPath, 'file')
        fprintf('The file %s does not exist.\nen', stSegImPath)
        continue
    end
    stMinusGtSegImPath = fullfile(stMinusGtSegPath, sprintf(fmtSeg, t-1));
    
    gtMatches = regexpi(gtSegFiles,...
        ['man_seg_?0*' num2str(t-1) '(_\d+|.tif)'],...
        'match',...
        'once');
    gtMatchingFiles = gtSegFiles(~cellfun(@isempty, gtMatches));
    
    if isempty(gtMatchingFiles)
        if ~exist(stMinusGtSegPath, 'dir')
            mkdir(stMinusGtSegPath)
        end
        copyfile(stSegImPath, stMinusGtSegImPath)
    else
        gtTraIm = ReadTifStack(gtTraImPath);
        stSegIm = ReadTifStack(stSegImPath);
        
        gtSegIm = zeros(size(gtTraIm), 'uint16');
        for i = 1:length(gtMatchingFiles)
            % Extract the zero based z-slice index from the file name. For 2D data,
            % the slice index is set to 1.
            slice = regexpi(gtMatchingFiles{i}, '(?<=man_seg_?\d+_)\d+', 'match', 'once');
            if isempty(slice)
                slice = 0;
            else
                slice = str2double(slice);
            end
            slicePath = fullfile(gtSegPath, gtMatchingFiles{i});
            sliceIm = imread(slicePath);
            sliceIm = sliceIm + max(gtSegIm(:));
            gtSegIm(:, :, slice+1) = sliceIm;
        end
        
        stLabels = unique(stSegIm(:));
        stLabels = setdiff(stLabels, 0);
        gtMatches = FindMatches(gtTraIm, gtSegIm);
        stMatches = FindMatches(gtTraIm, stSegIm);
        for i = 1:length(gtMatches)
            if ~isnan(gtMatches(i)) && ~isnan(stMatches(i))
                fprintf('Removing label %d in frame %d of %s\n',...
                    stMatches(i), t, aSeqPath)
                stLabels(stLabels == stMatches(i)) = [];
            end
        end
        
        stMinusGtIm = zeros(size(gtTraIm), 'uint16');
        for i = 1:length(stLabels)
            stMinusGtIm(stSegIm == stLabels(i)) = i;
        end
        
        if ~exist(stMinusGtSegPath, 'dir')
            mkdir(stMinusGtSegPath)
        end
        
        % Save the modified label image.
        if size(stMinusGtIm,3) == 1  % 2D data.
            imwrite(stMinusGtIm, stMinusGtSegImPath, 'Compression', 'lzw')
        else  % 3D data.
            for slice = 1:size(stMinusGtIm,3)
                if slice == 1
                    % Overwrite the existing file.
                    imwrite(stMinusGtIm(:,:,slice), stMinusGtSegImPath,...
                        'Compression', 'lzw')
                else
                    % Append to the new file.
                    imwrite(stMinusGtIm(:,:,slice), stMinusGtSegImPath,...
                        'WriteMode', 'append',...
                        'Compression', 'lzw')
                end
            end
        end
        
    end
end
end

function oMatches = FindMatches(aMarkerIm, aSegIm)

segLabels = double(unique(aSegIm(:)));
segNum = length(segLabels);
segMap(segLabels+1) = 1:segNum;

markerLabels = unique(aMarkerIm(:));
markerNum = length(markerLabels);
markerMap(markerLabels+1) = 1:markerNum;

% Matrix where the number of overlapping pixels are counted for each region
% pair. overlaps(i,j) is the overlap between region i in the marker image
% and region j in the segmentation. In these calculations, the backgrounds
% are counted as regions.
overlaps = zeros(markerNum, segNum);

% Count the overlaps.
for i = 1:numel(aSegIm)
    seg = segMap(aSegIm(i)+1);
    marker = markerMap(aMarkerIm(i)+1);
    overlaps(marker, seg) = overlaps(marker, seg) + 1;
end

% Sum to get the number of pixels in each region.
markerCounts = sum(overlaps, 2);

% Remove the background counts from the ground truth.
overlaps = overlaps(2:end, 2:end);
segLabels = segLabels(2:end);
markerCounts = markerCounts(2:end);

[maxOverlaps, matches] = max(overlaps, [], 2);
matches = segLabels(matches);
matches(maxOverlaps * 2 <= markerCounts) = nan;
oMatches = matches;
end