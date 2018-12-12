function oNames = GetNames(aFolder, aType)
% Returns the names of files and folders on a path.
%
% Inputs:
% aFolder - The path of a folder. This can be an absolute path or a
%           relative path such as '../Images'.
% aType - Optional input argument specifying a file type. If this inputs is
%         given, only files of the specified type will be returned.
%         Directories are specified using the empty string ''. Cell arrays
%         with multiple file extensions can be given, and then the function
%         will return files from all of the file types. If '' is included
%         in a cell array, files with no extension will be returned.
%
% Outputs:
% oNames - Cell array of strings with the filenames sorted alphabetically.
%          The file types are included in the filenames, but the path to
%          the files is not.
%
% See also:
% GetSeqDirs, GetUseSeq

jFile = java.io.File(aFolder);

if nargin == 1
    % All files and directories.
    jList = jFile.listFiles();
elseif isempty(aType)
    % Directories.
    directoryFilter =...
        org.apache.commons.io.filefilter.DirectoryFileFilter.DIRECTORY;
    jList = jFile.listFiles(directoryFilter);
else
    % Make aType be a cell array of types.
    if ischar(aType)
        aType = {aType};
    end
    
    % Files of a specified type.
    jExtensions = javaArray('java.lang.String', length(aType));
    for i = 1:length(aType)
        jExtensions(i) = java.lang.String(['.' aType{i}]);
    end
    suffixFilter = org.apache.commons.io.filefilter.SuffixFileFilter(...
        jExtensions, org.apache.commons.io.IOCase.INSENSITIVE);
    
    % Include only files, not directories.
    fileFilter = org.apache.commons.io.filefilter.FileFileFilter.FILE;
    
    % Skip "._" metadata files created by OS X.
    prefixFilter = org.apache.commons.io.filefilter.NotFileFilter(...
        org.apache.commons.io.filefilter.PrefixFileFilter('._'));
    
    % Combine the filters together and apply them
    andFilter = org.apache.commons.io.filefilter.AndFileFilter(...
        fileFilter, suffixFilter);
    finalFilter = org.apache.commons.io.filefilter.AndFileFilter(...
        andFilter, prefixFilter);
    
    jList = jFile.listFiles(finalFilter);
end

oNames = cell(length(jList),1);
for i = 1:length(jList)
    % arrayfun does not make this faster.
    oNames{i} = jList(i).getName();
end
oNames = cellfun(@char, oNames, 'UniformOutput', false);

% Sort the files alphabetically.
oNames = sort(oNames);
end