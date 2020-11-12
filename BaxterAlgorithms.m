function BaxterAlgorithms()
% Starts the Baxter Algorithms, a software package for cell tracking.
%
% The Baxter Algorithms is a software package which can do segmentation and
% tracking of live cells in transmission microscopy and fluorescence
% microscopy. In fluorescence microscopy, the program can process both 2D
% images and 3D z-stacks, and it can handle both cytoplasmic and nuclear
% fluorescence. In transmission microscopy, the program can only handle 2D
% images. The program can also be used to analyze single images of muscle
% histology imaged using fluorescence microscopy. There are graphical user
% interfaces for segmentation of cells, manual correction of tracking
% results, analysis of tracks, and many other things.
%
% The program assumes that image sequences are saved as folders containing
% images for the individual time points. The file extensions tif, tiff,
% png, jpg, and jpeg are supported. For 3D data, the images associated with
% one z-stack can be either individual images for the different z-planes a
% tif-stack. A folder containing one or multiple image sequence folders is
% called an experiment (folder). The program can have one or more
% experiments open and the names of the image sequences in these
% experiments are displayed in a listbox to the right in the main figure.
% The user selects image sequences from this list and chooses functions to
% run with these sequences as inputs, in the menus of the main figure. When
% sequences are selected, thumbnails of the first images of the sequences
% are shown in the left side of the main figure.
%
% For a more detailed description of the software package, the reader is
% referred to the user guide in pdf-format, which can be opened by pressing
% the 'Help->User guide' menu option.
%
% See also:
% SegmentationPlayer, ProcessDirectory, ManualCorrectionPlayer

if ~isdeployed
    % Add necessary paths.
    subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s', 'delimiter', pathsep);
    addpath(subdirs{1}{:});
else
    % Set the java look-and-feel depending on the platform. Otherwise a
    % cross-platform look-and-feel where the outlines of buttons are
    % missing and where all menu options have a square in front of them.
    if ispc()
        javax.swing.UIManager.setLookAndFeel(...
            'com.sun.java.swing.plaf.windows.WindowsLookAndFeel')
    elseif ismac()
        javax.swing.UIManager.setLookAndFeel(...
            'com.apple.laf.AquaLookAndFeel')
    elseif isunix()
        % True also for Macs, but we have already dealt with Macs.
        javax.swing.UIManager.setLookAndFeel(...
            'com.jgoodies.looks.plastic.Plastic3DLookAndFeel')
    end
end

% Add necessary java paths if they are not already added.
if ~isdeployed && ~CheckJavaPaths()
    % Print out missing java paths.
    fprintf('You need to add the folders:\n')
    missingPaths = setdiff(RequiredJavaPaths(), javaclasspath('-all'));
    for i = 1:length(missingPaths)
        fprintf('%s\n', missingPaths{i})
    end
    fprintf('to\n%s\n', fullfile(prefdir, 'javaclasspath.txt'))
    
    % Create a dialog where the user can decide how to add the paths.
    choise = questdlg(...
        ['The Baxter Algorithms needs to add java paths to MATLAB. '...
        'It is recommended that you let the program add the paths to ',...
        'javaclasspath.txt. You can also let the program add the paths ',...
        'temporarily (using javaaddpath), or add the paths yourself. '...
        'The required paths have been printed to the terminal. '...
        'You will need to restart the program after this dialog closes.'],...
        'Add java paths',...
        'Add paths javaclasspath.txt', 'Add paths temporarily', 'Cancel',...
        'Add paths javaclasspath.txt');
    
    switch choise
        case 'Add paths javaclasspath.txt'
            AddJavaPaths('Permanent', true)
        case 'Add paths temporarily'
            AddJavaPaths('Permanent', false)
    end
    % The program needs to be restarted, because the command javaaddpaths
    % clears all the callbacks of the GUI (even before they are created).
    % javaaddpath is called even when the paths are added to
    % javaclasspath.txt, because MATLAB needs to be restarted before those
    % changes take effect. For some reason, the callbacks don't come back
    % if the program is restarted from within the code. The use has to
    % restart the program manually.
    return
end

% Upper limit on the length of the lists of previously opened experiments.
MAX_PREVEX = 10;

exPathsUni = {};                % The paths of the the open experiments.
seqDirs = {};                   % Names of all image sequences.
seqPaths = {};                  % Full paths to image sequences.
imDatas = {};                   % Cached ImageData objects for seqPaths.
vers = {};                      % Tracking versions of the image sequences.
% Cell array where every cell contains a
% cell array of strings with the tracking
% versions of the corresponding sequence.
conds = {};                     % Culturing conditions of the images sequences.
selAlts = {'all', 'unknown'};   % Alternatives for "selPopupMenu".
selTypes = {'all', 'unknown'};  % Specifies the type of every alternative
% in "selAlts" ('all', 'unknown', 'ver' or 'cond').

mainFigure = figure(...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Baxter Algorithms',...
    'Units', 'normalized',...
    'Position', [0.1 0.1 0.8 0.8],...
    'CloseRequestFcn', @Close);

% Queue where the user can put computations for later execution.
queue = Queue();

% Paths of experiments that have been opened previously. These experiments
% will appear in lists next to File->Open Experiment and File->Add
% Experiment.
prevExPaths = LoadVariable('BaxterAlgorithms_prevExPaths');
prevExPaths = prevExPaths(1:min(MAX_PREVEX, length(prevExPaths)));

% Page number. If more than 20 images are selected, the images are
% arranged on multiple pages. "pageNum" stores the index of the page
% currently shown.
pageNum = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MENU OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data used to create the menus is put in the cell array "menus". The first
% column contains the labels on the menus, the second column contains
% levels specifying how advanced the settings are ('basic', 'advanced', or
% 'development'), and the third column contains either callbacks or cell
% arrays with sub-menus.

file = {...
    'Open experiment',              'basic',        @(aObj, aEvent)disp([])
    'Add experiment',               'advanced',     @(aObj, aEvent)disp([])
    'Remove experiment',            'advanced',     @(aObj, aEvent)RemoveExperiment()
    'Concatenate experiments',      'advanced',     @(aObj, aEvent)ConcatenateExperimentsGUI()
    'Copy sequences',               'advanced',     @(aObj, aEvent)CopySeq()
    'Move sequences',               'advanced',     @(aObj, aEvent)MoveSeq()
    'Delete sequences',             'advanced',     @(aObj, aEvent)DeleteSeq()
    'Export tracks to CTC format',  'advanced',     @(aObj, aEvent)disp([])
    'Close all',                    'advanced',     @(aObj, aEvent)CloseAll()
    'Invert selection',             'advanced',     @(aObj, aEvent)InvertSelection()
    'Random selection',             'advanced',     @(aObj, aEvent)RandomSelection()
    'Convert merged images',        'advanced',     @(aObj, aEvent)ConvertMergedImagesGUI()};

