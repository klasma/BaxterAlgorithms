function AddJavaPaths(varargin)
% Adds all java paths required by the Baxter Algorithms.
%
% The paths are added using the javaaddpath command, which also clears all
% variables. Therefore, the function cannot be run from within another
% function which has GUI-callbacks, because the callbacks will be cleared.
% The function can also add the required paths permanently to the
% javaclass.txt file in prefdir. The function will not add additional
% copies of paths that have already been added.
%
% Property/Value inputs:
% Permanent - If this is set to true, the paths will be added permanently
%             to javaclasspath.txt.
%
% See also:
% RequiredJavaPaths, CheckJavaPaths

% Get property/value inputs.
aPermanent = GetArgs({'Permanent'}, {false}, true, varargin);

requiredPaths = RequiredJavaPaths();

% Add the paths for the rest of this MATLAB session. This also clears all
% variables.
missingPaths = setdiff(requiredPaths, javaclasspath('-all'));
for i = 1:length(missingPaths)
    javaaddpath(missingPaths{i})
end

if aPermanent
    % Add the paths permanently.
    missingPaths = setdiff(requiredPaths, javaclasspath('-static'));
    if ~isempty(missingPaths)
        pathFile = fullfile(prefdir(),'javaclasspath.txt');
        append = exist(pathFile, 'file');
        fid = fopen(pathFile, 'a');
        for i = 1:length(missingPaths)
            if i > 1 || append
                fprintf(fid, '\r\n');
            end
            fprintf(fid, '%s', requiredPaths{i});
        end
        fclose(fid);
    end
end
end