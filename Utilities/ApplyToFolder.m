function aStopAfter = ApplyToFolder(aFunction, aFolder, varargin)
% Executes a function on a set of sequences.
%
% This helper function is supposed to be called from within the main
% function that is to be executed. If a single sequence is given as input,
% the helper function will not execute the main function, because then the
% main function will perform the execution on its own after calling the
% helper function. The helper function can handle experiment folders,
% dataset folders containing multiple experiment folders, and cell arrays
% of image sequence folders, experiment folders, or dataset folders.
%
% A typical main function looks like this:
%
% function MainFunction(aFolder, varargin)
%
% aFolderType = GetArgs({'FolderType'}, {'sequence'}, true, varargin);
%
% if ApplyToFolder(@MainFunction, aFolder, aFolderType)
%    return
% end
%
% % Main code.
%
% end
%
% Inputs:
% aFunction - Main function to be executed.
% aFolder - Full path of a folder or a cell array with full paths.
% aFolderType - Specifies which type of folder has been given as input.
%               Valid values are 'sequence', 'experiment', and 'dataset'.
%
% Outputs:
% aStopAfter - This is set to true if the main function needs to execute
%              its code after calling this helper function.

aFolderType = varargin{end};

% Handle cell array inputs with multiple paths.
if iscell(aFolder)
    for i = 1:length(aFolder)
        feval(aFunction, aFolder{i}, 'FolderType', aFolderType)
    end
end

switch lower(aFolderType)
    case 'dataset'
        exDirs = GetNames(aFolder, '');
        for i = 1:length(exDirs)
            feval(aFunction, fullfile(aFolder, exDirs{i}),...
                varargin{1:end-1},...
                'FolderType', 'experiment')
        end
        aStopAfter = true;
    case 'experiment'
        seqDirs = GetUseSeq(aFolder);
        for i = 1:length(seqDirs)
            feval(aFunction, fullfile(aFolder, seqDirs{i}),...
                varargin{1:end-1},...
                'FolderType', 'sequence')
        end
        aStopAfter = true;
    case 'sequence'
        aStopAfter = false;
        % Continue executing the main function.
    otherwise
        error('Unknown folder type %s\n', aFolderType)
end
end