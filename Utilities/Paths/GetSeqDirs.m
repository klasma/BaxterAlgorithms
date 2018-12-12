function oDirs = GetSeqDirs(aExPath)
% Returns a list of the image sequence folders in an experiment folder.
%
% The image sequence folders are folders containing the images in an image
% sequence. An experiment folder is a folder containing multiple image
% sequence folders which belong to the same imaging experiment.
%
% Inputs:
% aExPath - Full path of the experiment folder.
%
% Outputs:
% oDirs - The names of the image sequence folders of the experiment. The
%         full paths are not returned.
%
% See also:
% GetUseSeq, GetNames

oDirs = GetNames(aExPath, '');
% '.DS_Store' is a folder created when folders are opened on macs.
oDirs = setdiff(oDirs, {'Analysis'; '.DS_Store'});
end