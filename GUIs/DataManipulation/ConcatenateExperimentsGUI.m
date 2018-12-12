function ConcatenateExperimentsGUI()
% Creates a GUI for concatenation of experiment folders.
%
% By using button enabling, the user is guided to first add experiments,
% specify a destination directory, then finally merge the experiments.
%
% The merging concatenates the image sequences of the experiments so that
% multiple short time-lapse experiments are combined into a longer
% experiment. This can be useful if the imaging is stopped during a long
% time-lapse experiment and restarted with a new experiment folder name.
% For the merging to work, all experiments need to have the same number of
% image sequence folders and the image sequence folders must be in the same
% alphabetical order in each experiment. If the image sequence folders to
% be concatenated have different names in the different experiments, the
% names in the first experiment will be used in the merged experiment. The
% individual images will be given names which start with the name of the
% image sequence folder and end with '_t' followed by a zero-padded index
% starting from 000001 for the first image. The function can handle images
% with the file extensions tif, tiff, png, jpg, and jpeg.


% Paths of experiment folders that will be merged.
unmergedExperiments = {};
% Path of the merged experiment that will be created.
mergedDestination = [];
% Previously selected experiment folder where the folder dialog starts.
prevExPath = [];

mainFigure = figure(...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Concatenate Experiments GUI',...
    'Units', 'normalized',...
    'Position', [0.3 0.1 0.4 0.4]);

% ui controls
uicontrol('Style', 'text',...
    'String', 'Select the experiment folders that you want to merge',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.86, 0.9, 0.1]);

openExperimentsButton = uicontrol('Style', 'pushbutton',...
    'String', 'Open Experiments',...
    'Units', 'normalized',...
    'Position', [0.05, 0.85, 0.15, 0.05],...
    'Callback', @Cb_OpenExperimentGUI);

removeExperimentsButton = uicontrol('Style', 'pushbutton',...
    'String', 'Remove Experiments',...
    'Enable', 'off',...
    'Units', 'normalized',...
    'Position', [0.05, 0.78, 0.15, 0.05],...
    'Callback', @Cb_RemoveExperiments);

exPathListBox = uicontrol('Style', 'listbox',...
    'Min', 0,...
    'Max', 2,...
    'Value', [],...
    'String', unmergedExperiments,...
    'Units', 'normalized',...
    'Position', [0.25, 0.5, 0.7, 0.4]);

uicontrol('Style', 'text',...
    'String', 'Select the blank output folder that will hold the merged experiments',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.36, 0.9, 0.1]);

chooseDestination = uicontrol('Style', 'pushbutton',...
    'Enable', 'off',...
    'String', 'Choose Output Folder',...
    'Units', 'normalized',...
    'Position', [0.05, 0.35, 0.15, 0.05],...
    'Callback', @Cb_ChooseDestinationGUI);

destinationDir = uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'HorizontalAlignment', 'left',...
    'Position', [0.25, 0.35, 0.7, 0.05]);

mergeButton = uicontrol('Style', 'pushbutton',...
    'String', 'Merge Experiments',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'Position', [0.35, 0.15, 0.3, 0.1],...
    'Callback', @Cb_Merge);

mergeStatus = uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.35, 0.07, 0.4, 0.05]);

