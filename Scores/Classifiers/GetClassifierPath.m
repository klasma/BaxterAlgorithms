function oPath = GetClassifierPath(aType, aFilename)
% Returns the full path of a classifier file of a specific type.
%
% The function finds the full paths of mat-files with classifiers of a
% specified type. The caller specifies the classifier type and the name of
% the file, and the function looks through all folders where classifiers of
% the specified type have been placed. The function also looks in
% sub-folders. The function stops looking when it has found a file with the
% specified name, so there must not be multiple classifiers with the same
% name. The function generates an error if the classifier cannot be found.
%
% Inputs:
% aType - The classifier type. This should be 'Count', 'Death', 'Split' or
%         'Migration'.
% aFilename - The name of the classifier file. The extension '.mat' can be
%             included, but no path information should be included.
%
% Outputs:
% oPath - The full path of the classifier file.

% Check that a valid classifier type has been selected.
if ~any(strcmpi({'Count', 'Death', 'Split', 'Migration'}, aType))
    error(['aType must be Count, Death, Split or Migration. '...
        'The given input was %s'], aType)
end

% Append the file extension .mat if it has not already been specified.
if length(aFilename) < 4 || ~strcmp(aFilename(end-3:end), '.mat')
    aFilename = [aFilename '.mat'];
end

% Folders that contain classifiers. They have sub-folders for the different
% classifier types.
classifierLocations = {...
    FindFile('Classifiers')
    FindFile('LegacyClassifiers')};

for i = 1:length(classifierLocations)
    % Get the full paths of the folder and all sub-folders.
    classifierFolder = fullfile(classifierLocations{i}, aType);
    classifierFolders = textscan(genpath(classifierFolder), '%s',...
        'delimiter', pathsep);
    classifierFolders = classifierFolders{1};
    
    for j = 1:length(classifierFolders)
        candidatePath = fullfile(classifierFolders{j}, aFilename);
        if exist(candidatePath, 'file')
            oPath = candidatePath;
            return
        end
    end
end

error('The %s classifier file %s does not exist\n', lower(aType), aFilename)
end