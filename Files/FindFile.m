function oPath = FindFile(varargin)
% Returns the full path of a data file.
%
% All data files are stored in a folder named Files which is located in the
% same place as the main m-file of the program. To get the path of a data
% file, the user specifies the path of the file relative to the
% Files-folder. This makes it possible to have sub-folders inside the
% Files-folder. The syntax of the function is the same as that of the
% built in function fullfile. The function was introduced to handle
% relative paths in deployed applications, because the folder tree can
% be changed in deployment. The function assumes that the Files-folder is
% placed directly under ctfroot in deployment, which seems reasonable. It
% is also good to have all data files in the same location when deployment
% is performed. The function does not check if the file exists.
%
% Inputs:
% varargin - Input arguments with the same structure as the inputs given to
%            fullfile. The inputs should be a sequence of possible
%            sub-folders, followed by the name of the file, including the
%            file extension.
%
% Outputs:
% oPath - Full path of the data file, in deployed or un-deployed
%         applications.
%
% See also:
% GetNames, GetClassifierPath, fullfile

if isdeployed()
    root = fullfile(ctfroot(), 'Files');
else
    root = fileparts(mfilename('fullpath'));
end

oPath = fullfile(root, varargin{:});
end