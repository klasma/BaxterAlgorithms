function oNewFilename = ReplaceZInSegName(aOldFilename, aOffset)
% Changes the Z-index in segmentation ground truth file names.

beginning = regexpi(aOldFilename, 'man_seg_?\d+_', 'match', 'once');
oldSliceStr = regexpi(aOldFilename, '(?<=man_seg_?\d+_)\d+', 'match', 'once');
oldSlice = str2double(oldSliceStr);
newSlice = oldSlice + aOffset;
oNewFilename = sprintf('%s%03d.tif', beginning, newSlice);
end