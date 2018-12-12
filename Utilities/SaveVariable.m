function SaveVariable(aName, aVal) %#ok<INUSD>
% Saves a value to a mat-file so that it can be loaded using LoadVariable.
%
% The variables are saved to a file named variables.mat in a folder named
% MATfiles. The purpose of loading and saving variables to this file is to
% remember user choices between sessions. If there are other variables
% saved to variables.mat, this function appends the new variable to the
% file.
%
% Inputs:
% aName - Name that the value will be saved under.
% aVal - Value to save.
%
% See also:
% LoadVariable

% Create a variable with the desired name.
eval([aName ' = aVal;'])

% Path of mat-file.
saveName = FindFile('variables.mat');

% Save the variable to the mat-file.
if exist(saveName, 'file')
    save(saveName, aName, '-append')
else
    save(saveName, aName)
end
end