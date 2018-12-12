function WriteStabilizationLog(aPath, aSequenceName, aOffsets)
% Writes a log file with offsets computed during image stabilization.
%
% The log file has the same structure as the log files created by the image
% stabilizer plugin for ImageJ. The log files can be used to apply the same
% offsets to an image sequence using the ImageJ plugin
% Image_Stabilizer_Log_Applier. The log files are text files with the file
% type .log. The files have a header and 4 comma separated columns, the
% first column has frame indices, the second has step lengths and is all
% ones, the third has x-offsets, and the fourth has y-offsets.
%
% Inputs:
% aPath - Full path of the log file to be created. The file type should be
%         .log.
% aSequenceName - Name of the image sequence folder (used in the header).
% aOffsets - Matrix where the first column has x-offsets and the second has
%            y-offsets. The shift in the first image needs to be specified
%            even though it is 0 in both x and y.
%
% See also:
% Stabilize, StabilizationGUI, Stabilizer.java

% Create the folder where the log file is placed if it does not exist.
if ~exist(fileparts(aPath), 'dir')
    mkdir(fileparts(aPath))
end

% Open log file for writing.
fid = fopen(aPath, 'w');

% Write header.
fprintf(fid, 'Image Stabilizer Log File for "%s"\r\n', aSequenceName);

% Write '0'. It seems to be for time point 0, but I don't know what it is
% used for.
fprintf(fid, '0\r\n');

% Write offsets.
for i = 1:size(aOffsets,1)
    fprintf(fid, '%d,1,%.17f,%.17f\r\n', i, aOffsets(i,1), aOffsets(i,2));
end

% Close the log file.
fclose(fid);
end