settings = {...
    'Settings',                         'basic',        @(aObj, aEvent)Settings()
    'Save Settings',                    'advanced',     @(aObj, aEvent)CallbackSel(false, @SaveSettingsGUI)
    'Load Settings',                    'basic',        @(aObj, aEvent)CallbackSel(false, @LoadSettingsImageGUI, 'CloseFunction', @Update)
    'Load Settings (browse for file)',  'advanced',     @(aObj, aEvent)CallbackSel(false, @LoadSettingsGUI, 'CloseFunction', @Update)
    'Set segmentation parameters',      'basic',        @(aObj, aEvent)CreatePlayer(false, 'Segmentation')
    'Optimize segmentation parameters', 'advanced',     @(aObj, aEvent)CallbackSel(false, @SegmentationOptimization)
    'Train classifiers',                'advanced',     @(aObj, aEvent)CallbackSel(true, @TrainClassifierGUI, queue)
    'Set fluorescence display',         'basic',        @(aObj, aEvent)CreatePlayer(false, 'Fluorescence')};

automated = {...
    'Stabilize',                            'basic',        @(aObj, aEvent)CallbackSel(false, @StabilizationGUI, queue, 'ExitFunction', @SwitchExQuestion)
    'Cut microwells',                       'advanced',     @(aObj, aEvent)CallbackSel(false, @CuttingGUI, queue, 'ExitFunction', @SwitchExQuestion)
    'Track',                                'basic',        @(aObj, aEvent)CallbackSel(false, @TrackingGUI, queue, 'ExitFunction', @UpdateSelPopupMenu)
    'Replace segmentation',                 'development',  @(aObj, aEvent)CallbackSel(true, @ReplaceSegmentation, queue, 'ExitFunction', @UpdateSelPopupMenu)};

manual = {...
    'Play',                     'basic',        @(aObj, aEvent)CreatePlayer(false, 'Z')
    'Track Correction',         'basic',        @(aObj, aEvent)CreatePlayer(false, 'Correction')
    'Fiber Correction',         'basic',        @(aObj, aEvent)CreatePlayer(false, 'FiberCorrection')};

analysis = {...
    'Cell Analysis GUI',                        'basic',        @(aObj, aEvent)CreatePlayer(true, 'Analysis')
    'Population Analysis GUI',                  'basic',        @(aObj, aEvent)CallbackSel(true, @PopulationAnalysisGUI)
    'Scatter Plot Analysis GUI',                'advanced',     @(aObj, aEvent)CallbackSel(true, @ScatterPlotGUI)
    'Fiber analysis GUI',                       'basic',        @(aObj, aEvent)CallbackSel(false, @FiberAnalysisGUI)
    'Central nuclei GUI',                       'development',  @(aObj, aEvent)CallbackSel(false, @CentralNucleiGUI)
    'Myotube fusion analysis GUI',              'advanced',     @(aObj, aEvent)CallbackSel(false, @FusionIndexGUI)
    'Plot GUI',                                 'advanced',     @(aObj, aEvent)CallbackSel(false, @PlotGUI)
    'Save plots',                               'advanced',     @(aObj, aEvent)SavePlotsGUI()
    'Statistics',                               'advanced',     @(aObj, aEvent)CallbackSel(true, @ExportStatistics)
    'TRA Tracking performance',                 'advanced',     @(aObj, aEvent)CallbackSel(true, @PerformanceTRAGUI, queue)
    'SEG Segmentation performance',             'advanced',     @(aObj, aEvent)CallbackSel(true, @PerformanceSEGGUI, queue)};

levels = {...
    'basic',        'basic', @LevelCallback
    'advanced',     'basic', @LevelCallback
    'development',  'basic', @LevelCallback};

helpmenu = {...
    'User guide',              'basic',     @OpenUserGuide
    'Information dialogs',     'advanced',  @(aObj, aEvent)disp([])
    'About Baxter Algorithms', 'basic',     @(aObj, aEvent)AboutBaxterAlgorithms()};

% Cell array with all menus of the figure.
menus = {...
    ' File ',                   'basic',        file
    ' Settings ',               'basic',        settings
    ' Automated ',              'basic',        automated
    ' Manual ',                 'basic',        manual
    ' Analysis ',               'basic',        analysis
    ' Level ',                  'basic',        levels
    ' Help ',                   'basic',        helpmenu};

menus = CreateMenus(mainFigure, menus);

% Get handles of menu objects that need to be accessed later.
basicMenu = GetMenu(mainFigure, ' Level ', 'basic');
advancedMenu = GetMenu(mainFigure, ' Level ', 'advanced');
developmentMenu = GetMenu(mainFigure, ' Level ', 'development');
openMenu = GetMenu(mainFigure, ' File ', 'Open experiment');
addMenu = GetMenu(mainFigure, ' File ', 'Add experiment');
ctcMenu = GetMenu(mainFigure, ' File ', 'Export tracks to CTC format');
infoMenu = GetMenu(mainFigure, ' Help ', 'Information dialogs');

% Sub-menu for opening new or previously opened experiments.
uimenu(openMenu,...
    'Label', 'Browse...',...
    'Callback', @(aObj, aEvent)OpenOrAddExperimentGUI('open'));
for p = 1:length(prevExPaths)
    uimenu(openMenu,...
        'Label', prevExPaths{p},...
        'Callback', @(aObj, aEvent)OpenOrAddExperiment(prevExPaths{p}, 'open'));
end

% Sub-menu for adding new or previously opened experiments.
uimenu(addMenu,...
    'Label', 'Browse...',...
    'Callback', @(aObj, aEvent)OpenOrAddExperimentGUI('add'));
for p = 1:length(prevExPaths)
    uimenu(addMenu,...
        'Label', prevExPaths{p},...
        'Callback', @(aObj, aEvent)OpenOrAddExperiment(prevExPaths{p}, 'add'));
end

uimenu(ctcMenu,...
    'Label', 'RES tracks',...
    'Callback', @(aObj, aEvent)CallbackSel(true, @CTCExportGUI, 'RES'))
uimenu(ctcMenu,...
    'Label', 'SEG ground truth',...
    'Callback', @(aObj, aEvent)CallbackSel(true, @CTCExportGUI, 'SEG'))
uimenu(ctcMenu,...
    'Label', 'TRA ground truth',...
    'Callback', @(aObj, aEvent)CallbackSel(true, @CTCExportGUI, 'TRA'))

uimenu(infoMenu,...
    'Label', 'Display all',...
    'Callback', @DisplayAllInfo_Callback);
uimenu(infoMenu,...
    'Label', 'Display none',...
    'Callback', @DisplayNoInfo_Callback);

% Set the menus level. If the GUI has been opened before, the level
% selected when the GUI was last closed is used. Otherwise, 'basic' is
% used.
level = LoadVariable('BaxterAlgorithms_level');
if isempty(level)
    level = 'basic';
end
switch level
    case 'basic'
        set(basicMenu, 'Checked', 'on')
    case 'advanced'
        set(advancedMenu, 'Checked', 'on')
    case 'development'
        set(developmentMenu, 'Checked', 'on')
    otherwise
        error('Unknown level %s.\n', level)
end
SetVisibleMenus(menus, level)

% Order of control objects. Each cell contains the controls on one row.
order = [...
    {{'exLabel'}}
    {{'exListBox'}}
    {{'seqLabel'}}
    {{'seqListBox'}}
    {{'selLabel'}}
    {{'selPopupMenu'}}
    {{'previousButton' 'nextButton'}}];

