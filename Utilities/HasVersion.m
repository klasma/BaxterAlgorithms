function oTest = HasVersion(aSeqPath, aVer)
% Tests if an image sequence has a particular tracking version.
%
% The function will both check that a file with tracking results exists and
% that it is not empty. If no file is found, the function checks if there
% is a folder with tracking results in the CTC format.
%
% Inputs:
% aSeqPath - Full path of the image sequence folder.
% aVer - Version to check for, excluding the 'CellData' prefix.
%
% Outputs:
% oTest - True if the tracking version exists, false otherwise.
%
% See also:
% GetVersions

[exPath, seqDir] = FileParts2(aSeqPath);
dataFile = fullfile(exPath, 'Analysis', ['CellData' aVer],...
    [seqDir '.mat']);

oTest = false;
if exist(dataFile, 'file')
    % Check that the file is not empty.
    info = dir(dataFile);
    if info.bytes > 0
        oTest = true;
    end
else
    % Look for a tracking result saved in the CTC format.
    ctcFolder = fullfile(exPath, 'Analysis', ['CellData' aVer],...
        'RES', [seqDir '_RES']);
    if exist(ctcFolder, 'dir')
        oTest = true;
    end
end
end