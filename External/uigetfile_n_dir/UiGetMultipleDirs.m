function oPath = UiGetMultipleDirs(varargin)
% Java-GUI that allows selection of multiple directories.
%
% The function is similar to the built in function uigetdir, but it allows
% selection of multiple directories. Some of the code is from
% uigetfile_n_dir on MATLAB File Exchange. The function uses the java class
% JFileChooser.
%
% Property/Value inputs:
% Path - Full path of starting directory. The default is the current path.
% Title - Title of the dialog box.
% MultiSelect - If this is set to true, multiple directories can be
%               selected simultaneously. By default it is set to false.
%
% Outputs:
% oPath - If a single directory is selected, this is a character array with
%         the full path of the selected directory. If multiple directories
%         are selected, it is a cell array with paths. If the user presses
%         cancel, the output is [].

import javax.swing.JFileChooser;

% Parse property/value inputs.
[aPath, aTitle, aMultiSelect] = GetArgs(...
    {'Path', 'Title', 'MultiSelect'},...
    {pwd, '', false},...
    true, varargin);

% Create the dialog object (it is not shown yet).
jchooser = javaObjectEDT('javax.swing.JFileChooser', aPath);

% Only directories and no files will show up in the dialog box.
jchooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);

if ~isempty(aTitle)
    jchooser.setDialogTitle(aTitle);
end

jchooser.setMultiSelectionEnabled(aMultiSelect);

% Show the dialog and let the user make a selection.
status = jchooser.showOpenDialog([]);

% Process the users selection.
if status == JFileChooser.APPROVE_OPTION
    if ~aMultiSelect
        jFile = jchooser.getSelectedFile();
        oPath = char(jFile.getAbsolutePath);
    else
        jFile = jchooser.getSelectedFiles();
        
        if length(jFile) == 1
            oPath = char(jFile(1).getAbsolutePath);
        else
            oPath = cell(length(jFile),1);
            for i=1:size(jFile, 1)
                oPath{i} = char(jFile(i).getAbsolutePath);
            end
        end
    end
elseif status == JFileChooser.CANCEL_OPTION
    oPath = [];
else
    error('Error occured while picking file.');
end