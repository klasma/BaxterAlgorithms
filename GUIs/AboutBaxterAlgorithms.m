function AboutBaxterAlgorithms()
% Opens a dialog box with version information about the program.
%
% The dialog box contains information about the version number of the
% Baxter Algorithms, the MATLAB version, and the computer architecture. The
% user can also see if the software is running as a deployed program or if
% the source code is executed from within MATLAB. If executed source code
% is in a git repository, the git branch and the git hash are also
% displayed.
%
% See also:
% WriteLog

h = dialog(...
    'Name', 'About Baxter Algorithms',...
    'Units', 'normalized',...
    'Position', [0.4 0.4 0.2 0.1]);

string = sprintf('Baxter Algorithms version: %s\n',...
    fileread(FindFile('version.txt')));
string = [string sprintf('MATLAB version: %s\n', version())];
string = [string sprintf('Architecture: %s\n', computer('arch'))];

if isdeployed
    string = [string sprintf('Deployed: yes\n')];
else
    string = [string sprintf('Deployed: no\n')];
end

% Include git information if the code is in a git-repository.
gitPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), '.git');
if exist(gitPath, 'dir')
    [branch, hash] = getGitInfo(gitPath);
    string = [string sprintf('Git branch: %s\n', branch)];
    string = [string sprintf('Git hash: %s\n', hash)];
end

% Add the text in a text box.
uicontrol('Parent', h,...
    'Style', 'text',...
    'Units', 'normalized',...
    'Position', [0.1 0.1 0.8 0.8],...
    'HorizontalAlignment', 'left',...
    'String', string);
end