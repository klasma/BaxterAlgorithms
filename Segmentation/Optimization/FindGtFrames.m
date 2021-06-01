function oFrames = FindGtFrames(aGtPath)
% Find the frames with ground truth segmentations.
gtImages = GetNames(aGtPath, 'tif');
gtStrings = regexp(gtImages, '(?<=man_seg_?)\d+', 'match', 'once');
gtFramesWithDuplicates = cellfun(@str2double, gtStrings) + 1;
oFrames = unique(gtFramesWithDuplicates);
end