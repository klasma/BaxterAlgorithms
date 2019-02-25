exPath = 'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training\Fluo-N3DL-TRIC';
newExPath = 'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training\Fluo-N3DL-TRIC-cropped';

seqDirs = GetSeqDirs(exPath);

for i = 1:length(seqDirs)
    seqPath = fullfile(exPath, seqDirs{i});
    imData = ImageData(seqPath);
    gtSegPath = fullfile(exPath, 'Analysis', [seqDirs{i}(end-1:end) '_GT'], 'SEG');
    segGtTifs = GetNames(gtSegPath, 'tif');
    
    cellPixels = [];
    for j = 1:length(segGtTifs)
        imPath = fullfile(gtSegPath, segGtTifs{j});
        labelIm = imread(imPath);
        if isempty(cellPixels)
            cellPixels = labelIm > 0;
        else
            cellPixels = cellPixels | labelIm > 0;
        end
    end
    
    x = any(cellPixels,1);
    x1 = max(find(x, 1, 'first')-10, 1);
    x2 = min(find(x, 1, 'last')+10, imData.imageWidth);
    
    y = any(cellPixels,2);
    y1 = max(find(y, 1, 'first')-10, 1);
    y2 = min(find(y, 1, 'last')+10, imData.imageHeight);
    
    newSeqPath = fullfile(newExPath, seqDirs{i});
    SaveSubVolume(seqPath, newSeqPath, [x1 x2], [y1 y2], [1 imData.numZ], [1 imData.sequenceLength])
    
    numImages = length(GetNames(gtSegPath, 'tif'));
    newGtSegPath = fullfile(newExPath, 'Analysis', [seqDirs{i}(end-1:end) '_GT'], 'SEG');
    SaveSubVolume(gtSegPath, newGtSegPath, [x1 x2], [y1 y2], [1 1], [1 numImages])
    
    gtTraPath = fullfile(exPath, 'Analysis', [seqDirs{i}(end-1:end) '_GT'], 'TRA');
    newGtTraPath = fullfile(newExPath, 'Analysis', [seqDirs{i}(end-1:end) '_GT'], 'TRA');
    SaveSubVolume(gtTraPath, newGtTraPath, [x1 x2], [y1 y2], [1 imData.numZ], [1 imData.sequenceLength])
    
    gtTrackFile = fullfile(gtTraPath, 'man_track.txt');
    newGtTrackFile = fullfile(newGtTraPath, 'man_track.txt');
    copyfile(gtTrackFile, newGtTrackFile)
end