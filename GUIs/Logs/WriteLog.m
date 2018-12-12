function WriteLog(aFilename, aFunction, aNote)
% Writes log information about tracking of cells in an image sequence.
%
% The function writes information to a text file located in a folder named
% 'Logs' in the CellData directory. The name of the text file is the same
% as the name of the image sequence directory. The following information is
% saved to the text file:
%
% Processing finished - The time when the tracking was completed. The same
%                       as the time the text files is created.
% Architecture - The computer architecture (win32, win64, glnxa64, maci64
%                for 32 bit windows, 64 bit windows, 64 bit linux, 64 bit
%                mac)
% MATLAB version - The version of MATLAB used for computation.
% Baxter Algorithms version - The version number for the BaxterAlgorithms.
%                             This field also specifies if the program is
%                             deployed.
% Git branch - If the program is executed from a git-repository, the
%              current branch is specified here.
% Git branch - If the program is executed from a git-repository, the
%              git hash (SHA) of the current commit is specified here.
% Function - The name of the function which saved the tracks.
% User notes - Notes specified by the user in the text box of the Tracking
%              GUI.
%
% Inputs:
% aFilename - Full path name of the file to be created.
% aFunction - The name of the function which saved the tracks.
% aNote - Notes specified by the user.
%
% See also:
% ReadLogNote, AboutBaxterAlgorithms

if ~exist(fileparts(aFilename), 'dir')
    mkdir(fileparts(aFilename))
end
fid = fopen(aFilename,'w');

fprintf(fid, 'Processing finished : %s\r\n', datestr(now));

fprintf(fid, 'Architecture: %s\r\n', computer('arch'));
fprintf(fid, 'MATLAB version: %s\r\n', version());
fprintf(fid, 'Baxter Algorithms version: %s\r\n', fileread(FindFile('version.txt')));
if isdeployed
    fprintf(fid, 'Deployed: yes\r\n');
else
    fprintf(fid, 'Deployed: no\r\n');
end

% Write git information if the code is in a git-repository.
gitPath = fullfile(...
    fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))),...
    '.git');
if exist(gitPath, 'dir')
    [branch, hash] = getGitInfo(gitPath);
    fprintf(fid, 'Git branch: %s\r\n', branch);
    fprintf(fid, 'Git hash: %s\r\n', hash);
end

fprintf(fid, 'Function: %s\r\n', aFunction);
fprintf(fid, 'User notes:\r\n');
fprintf(fid, aNote);

fclose(fid);
end