% Relative positions in the format
% [left margin, top margin, width, height].
positions = struct(...
    'exLabel',          [0.8,  0.01,  0.19, 0.02],...
    'exListBox',        [0.8,  0.005, 0.19, 0.25],...
    'seqLabel',         [0.8,  0.01,  0.19, 0.02],...
    'seqListBox',       [0.8,  0.005, 0.19, 0.54],...
    'selLabel',         [0.8,  0.01,  0.19, 0.02],...
    'selPopupMenu',     [0.8,  0.005, 0.19, 0.02],...
    'previousButton',   [0.8,  0.02,  0.09, 0.05],...
    'nextButton',       [0.01, 0.02,  0.09, 0.05]);

% Convert the relative positions to absolute positions.
top = 1;
for i = 1:length(order)
    field1 = order{i}{1};
    pos1 = positions.(field1);
    deltaH = pos1(2) + pos1(4);
    left = 0;
    for j = 1:length(order{i})
        field2 = order{i}{j};
        pos2 = positions.(field2);
        p1.(field2) = left + pos2(1);
        p2.(field2) = top - deltaH;
        left = left + pos2(1) + pos2(3);
    end
    top = top - deltaH;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UI-CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

exLabel = uicontrol('Style', 'text',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Experiments',...
    'Units', 'normalized',...
    'Tooltip', 'Paths of experiments that the images sequences belong to'); %#ok<NASGU>
exListBox = uicontrol('Style', 'listbox',...
    'Min', 0,...
    'Max', 2,...
    'Value', [],...
    'String', exPathsUni,...
    'Units', 'normalized',...
    'Tooltip', 'Paths of experiments that the images sequences belong to',...
    'Callback', @ExListBox_Callback);
seqLabel = uicontrol('Style', 'text',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', sprintf('Image sequences %d / %d', 0, length(seqDirs)),...
    'Units', 'normalized',...
    'Tooltip', 'Select image sequences to process');
seqListBox = uicontrol('Style', 'listbox',...
    'Min', 0,...
    'Max', 2,...
    'Value', [],...
    'String', seqDirs,...
    'Units', 'normalized',...
    'Tooltip', 'Select image sequences to process',...
    'Callback', @SeqListBox_Callback);
selLabel = uicontrol('Style', 'text',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Select',...
    'Units', 'normalized',...
    'Tooltip', 'Selects groups of image sequences'); %#ok<NASGU>
selPopupMenu =  uicontrol(...
    'BackgroundColor', 'white',...
    'HorizontalAlignment', 'left',...
    'Units', 'Normalized',...
    'Style', 'popupmenu',...
    'String', selAlts,...
    'Value', find(strcmp(selTypes, 'unknown')),...
    'Tooltip', 'Selects groups of image sequences',...
    'Callback', @SelPopupMenu_Callback);
previousButton = uicontrol('Style', 'pushbutton',...
    'Enable', 'off',...
    'String', 'Previous 20',...
    'Units', 'normalized',...
    'Tooltip', 'Show thumbnails for the previous 20 image sequences',...
    'Callback', @PreviousButton_Callback);
nextButton = uicontrol('Style', 'pushbutton',...
    'Enable', 'off',...
    'String', 'Next 20',...
    'Units', 'normalized',...
    'Tooltip', 'Show thumbnails for the following 20 image sequences',...
    'Callback', @NextButton_Callback);

% Position the controls.
for i = 1:length(order)
    for j = 1:length(order{i})
        eval(['set(' order{i}{j} ,...
            ',''Position'', ['...
            num2str([p1.(order{i}{j}),...
            p2.(order{i}{j}),...
            positions.(order{i}{j})(3),...
            positions.(order{i}{j})(4)]) '])'])
    end
end

if ispc
    set(seqListBox, 'BackgroundColor', 'white');
    set(exListBox, 'BackgroundColor', 'white');
else
    % Don't know why I added this. Probably to make the GUI look nicer on
    % unix. The GUI might also look nicer on Mac.
    set(seqListBox,...
        'BackgroundColor', get(0,'defaultUicontrolBackgroundColor'));
    set(exListBox,...
        'BackgroundColor', get(0,'defaultUicontrolBackgroundColor'));
end

% Create empty axes objects to show selected images in, and empty labels to
% display image sequence names.
smallPictures = cell(1,20);
smallLabels = cell(1,20);
for i=0:3
    for j=1:5
        smallPictures{i*5+j} = axes(...
            'Units', 'normalized',...
            'Position', [0.01+i*0.2 1-j*0.2 0.18 0.18]);
        smallLabels{i*5+j} = uicontrol(...
            'Style', 'text',...
            'BackgroundColor', get(mainFigure, 'color'),...
            'Units', 'normalized',...
            'Position', [0.01+i*0.2, 0.98-(j-1)*0.2, 0.18, 0.02]);
        axis off
    end
end

% Load the experiments that were open when the program was last closed.
tmp = LoadVariable('BaxterAlgorithms_exPathsUni');
if isempty(tmp)
    % Replace [] by {} to make cellfun work.
    tmp = {};
end
% Remove experiments that no longer exist.
tmp = tmp(cellfun(@(x)exist(x,'dir') > 0, tmp));
OpenOrAddExperiment(tmp, 'open')


% Select the first image when a new experiment is opened.
if ~isempty(seqDirs)
    set(seqListBox, 'Value', 1)
end

% Display thumbnails of selected image sequences.
SeqListBox_Callback(seqListBox, [])

