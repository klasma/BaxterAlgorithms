% Performs startup tasks when MATLAB is opened in this directory.

% Add all paths in sub-directories. This makes it possible to skip the
% addition of paths in scripts and eliminates the risk that a deployed
% application is created without adding the necessary paths.
if ~isdeployed
    subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s', 'delimiter', pathsep);
    addpath(subdirs{1}{:});
    clear subdirs
end