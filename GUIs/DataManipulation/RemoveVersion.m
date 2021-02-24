function RemoveVersion(aExPath, aVer)
% Removes a tracking version from an experiment.
%
% Inputs:
% aExPath - The full path of the experiment folder.
% aVer - The name of the tracking version NOT including 'CellData'.
%
% See also:
% DeleteVersion

verPath = fullfile(aExPath, 'Analysis', ['CellData' aVer]);
if ~exist(verPath, 'dir')
    warning('The folder %s does not exist.\n', verPath)
    return
end
fclose('all'); % rmdir can fail because files are open in Matlab.
rmdir(verPath, 's')
end