InfoDialog('InfoBaxterAlgorithms', 'Main GUI',...
    ['First open a dataset by pressing '...
    'File->Open Experiment. Then select the image sequences that you '...
    'want to process in the listbox to the right. The available '...
    'processing functions and user interfaces can be found under the '...
    'different menus. The menu alternatives are separated into the 3 '...
    'levels ''basic'', ''advanced'', and ''development'', and you can '...
    'select which alternatives are shown using the Level menu. '...
    'Information about the images is specified under '...
    'Settings->Settings, the image sequences are played under '...
    'Manual->Play. Segmentation settings are specified under '...
    'Settings->Set Segmentation Parameters, tracking settings are '...
    'specified under Settings->Settings. Tracking results are produced '...
    'under Automated->Track. The tracking results can be viewed and '...
    'corrected under Manual->Track Correction, and the results can '...
    'be analyzed using the options on the Analysis menu. A pdf '...
    'manual is available under Help->User Guide.'])

    function AddExPath(aExPaths)
        % Adds an experiment to the set of open experiments.
        %
        % Inputs:
        % aExPaths - Cell array with paths of experiment folders to be
        %           added.
        
        % Update experiment list box.
        exPathsUni = [exPathsUni; aExPaths];
        set(exListBox, 'String', exPathsUni)
        
        for ii = 1:length(aExPaths)
            % Update sequence list box.
            tmpSeqDirs = GetUseSeq(aExPaths{ii});
            seqDirs = [seqDirs; tmpSeqDirs]; %#ok<AGROW>
            if ~isempty(seqDirs)
                seqPaths = [seqPaths; strcat(aExPaths{ii}, filesep, tmpSeqDirs)]; %#ok<AGROW>
                imDatas = [imDatas; cell(size(tmpSeqDirs))]; %#ok<AGROW>
            end
        end
        set(seqListBox, 'String', seqDirs)
        
        UpdateSelPopupMenu()
        AddPrevExPath(aExPaths)
        SaveVariable('BaxterAlgorithms_exPathsUni', exPathsUni)
    end

    function AddPrevExPath(aExPaths)
        % Adds a path to the menus of previously opened experiments.
        %
        % The menus of previously opened experiments let the user open or
        % add one of the experiments by clicking the menu instead of
        % browsing for the experiment again.
        %
        % Inputs:
        % aExPaths - Cell array with experiment paths to be added to the
        %           menus.
        
        for ii = 1:length(aExPaths)
            % Remove the path from the list if it is already on it.
            if any(strcmpi(prevExPaths, aExPaths{ii}))
                delete(GetMenu(mainFigure, ' File ', 'Open experiment', aExPaths{ii}))
                delete(GetMenu(mainFigure, ' File ', 'Add experiment', aExPaths{ii}))
                prevExPaths(strcmpi(prevExPaths, aExPaths{ii})) = [];
            end
            
            % Remove the oldest experiments for the list if necessary.
            for prevIndex = length(prevExPaths) : -1 : MAX_PREVEX
                delete(GetMenu(mainFigure, ' File ', 'Open experiment', prevExPaths{prevIndex}))
                delete(GetMenu(mainFigure, ' File ', 'Add experiment', prevExPaths{prevIndex}))
            end
            prevExPaths = prevExPaths(1:min(MAX_PREVEX-1, length(prevExPaths)));
            
            % Add new menu options.
            uimenu(openMenu,...
                'Position', 2,...
                'Label', aExPaths{ii},...
                'Callback', @(aObj, aEvent)OpenOrAddExperiment(aExPaths{ii}, 'open'));
            uimenu(addMenu,...
                'Position', 2,...
                'Label', aExPaths{ii},...
                'Callback', @(aObj, aEvent)OpenOrAddExperiment(aExPaths{ii}, 'add'));
            prevExPaths = [aExPaths(ii); prevExPaths]; %#ok<AGROW>
        end
        
        % Save "prevExPaths" for future sessions.
        SaveVariable('BaxterAlgorithms_prevExPaths', prevExPaths)
    end

    function CallbackSel(aCheckTracked, aFunction, varargin)
        % Applies a sequence of functions to the selected image sequences.
        %
        % Inputs:
        % aCheckTracked - Boolean variable specifying if the function
        %                 requires a tracked sequence to play. If it does,
        %                 selecting only sequences that have not been
        %                 tracked will produce an error dialog.
        % aFunction - Function handle for the function to be executed. The
        %             function should take a cell array of image sequence
        %             paths as the first input argument.
        % varargin - Additional input arguments to aFunction.
        
        index = get(seqListBox, 'Value');
        
        % No sequences selected.
        if isempty(index)
            errordlg('You have not selected any image sequences to process.')
            return
        end
        
        % No sequences tracked.
        if aCheckTracked && isempty([vers{:}])
            errordlg(['None of the selected image sequences have '...
                'been tracked. There could exist a stabilized or '...
                'cut version of the experiment which has been '...
                'tracked.'], 'No tracking available')
            return
        end
        
        % If the users have not selected all sequences, a dialog is opened
        % to give them the option to select all.
        numSel = length(index);
        numSeq = length(get(seqListBox, 'String'));
        if numSel < numSeq
            if ~SelectAllDlg(numSel, numSeq)
                return
            end
        end
        index = get(seqListBox, 'Value');
        
        % Call the functions.
        feval(aFunction, seqPaths(index), varargin{:})
    end

    function Close( ~, ~)
        % Callback executed before the main figure is closed.
        %
        % The function saves the selected menu level for next time that the
        % GUI is opened.
        
        % Saves the selected menu level so that it can be recalled the next
        % time the GUI is opened.
        SaveVariable('BaxterAlgorithms_level', GetLevel())
        
        delete(mainFigure)
    end

    function CopySeq()
        % Copies the selected image sequences to another experiment.
        
        index = get(seqListBox, 'Value');
        
        % No sequences selected.
        if isempty(index)
            errordlg('You have not selected any image sequences to copy.')
            return
        end
        
        % Select an experiment to copy sequences to.
        tmpExPath = UiGetMultipleDirs(...
            'Title', 'Select an experiment folder',...
            'Path', FileParts2(seqPaths{1}),...
            'MultiSelect', false);
        
        if ~isempty(tmpExPath)
            if exist(fullfile(tmpExPath, 'SettingsLinks.csv'), 'file')
                errordlg(['It is not possible to copy sequences to '...
                    'experiments with linked settings.'])
                return
            end
            seqNames = FileEnd(seqPaths(index));
            for seq = 1:length(seqNames)
                if exist(fullfile(tmpExPath, seqNames{seq}), 'file')
                    errordlg(['The selected experiment already contains '...
                        'an image sequence named ' seqNames{seq} '.'])
                return
                end
            end
            CopySequences(seqPaths(index), tmpExPath);
        end
    end

    function CloseAll()
        % Closes all figures except the main figure.
        
        figs = get(0, 'Children');  % all open figures
        for ii =  1:length(figs)
            if(figs(ii) ~= mainFigure) % Don't delete the main figure.
                delete(figs(ii))
            end
        end
    end

    function CreatePlayer(aCheckTracked, aPlayerType)
        % Opens one of the player GUIs that play image sequences.
        %
        % The different GUIs let the user visualize, edit and analyze image
        % sequences and tracking results in different ways.
        %
        % Inputs:
        % aCheckTracked - Boolean variable specifying if the player
        %                 requires a tracked sequence to play. If it does,
        %                 selecting only sequences that have not been
        %                 tracked will produce an error dialog.
        % aPlayerType - String defining which player to open. The different
        %               alternatives are:
        %               'Z' - Plays 2D image sequences or sequences of 3D
        %                     z-stacks.
        %               'Fluorescence' - Lets the user specify colors and
        %                                dynamic ranges for different
        %                                (fluorescent) channels.
        %               'Segmentation' - Lets the user specify segmentation
        %                                settings for the image sequences
        %                                and look at the corresponding
        %                                segmentations.
        %               'Correction' - Lets the user visualize and correct
        %                              tracks and outlines of cells.
        %               'Features' - Lets the user visualize the values of
        %                            different features of segmented blobs.
        %                            The outputs of classifiers operating
        %                            on the features can also be
        %                            visualized.
        %
        % See also:
        % CallbackSel
        
        index = get(seqListBox, 'Value');
        
        % No sequences selected.
        if isempty(index)
            errordlg('You have not selected any image sequences to process.')
            return
        end
        
        % No sequences tracked.
        if aCheckTracked && isempty([vers{:}])
            errordlg(['None of the selected image sequences have '...
                'been tracked. There could exist a stabilized or '...
                'cut version of the experiment which has been '...
                'tracked.'], 'No tracking available')
            return
        end
        
        switch aPlayerType
            case 'Z'
                ZPlayer(seqPaths(index));
                InfoDialog('InfoZPlayer', 'Settings',...
                    ['You can zoom in by clicking and dragging a '...
                    'rectangle, zoom out again by right-clicking, and '...
                    'pan by holding down the space bar or pressing '...
                    '''m''. If you are viewing slices of 3D data, you '...
                    'can switch to another slice by shift-clicking, or '...
                    'clicking with the center mouse button on the '...
                    'desired slice in one of the other 3D views.'])
            case 'Fluorescence'
                SetFluorescencePlayer(seqPaths(index),...
                    'CloseFunction', @Update);
                InfoDialog('InfoSetFluorescencePlayer',...
                    'Set fluorescence display',...
                    {['You can select colors for the different '...
                    'channels using the dropdown menus, and specify '...
                    'the range of displayed intensity values by '...
                    'clicking and dragging in the gradients or the '...
                    'histograms. Before you can use this GUI, you need '...
                    'to specify the settings channelNames and '...
                    'channelTags.']
                    ''
                    ['You can zoom in by clicking and dragging a '...
                    'rectangle, zoom out again by right-clicking, and '...
                    'pan by holding down the space bar or pressing '...
                    '''m''. If you are viewing slices of 3D data, you '...
                    'can switch to another slice by shift-clicking, or '...
                    'clicking with the center mouse button on the '...
                    'desired slice in one of the other 3D views.']})
            case 'Segmentation'
                SegmentationPlayer(seqPaths(index));
                InfoDialog('InfoSegmentationPlayer',...
                    'Set segmentation parameters',...
                    {['The segmentation settings are separated into '...
                    'the 3 levels ''basic'', ''advanced'', and '...
                    '''development''. You can select which levels to '...
                    'show using the Level menu. The basic level has '...
                    'settings which have to be set properly in order '...
                    'to get a good segmentation. The advanced settings '...
                    'are settings which can improve the segmentation '...
                    'or which are needed for special types of data. '...
                    'The development settings are not needed by the '...
                    'typical user and may not be fully tested.']
                    ''
                    ['If you are changing multiple settings at once, '...
                    'you can save time by unchecking the Update '...
                    'button while you make the changes. If you want '...
                    'to see the segmentations that unsaved settings '...
                    'produce on other image sequences, you need to '...
                    'uncheck the Revert to saved button before you '...
                    'switch to the other sequences.']
                    ''
                    ['You can zoom in by clicking and dragging a '...
                    'rectangle, zoom out again by right-clicking, and '...
                    'pan by holding down the space bar or pressing '...
                    '''m''. If you are viewing slices of 3D data, you '...
                    'can switch to another slice by shift-clicking, or '...
                    'clicking with the center mouse button on the '...
                    'desired slice in one of the other 3D views.']})
            case 'Correction'
                ManualCorrectionPlayer(seqPaths(index));
                InfoDialog('InfoManualCorrectionPlayer',...
                    'Track Correction',...
                    {['In this player, you can select tracking results '...
                    'to view and correct in the dropdown menu in the '...
                    'upper right corner, or you can generate a manual '...
                    'tracking result from scratch using the correction '...
                    'tools. Automatic tracking results are created '...
                    'under Automated->Track, in the main window.']
                    ''
                    ['The zoom functions which are available in other '...
                    'players are enabled by pressing the zoom tool. '...
                    'You can zoom in by clicking and dragging a '...
                    'rectangle, zoom out again by right-clicking, and '...
                    'pan by holding down the space bar or pressing '...
                    '''m''. If you are viewing slices of 3D data, you '...
                    'can switch to another slice by shift-clicking, or '...
                    'clicking with the center mouse button on the '...
                    'desired slice in one of the other 3D views. '...
                    'Clicking in the lineage tree will take you to the '...
                    'clicked time point.']})
            case 'FiberCorrection'
                ManualFiberCorrectionPlayer(seqPaths(index));
                InfoDialog('InfoFiberCorrectionPlayer',...
                    'Fiber Correction',...
                    {['In this player, you can select fiber '...
                    'segmentation results to view and correct in the '...
                    'dropdown menu in the upper right corner, or you '...
                    'can generate a manual segmentation result from '...
                    'scratch using the correction tools. Automatic '...
                    'segmentation results are created under '...
                    'Automated->Track, in the main window.']
                    ''
                    ['The zoom functions which are available in other '...
                    'players are enabled by pressing the zoom tool. '...
                    'You can zoom in by clicking and dragging a '...
                    'rectangle, zoom out again by right-clicking, and '...
                    'pan by holding down the space bar or pressing '...
                    '''m''. If you are viewing slices of 3D data, you '...
                    'can switch to another slice by shift-clicking, or '...
                    'clicking with the center mouse button on the '...
                    'desired slice in one of the other 3D views.']})
            case 'Analysis'
                CellAnalysisPlayer(seqPaths(index));
        end
    end

    function DisplayAllInfo_Callback(~,~)
        % Makes all GUIs display all information dialogs.
        %
        % This function will undo all decisions to not show information
        % dialogs again.
        %
        % See also:
        % DisplayNoInfo_Callback
        
        SaveVariable('InfoBaxterAlgorithms',            true)
        SaveVariable('InfoSettingsGUI',                 true)
        SaveVariable('InfoConvertMergedImagesGUI',      true)
        SaveVariable('InfoMergeExperimentsGUI',         true)
        SaveVariable('InfoZPlayer',                     true)
        SaveVariable('InfoSetFluorescencePlayer',       true)
        SaveVariable('InfoSegmentationPlayer',          true)
        SaveVariable('InfoCreateTemplate',              true)
        SaveVariable('InfoManualCorrectionPlayer',      true)
        SaveVariable('InfoFiberCorrectionPlayer',       true)
        SaveVariable('InfoDeleteButton',                true)
        SaveVariable('InfoEditSegmentsButton',          true)
        SaveVariable('InfoSegmentationOptimization',    true)
    end

    function DisplayNoInfo_Callback(~,~)
        % Makes all GUIs not display optional information dialogs.
        %
        % After this function has been executed, information dialogs that
        % the user can choose not to show again will not be shown at all.
        %
        % See also:
        % DisplayAllInfo_Callback
        
        SaveVariable('InfoBaxterAlgorithms',            false)
        SaveVariable('InfoSettingsGUI',                 false)
        SaveVariable('InfoConvertMergedImagesGUI',      false)
        SaveVariable('InfoMergeExperimentsGUI',         false)
        SaveVariable('InfoZPlayer',                     false)
        SaveVariable('InfoSetFluorescencePlayer',       false)
        SaveVariable('InfoSegmentationPlayer',          false)
        SaveVariable('InfoCreateTemplate',              false)
        SaveVariable('InfoManualCorrectionPlayer',      false)
        SaveVariable('InfoFiberCorrectionPlayer',       false)
        SaveVariable('InfoDeleteButton',                false)
        SaveVariable('InfoEditSegmentsButton',          false)
        SaveVariable('InfoSegmentationOptimization',    false)
    end

    function DeleteSeq()
        % Deletes the selected image sequences.
        
        index = get(seqListBox, 'Value');
        
        % No sequences selected.
        if isempty(index)
            errordlg('You have not selected any image sequences to delete.')
            return
        end
        
        % Ask if the user really wants to delete the sequences.
        choise = questdlg(...
            sprintf(['Are you sure that you want to delete the %d '...
            'selected sequences?'], length(index)),...
            'Delete sequences?', 'Yes', 'No', 'No');
        if strcmpi(choise, 'Yes')
            DeleteSequences(seqPaths(index));
        end
        
        % Removes the deleted sequences from the sequence list box.
        Update()
    end

    function ExListBox_Callback(aObj, ~)
        % Selects image sequences when the user selects experiments.
        %
        % This callback will selects all images sequences that belong to
        % the experiments that are selected in the experiment listbox.
        %
        % See also:
        % SeqListBox_Callback, SelPopupMenu_Callback
        
        % Get the selected experiments.
        selection = get(aObj, 'Value');
        exPathsSel = exPathsUni(selection);
        
        % The experiments that the sequences belong to.
        seqExPaths = FileParts2(seqPaths);
        
        % Create a binary array which indicate which sequences are in the
        % selected experiments.
        seqSelection = false(size(seqPaths));
        for ex = 1:length(exPathsSel)
            seqSelection = seqSelection | strcmpi(seqExPaths, exPathsSel{ex});
        end
        
        % Select the sequences in the sequence listbox and execute the
        % callback of the listbox so that all necessary updates are
        % performed.
        set(seqListBox, 'value', find(seqSelection))
        SeqListBox_Callback(seqListBox, 'ExListBox_Callback')
    end

    function oLevel = GetLevel()
        % Returns the selected menu level.
        %
        % The menu level is either 'basic', 'advanced', or 'development'
        % and determines which other menus should be shown to the user.
        
        if strcmp(get(basicMenu, 'Checked'), 'on')
            oLevel = 'basic';
        elseif strcmp(get(advancedMenu, 'Checked'), 'on')
            oLevel = 'advanced';
        elseif strcmp(get(developmentMenu, 'Checked'), 'on')
            oLevel = 'development';
        end
    end

    function InvertSelection()
        % Inverts the selection in the image sequence listbox.
        %
        % The unmarked sequences become marked and the marked sequence
        % become unmarked. This can be useful if a user wants to open
        % and correct sequences that have not yet been manually corrected.
        
        sel = get(seqListBox, 'Value');
        newSel = setdiff(1:length(seqPaths),sel);
        set(seqListBox, 'Value', newSel)
        SeqListBox_Callback(seqListBox, [])
    end

    function RandomSelection()
        % Lets the user select a random subset of the selected sequences.
        %
        % The function opens a dialog box where the user enters an integer,
        % and then the program selects that number of random image
        % sequences, from the set of already selected sequences.
        
        sel = get(seqListBox, 'Value');
        
        % No sequences selected.
        if length(sel) < 2
            errordlg(['You have to select at least two image sequences '...
                'to draw a subset from.'])
            return
        end
        
        % Ask the user how many sequences to select.
        answer = inputdlg({'Number of sequences to select'},...
            'Random selection', [1 40], {'1'});
        if isempty(answer)
            % The user closed the dialog.
            return
        end
        num = str2double(answer);
        
        if isnan(num) || num < 1 || num ~= round(num)
            errordlg('You have to input a nonnegative integer.')
            return
        end
        
        if num >= length(sel)
            errordlg(sprintf(['Currently there are %d image sequences '...
                'to pick from, so you have to input a number which is '...
                'smaller than that.'], length(sel)))
            return
        end
        
        % Select a random subset of the image sequences.
        newSel = sel(randperm(length(sel)));
        newSel = newSel(1:num);
        set(seqListBox, 'Value', newSel)
        SeqListBox_Callback(seqListBox, [])
    end

    function LevelCallback(aObj, ~)
        % Callback executed when one of the level menus is clicked.
        %
        % The callback deselects all other level menus and then updates the
        % set of other menus displayed.
        
        otherMenus = setdiff(...
            [basicMenu,...
            advancedMenu,...
            developmentMenu], aObj);
        set(aObj, 'Checked', 'on')
        set(otherMenus(1), 'Checked', 'off')
        set(otherMenus(2), 'Checked', 'off')
        
        SetVisibleMenus(menus, GetLevel())
    end

    function MoveSeq()
        % Moves the selected image sequences to another experiment.
        
        index = get(seqListBox, 'Value');
        
        % No sequences selected.
        if isempty(index)
            errordlg('You have not selected any image sequences to move.')
            return
        end
        
        % Select an experiment to move sequences to.
        tmpExPath = UiGetMultipleDirs(...
            'Title', 'Select an experiment folder',...
            'Path', FileParts2(seqPaths{1}),...
            'MultiSelect', false);
        
        if ~isempty(tmpExPath)
            if exist(fullfile(tmpExPath, 'SettingsLinks.csv'), 'file')
                errordlg(['It is not possible to move sequences to '...
                    'experiments with linked settings.'])
                return
            end
            seqNames = FileEnd(seqPaths(index));
            for seq = 1:length(seqNames)
                if exist(fullfile(tmpExPath, seqNames{seq}), 'file')
                    errordlg(['The selected experiment already contains '...
                        'an image sequence named ' seqNames{seq} '.'])
                return
                end
            end
            MoveSequences(seqPaths(index), tmpExPath);
        end
        
        % Removes the moved sequences from the sequence list box.
        Update()
    end

    function NextButton_Callback(~, ~)
        % Shows the next page of thumbnails.
        
        pageNum = pageNum + 1;
        SeqListBox_Callback(seqListBox, [])
    end

    function OpenUserGuide(~, ~)
        % Opens the User guide pdf when the user presses Help->User Guide.
        
        if ~isdeployed
            open('UserGuide.pdf')
        else
            % The command "open" does not work in deployed programs.
            if ispc
                winopen('UserGuide.pdf');
            else
                % This works on Mac but not on linux.
                unix('open "UserGuide.pdf" &');
            end
        end
    end

    function OpenOrAddExperiment(aExPaths, aOp)
        % Opens or adds a new experiment to the analysis.
        %
        % If a new experiment is opened, this closes all other experiments.
        %
        % Inputs:
        % aExPaths - Cell array with paths of experiment folders to be
        %            opened or added.
        % aOp - This parameter should be set to 'open' if we want to open
        %       new experiments and to 'add' if we want to add additional
        %       experiments.
        
        if ~any(strcmpi(aOp, {'open', 'add'}))
            error('aOp has to be either ''open'' or ''add''')
        end
        
        if iscell(aExPaths)
            exPaths = aExPaths;
        else
            exPaths = {aExPaths};
        end
        
        % Description of the required folder structure.
        folderRules = ['Sequences of images should be placed in '...
            'folders and these folders should be placed in experiment '...
            'folders, which can be opened in the program. The file '...
            'extensions tif, tiff, png, jpg, and jpeg are supported. '...
            'Image sequence folders must not be called ''Analysis''.'];
        
        % Check that the folder structure is correct, remove incorrect
        % folders, and notify the user using error dialogs.
        removeIndices = [];
        for ex = 1:length(exPaths)
            dirs = GetSeqDirs(exPaths{ex});
            
            % Check that the experiment folder exists.
            if ~exist(exPaths{ex}, 'dir')
                errordlg(sprintf(['The selected folder %s could not be '...
                    'found. It may have been moved or deleted, or it '...
                    'may be located on a drive which is not available. '],...
                    exPaths{ex}), 'Error opening experiment')
                removeIndices = [removeIndices; ex]; %#ok<AGROW>
                continue
            end
            
            % Check that there are image sequence folders.
            if isempty(dirs)
                errordlg(sprintf(['The selected folder %s does not '...
                    'contain any image sequence folders, and '...
                    'therefore the folder cannot be opened.\n\n'...
                    folderRules], exPaths{ex}), 'Error opening experiment')
                removeIndices = [removeIndices; ex]; %#ok<AGROW>
                continue
            end
            
            seqCandidate = fullfile(exPaths{ex}, dirs{1});
            images = GetNames(seqCandidate,...
                {'tif' 'tiff' 'png' 'jpg' 'jpeg'});
            
            % Check that the first image sequence folder contains images.
            % One could check all image sequences, but that would take too
            % long for large experiments. New checks are made when
            % thumbnails are read in.
            if isempty(images)
                errordlg(sprintf(['The image sequence folder %s does '...
                    'not contain any images, and therefore the '...
                    'corresponding experiment folder cannot be '...
                    'opened.\n\n' folderRules], seqCandidate),...
                    'Error opening experiment')
                removeIndices = [removeIndices; ex]; %#ok<AGROW>
                continue
            end
        end
        exPaths(removeIndices) = [];
        
        if strcmpi(aOp, 'add')
            % Do not add experiments that are already open.
            exPaths = setdiff(exPaths, exPathsUni);
        end
        
        % Nothing is done if there are no experiment folders left to open.
        if isempty(exPaths)
            return
        end
        
        if strcmpi(aOp, 'open')
            RemoveExPath(exPathsUni)
        end
        
        AddExPath(exPaths)
    end

    function OpenOrAddExperimentGUI(aOp)
        % Opens a directory selection dialog to open/add experiments.
        %
        % The function can open or add one or more experiments. When
        % experiments are opened, the experiments that are already open are
        % closed. When experiments are added, the experiments that are
        % already open remain open.
        %
        % Inputs:
        % aOp - This parameter should be set to 'open' if we want to open
        %       new experiments and to 'add' if we want to add additional
        %       experiments.
        
        if ~any(strcmpi({'open', 'add'}, aOp))
            error('aOp has to be either ''open'' or ''add''')
        end
        
        % Open a dialog box for selection of multiple folders.
        if ~isempty(seqPaths)
            tmpExPath = UiGetMultipleDirs(...
                'Path', FileParts2(FileParts2(seqPaths{1})),...
                'MultiSelect', true);
        else
            tmpExPath = UiGetMultipleDirs('MultiSelect', true);
        end
        
        % The user pressed cancel.
        if isempty(tmpExPath)
            return
        end
        
        OpenOrAddExperiment(tmpExPath, aOp)
    end

    function PreviousButton_Callback(~, ~)
        % Shows the previous page of thumbnails.
        
        pageNum = pageNum - 1;
        SeqListBox_Callback(seqListBox, [])
    end

    function RemoveExPath(aExPaths)
        % Removes an experiment from the analysis.
        %
        % This deselects all experiments and image sequences in the list
        % boxes.
        %
        % Inputs:
        % aExPaths - Paths of the sequences to be removed.
        
        % "setdiff" is not used, as it sorts the inputs alphabetically.
        for ii = 1:length(aExPaths)
            exPathsUni(strcmpi(exPathsUni, aExPaths{ii})) = [];
        end
        
        % Remove sequences associated with the experiments to be removed.
        if ~isempty(seqPaths)
            exPathsTmp = FileParts2(seqPaths);
            % Binary vector indicating what image sequences to remove.
            seqBin = false(size(seqPaths));
            for ii = 1:length(aExPaths)
                seqBin = seqBin | strcmpi(exPathsTmp, aExPaths{ii});
            end
            seqDirs = seqDirs(~seqBin);
            seqPaths = seqPaths(~seqBin);
            imDatas = imDatas(~seqBin);
        end
        
        % Update list boxes.
        set(exListBox, 'Value', [])  % Avoids decreasing the number of
        % list entries below the selection index.
        set(exListBox, 'String', exPathsUni)
        set(seqListBox, 'Value', [])  % Avoids decreasing the number of
        % list entries below the selection index.
        set(seqListBox, 'String', seqDirs)
        
        UpdateSelPopupMenu()
        
        SaveVariable('BaxterAlgorithms_exPathsUni', exPathsUni)
    end

    function RemoveExperiment()
        % Opens a GUI for closing of open experiments.
        %
        % The user gets to select the experiments to be closed in a list
        % box.
        
        [sel, ok] = listdlg('ListString', exPathsUni,...
            'Name', 'Remove experiment',...
            'ListSize', [600, 100]);
        if ok
            RemoveExPath(exPathsUni(sel))
        end
    end

    function oContinue = SelectAllDlg(aNumSel, aNumSeq)
        % Opens a dialog asking if the user wants to select all sequences.
        %
        % Inputs:
        % aNumSel - Number of selected sequences (only used in warning
        %           text).
        % aNumSeq - Total number of sequences (only used in warning text).
        %
        % Outputs:
        % oContinue - True if the user does not choose to cancel the
        %             initiated operation (by pressing Cancel in the dialog
        %             box).
        
        choice = questdlg(...
            sprintf(['You have selected %d out of %d files. The '...
            'unselected files will not be processed. Do you want to '...
            'select all files?'], aNumSel, aNumSeq),...
            'Select all files?',...
            'Select all', 'Continue', 'Cancel',...
            'Select all');
        
        switch choice
            case 'Select all'
                set(seqListBox, 'Value', 1:aNumSeq)
                SeqListBox_Callback(seqListBox, [])
                oContinue = true;
            case 'Continue'
                oContinue = true;
            case {'Cancel', ''}
                oContinue = false;
        end
    end

    function SelPopupMenu_Callback(~, ~)
        % Selects image sequences using the selPopupMenu.
        %
        % The set of image sequences selected in the popup menu are
        % highlighted in the list box with image sequence names, and
        % thumbnails for the selected image sequences are shown.
        %
        % See also:
        % SeqListBox_Callback, ExListBox_Callback
        
        sel = get(selPopupMenu, 'Value');
        switch selTypes{sel}
            case 'all'
                % Mark all sequences.
                selIndex = 1:length(seqPaths);
            case 'unknown'
                % Indicates that sequences have been marked manually. There
                % is no point in selecting this option.
                selIndex = get(seqListBox, 'Value');
            case 'cond'
                % Mark all sequences with the selected culturing condition.
                selIndex = find(cellfun(@(x)strcmp(x, selAlts{sel}), conds));
            case 'ver'
                % Mark all sequences with the selected tracking version.
                selIndex = find(cellfun(@(x)any(strcmp(x, selAlts{sel})), vers));
        end
        set(seqListBox, 'Value', selIndex)
        SeqListBox_Callback(seqListBox, 'SelPopupMenu_Callback')
    end

    function SeqListBox_Callback(aObj, aEvent)
        % Displays thumbnails of the selected image sequences.
        %
        %  When image sequences are selected in the list box to the right
        %  in the figure, this function displays thumbnails with the first
        %  image of each sequence. Only 20 images are displayed at a time,
        %  but the user can change which 20 images to display by pressing
        %  the Next and Previous buttons. The second input argument is set
        %  to 'SelPopupMenu_Callback' if the function is called from
        %  SelPopupMenu_Callback, and to 'ExListBox_Callback' if the
        %  function is called from ExListBox_Callback.
        %
        % See also:
        % SelPopupMenu_Callback, ExListBox_Callback
        
        vec = get(aObj, 'Value');
        
        set(seqLabel, 'String', sprintf('Image sequences %d / %d', length(vec), length(seqDirs)))
        
        % Mark the appropriate field in the selection popupmenu unless this
        % function was called from SelPopupMenu_Callback.
        if ~isequal(aEvent, 'SelPopupMenu_Callback')
            if length(vec) == length(seqPaths)
                set(selPopupMenu, 'Value', find(strcmpi(selTypes, 'all')))
            else
                set(selPopupMenu, 'Value', find(strcmpi(selTypes, 'unknown')))
            end
        end
        
        % Deselect all experiments unless the function was called from
        % ExListBox_Callback.
        if ~isequal(aEvent, 'ExListBox_Callback')
            set(exListBox, 'value', [])
        end
        
        % Avoids showing an empty last page.
        
        if pageNum > ceil(length(vec)/20.0)
            pageNum = max(ceil(length(vec)/20.0),1);
        end
        
        if length(vec) > 20 && pageNum < ceil(length(vec)/20.0)  % not on final page
            set(nextButton,  'Enable', 'on')
        else  % on final page
            set(nextButton,  'Enable', 'off')
        end
        
        if pageNum > 1  % not on first page
            set(previousButton,  'Enable', 'on')
        else  % on first page
            set(previousButton,  'Enable', 'off')
        end
        
        % Display new images and labels.
        k = 0; % image index
        for jj = 1 + (pageNum-1)*20 : min(length(vec), pageNum*20)
            k = mod(jj,20);
            if(k == 0)
                k = 20;
            end
            
            % Display the name of the image sequence.
            set(smallLabels{k}, 'String', seqDirs{vec(jj)})
            
            try
                % It is too costly to check for images in the image
                % sequence folders ahead of time, so instead ImageData will
                % throw an error if no images are found.
                if isempty(imDatas{vec(jj)})
                    % There is no cached ImageData objects, so one is
                    % computed and cached.
                    imDatas{vec(jj)} = ImageData(seqPaths{vec(jj)});
                end
                imData = imDatas{vec(jj)};
            catch err
                if (strcmp(err.identifier,'ImageData:noImages'))
                    % Create an error dialog.
                    errorMessage = sprintf(...
                        'The image sequence folder ''%s'' does not contain any image files.',...
                        seqDirs{vec(jj)});
                    errordlg(errorMessage, 'No images found.');
                    
                    % Select all image sequences, not just the bad one.
                    set(aObj, 'Value', [])
                    
                    % Deselect all image sequences in the list.
                    SeqListBox_Callback(aObj, aEvent)
                    break
                else
                    rethrow(err);
                end
            end
            
            % Decide how much to down-scale the image. Down-scale as much
            % as possible without making the image smaller than 200x200.
            minDim = min(imData.imageWidth, imData.imageHeight);
            downScale = max(floor(minDim/200),1);
            
            maxY = imData.imageHeight - mod(imData.imageHeight-1, downScale);
            maxX = imData.imageWidth - mod(imData.imageWidth-1, downScale);
            tempImage = imData.GetShownImage(1,...
                'Channels', imData.channelNames,...  % Include all fluorescent channels.
                'PixelRegion', {[1 downScale maxY], [1 downScale maxX]});
            
            imshow(tempImage, 'Parent', smallPictures{k})
            axis(smallPictures{k}, 'off')
        end
        
        % Remove old images and labels.
        for ii = k+1 : 20
            set(smallLabels{ii}, 'String', '')
            cla(smallPictures{ii})
        end
    end

    function Settings()
        % Opens a GUI where settings can be changed.
        %
        % The GUI lets the user review and change all settings for
        % processing and analysis of the image sequences in the open
        % experiments. The settings for image sequences where the "use"
        % setting is set to 0 can also be changed.
        %
        % See also:
        % SettingsGUI
        
        % In case the "use" settings of the image sequences are changed, we
        % need to update the sequence variables and the sequence list box
        % once the user closes the settings GUI.
        selSeqPaths = seqPaths(get(seqListBox, 'Value'));
        SettingsGUI(exPathsUni,...
            'Selection', selSeqPaths,...
            'CloseFunction', @Update);
        InfoDialog('InfoSettingsGUI', 'Specify settings',...
            ['You can select which settings category to display using '...
            'the Category menu. The settings are also separated into '...
            'the 3 levels ''basic'', ''advanced'', and '...
            '''development''. You can select which levels to show '...
            'using the Level menu. The basic level has settings which '...
            'have to be set properly in order to process the data '...
            'successfully. The advanced settings are settings which '...
            'can improve the performance or which are needed for '...
            'special types of data. The development settings are not '...
            'needed by the typical user and may not be fully tested. '...
            'There is a separate graphical user interface to specify '...
            'settings for segmentation.'])
    end

    function SwitchExQuestion(aExPath)
        % Asks users if they want to switch to cut/stabilized experiments.
        %
        % Inputs:
        % aExPath - Full path of the experiment that the user may want to
        %           switch to.
        
        if ishandle(mainFigure)  % The user may have closed the figure.
            choice = questdlg(...
                sprintf('Would you like to switch to the experiment %s', aExPath),...
                'Done processing.',...
                'Yes', 'No', 'Yes');
            
            if strcmp(choice, 'Yes')
                RemoveExPath(exPathsUni)
                OpenOrAddExperiment(aExPath, 'add')
            end
        end
    end

    function UpdateSelPopupMenu()
        % Updates the alternatives available in "selPopupMenu".
        
        % Get the old values, so that they can be selected again once the
        % alternatives have been updated.
        sel = get(selPopupMenu, 'Value');
        selA = selAlts{sel};
        selT = selTypes{sel};
        
        % Update options.
        vers = GetVersions(seqPaths);
        conds = ReadSeqSettings(seqPaths, 'condition');
        if isempty([conds{:}])
            conds = {};
        end
        uVers = unique([vers{:}])';
        uConds = unique(conds);
        selAlts = [{'all'}; {'unknown'}; uVers; uConds];
        selTypes = [...
            {'all'}
            {'unknown'}
            repmat({'ver'}, length(uVers), 1)
            repmat({'cond'}, length(uConds), 1)];
        
        % Set the selection to what was selected before the update.
        newIndex = find(strcmp(selAlts, selA) & strcmpi(selTypes, selT));
        set(selPopupMenu, 'String', selAlts)
        if ~isempty(newIndex)
            set(selPopupMenu, 'Value', newIndex)
        else
            set(selPopupMenu, 'Value', find(strcmpi(selTypes, 'unknown')))
        end
        SelPopupMenu_Callback(selPopupMenu, [])
    end

    function Update()
        % Updates the image sequence list box and all thumbnails.
        %
        % The list box is updated so that only sequences for which the
        % "use" setting is 1 show up. The function also gets rid of all
        % cached ImageData objects, and redraws all thumbnails, in case
        % some of the visualization settings have been changed. The
        % function is called from other GUIs that make changes to the
        % settings.
        
        % Previously selected sequences.
        selSeqPaths = seqPaths(get(seqListBox, 'Value'));
        
        % Update the image sequence paths.
        seqPaths = {};
        for ex = 1:length(exPathsUni)
            tmpSeqDirs = GetUseSeq(exPathsUni{ex});
            if ~isempty(tmpSeqDirs)
                seqPaths = [seqPaths
                    strcat(exPathsUni{ex}, filesep, tmpSeqDirs)]; %#ok<AGROW>
            end
        end
        seqDirs = FileEnd(seqPaths);
        
        % Remove all cached ImageData objects.
        imDatas = cell(size(seqDirs));
        
        % Update sequence list box.
        [~, sel] = intersect(seqPaths, selSeqPaths);
        set(seqListBox, 'String', seqDirs)
        set(seqListBox, 'Value', sel)
        
        % Update the thumbnails and the options in the selection dropdown
        % menu.
        UpdateSelPopupMenu()
    end
end