InfoDialog('InfoMergeExperimentsGUI', 'Concatenate experiments',...
    ['This user interface lets you combine multiple short time-lapse '...
    'experiments into a longer experiment, by concatenating the image '...
    'sequences. This can be useful if the imaging is stopped during a '...
    'long time-lapse experiment and restarted with a new experiment '...
    'folder name. For the merging to work, all experiments need to '...
    'have the same number of image sequence folders and the image '...
    'sequence folders must be in the same alphabetical order in each '...
    'experiment. If the image sequence folders to be concatenated have '...
    'different names in the different experiments, the names in the '...
    'first experiment will be used in the merged experiment. The '...
    'individual images will be given names which start with the name '...
    'of the image sequence folder and end with ''_t'' followed by a '...
    'zero-padded index starting from 000001 for the first image.'])

    function Cb_OpenExperimentGUI(~, ~)
        % Opens a dialog box for selection of multiple experiments.
        
        if ~isempty(prevExPath)
            exPath = fileparts(prevExPath);
        else
            exPath = [];
        end
        tmpExPath = UiGetMultipleDirs('Path', exPath, 'MultiSelect', true);
        % Open or add a single experiment.
        if ischar(tmpExPath)
            AddExperiment(tmpExPath)
            % Multiple Selection
        elseif iscell(tmpExPath)
            AddExperiment(tmpExPath{1})
            for addIndex = 2:length(tmpExPath)
                AddExperiment(tmpExPath{addIndex})
            end
        end
        % If the user cancels in UiGetMultipleDirs the tmpExPath is []
        % which is considered a double array, so nothing is added.
    end

    function Cb_ChooseDestinationGUI(~, ~)
        % Opens a dialog box for selection of destination folder.
        
        tmpExPath = uigetdir(fileparts(unmergedExperiments{1}),...
            'Select Output Folder For Merged Experiments');
        % Check to make sure a folder is selected, and that it is not
        % one of the experiment folders selected for merging.
        if ischar(tmpExPath)
            if ~any(strcmpi(unmergedExperiments, tmpExPath))
                SetDestinationDir(tmpExPath)
            else
                errordlg('The folder you selected is one of the experiment folders.',...
                    'Invalid Output Folder')
            end
        end
    end

    function AddExperiment(aExPath)
        % Adds a new experiment folder to be merged.
        %
        % Inputs:
        % aExPath - Directory containing folders with the image sequences
        %           of the experiment to be merged.
        
        if any(strcmpi(unmergedExperiments, aExPath))
            msgbox(sprintf('Experiment "%s" has already been added.', aExPath), 'Notice')
            return
        end
        AddExPath(aExPath)
    end

    function Cb_RemoveExperiments(~, ~)
        % Removes selected experiments from the list of unmerged folders.
        
        indices = get(exPathListBox, 'Value');
        unmergedExperiments(indices)= [];
        % Updates listbox UI
        set(exPathListBox, 'String', unmergedExperiments)
        set(exPathListBox, 'Value', [])
        % If the user removes all the experiments, removing experiments,
        % setting the destination directory, and merging should be disabled
        if isempty(unmergedExperiments)
            set(openExperimentsButton, 'String', 'Open Experiments')
            set(removeExperimentsButton, 'Enable', 'off')
            set(chooseDestination, 'Enable', 'off')
            set(destinationDir, 'Enable', 'off')
            set(mergeButton, 'Enable', 'off')
            set(mergeStatus, 'String', '')
        end
    end

    function AddExPath(aExPath)
        % Adds an experiment to the merging list and updates the GUI.
        %
        % Inputs:
        % aExPath - Path of the experiment to be added.
        
        % Update experiment listbox.
        unmergedExperiments = [unmergedExperiments; {aExPath}];
        set(exPathListBox, 'String', unmergedExperiments)
        set(openExperimentsButton, 'String', 'Add Experiments')
        prevExPath = aExPath;
        % Allows user to now select a destination directory
        set(chooseDestination, 'Enable', 'on')
        set(destinationDir, 'Enable', 'on')
        % Allows user to remove experiments
        set(removeExperimentsButton, 'Enable', 'on')
    end

    function SetDestinationDir(aDestPath)
        % Specifies a destination folder.
        %
        % The function sets the destination folder that the experiments
        % will be merged into and updates the uicontrol text with the path
        % of the destination folder.
        %
        % Inputs:
        % aDestPath - Path of the destination folder.
        
        mergedDestination = aDestPath;
        set(destinationDir, 'String', mergedDestination)
        set(mergeButton, 'Enable', 'on')
    end

    function Cb_Merge(~, ~)
        % Callback which calls the function which performs the merge.
        %
        % The function checks if the destination folder is empty, and if it
        % is not, gives the user a warning dialog.
        
        % numel(dir(path)) returns 2 when a folder is empty
        if numel(dir(mergedDestination)) > 2
            choice = questdlg(...
                ['The specified output folder already has contents. '...
                'Merge and overwrite files?'],...
                'Merge Warning', 'Yes', 'No', 'Cancel', 'No');
            switch choice
                case {'No', 'Cancel'}
                    return;
                otherwise
            end
        end
        MergeExperiments()
        set(mergeStatus, 'String',...
            sprintf('Merge Status: (%d/%d) Complete',...
            length(unmergedExperiments),...
            length(unmergedExperiments)))
    end

    function MergeExperiments()
        % Merges experiment directories into the destination directory.
        
        for i = 1 : length(unmergedExperiments)
            set(mergeStatus, 'String',...
                sprintf('Merge Status: Merging... (%d/%d)',...
                i, length(unmergedExperiments)))
            drawnow()
            
            seqDirs = GetSeqDirs(unmergedExperiments{i});
            
            if i == 1
                % Counter array to keep track of how many images have been
                % copied in each sequence.
                numImagesCopied = zeros(length(seqDirs),1);
                % The names of the images sequence folders in the first
                % experiment are used in the merged experiment.
                firstSeqDirs = seqDirs;
            end
            
            % Copy image sequence folders.
            for j = 1 : length(seqDirs)
                srcSeqPath = fullfile(unmergedExperiments{i} ,seqDirs{j});
                dstSeqPath = fullfile(mergedDestination, firstSeqDirs{j});
                
                imageNames = GetNames(srcSeqPath,...
                    {'tif' 'tiff' 'png' 'jpg' 'jpeg'});
                
                % Create an image sequence folder if necessary.
                if ~exist(dstSeqPath, 'dir')
                    mkdir(dstSeqPath);
                end
                
                % Copy images.
                for k = 1 : length(imageNames)
                    % Full path to the image to be copied.
                    source = fullfile(srcSeqPath, imageNames{k});
                    
                    % Full path of the image copy to be created.
                    destination = fullfile(dstSeqPath,...
                        sprintf('%s_t%06d.tif',...
                        firstSeqDirs{j}, numImagesCopied(j)+1));
                    
                    % Copy the image.
                    copyfile(source, destination, 'f');
                    
                    numImagesCopied(j) = numImagesCopied(j) + 1;
                end
            end
        end
    end
end