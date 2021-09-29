classdef ImageParameters < Map
    % Information about an image sequence, loaded from a settings file.
    %
    % This class contains all of the information about an image sequence
    % which can be found in a settings file. Information which is computed
    % based on the contents of the image sequence folder is added in the
    % sub-class ImageData. Creating an ImageData object is much
    % more costly than creating a ImageParameters object. The
    % ImageParameters class is a sub-class of Map, and stores the settings
    % in the settings file using the names of the settings as keys.
    % ImageParameters also has some properties which are derived from the
    % settings files, and some dependent properties which give get-access
    % to some commonly used settings which are properties of the image
    % sequence itself, and not algorithm settings.
    
    properties
        globalSettingsFile = [];    % Path of a csv settings file, which can be supplied to the constructor.
        seqPath = [];               % Path of the folder containing the image sequence.
        channelNames = {};          % Cell array of strings with names of the imaging channels.
        channelTags = {};           % Cell array with regular expressions unique to file names associated with the different channels.
        channelColors = {};         % Cell array of channel colors in the form of RGB vectors with values between 0 and 1.
        channelMin = {};            % Pixel intensity (normalized between 0 and 1) below which all pixels are displayed as black.
        channelMax = {};            % Pixel intensity (normalized between 0 and 1) above which all pixels are displayed as white.
        xCalibrationMicrons = [];   % The image pixel width in microns.
        currentSettingsFile = [];
        availableSettingsFiles = [];
    end
    
    properties (Dependent = true)
        dT              % The time between images in seconds.
        numZ            % Number of z-planes in z-stack (1 for 2D data).
        zStacked        % True if the images are tif-stacks with z-stacks.
        voxelHeight     % The ratio between the voxel height and the voxel width (for 3D data).
        bits            % The number of camera bits in the images.
        condition       % String with the experimental condition.
    end
    
    methods
        function this = ImageParameters(aSeqPath, varargin)
            % Constructs empty object or one with settings for a sequence.
            %
            % In an empty object, there will not be any settings. The
            % object with settings for an image sequence has
            % values for all settings found in AllSettings. If a setting
            % has a value stored in the settings file corresponding to the
            % image sequence, that value will be used. Otherwise the
            % default value of the setting will be used.
            %
            % Inputs:
            % aSeqPath - Full path name of the image sequence. If this
            %            input is omitted, an object without settings is
            %            returned.
            %
            % Property/Value inputs:
            % SettingsFile - The full path of a csv-file with settings. If
            %                this input is not given, the file named
            %                Settings.csv in the experiment folder will be
            %                used. This paths is stored in the
            %                globalSettingsFile property of the class.
            % Spreadsheet - A spreadsheet with settings, created by
            %               reading a settings file with ReadSettings.
            % See also:
            % AllSettings, Setting, ReadSettings
            
            if nargin == 0
                % Return object without settings.
                return
            end
            
            if ~exist(aSeqPath, 'dir')
                error('The image sequence %s does not exist.\n', aSeqPath)
            end
            
            % Get property/value inputs.
            [this.globalSettingsFile, spreadSheet]  =...
                GetArgs({'SettingsFile' 'Spreadsheet'}, {'' []}, true, varargin);
            
            this.seqPath = aSeqPath;
            
            % Construct a spread sheet by reading a settings file.
            if isempty(spreadSheet)
                this.availableSettingsFiles = GetSettingsFiles(this.GetExPath);
                if isempty(this.globalSettingsFile)
                    % Read settings file from the default location.
                    if isempty(this.availableSettingsFiles)
                        this.currentSettingsFile = [];
                    else
                        this.currentSettingsFile = this.availableSettingsFiles{1};
                    end
                else
                    % Read settings file from a specified location.
                    this.currentSettingsFile = this.globalSettingsFile;
                    if ~any(strcmpi(this.availableSettingsFiles, this.currentSettingsFile))
                        this.availableSettingsFiles =...
                            [this.currentSettingsFile
                            this.availableSettingsFiles];
                    end
                end
                if isempty(this.currentSettingsFile)
                    spreadSheet = ReadSettings(this.GetExPath(), this.GetSeqDir());
                else
                    spreadSheet = ReadSettings(this.currentSettingsFile, this.GetSeqDir());
                end
            end
            
            allSettings = AllSettings();
            
            % Extract values from the spreadsheet.
            for i = 1:allSettings.Size()
                s = allSettings.Get(i);
                label = allSettings.GetLabel(i);
                
                value = GetSeqSettings(spreadSheet, this.GetSeqDir(), label);
                
                % Look for settings aliases if no value was found.
                if isempty(value)
                    for j = 1:length(s.aliases)
                        value = GetSeqSettings(spreadSheet, this.GetSeqDir(), s.aliases{j});
                        if ~isempty(value)
                            break
                        end
                    end
                end
                
                if ~isempty(value)
                    % Use the value found in the settings file.
                    if strcmpi(s.type, 'numeric')
                        % Convert numeric string to a number.
                        this.Add(label, str2num(value)); %#ok<ST2NM>
                    else
                        this.Add(label, value);
                    end
                else
                    % Use the default settings value.
                    this.Add(label, s.GetDefault(this));
                end
            end
            
            % Post-processing of settings values.
            if isempty(regexp(this.Get('PCSegPSF'), '.*\.mat$', 'once'))
                this.Set('PCSegPSF', [this.Get('PCSegPSF') '.mat']);
            end
            if strcmp(this.Get('SegLightCorrect'), '0')
                this.Set('SegLightCorrect',  'none')
            elseif strcmp(this.Get('SegLightCorrect'), '1')
                this.Set('SegLightCorrect',  'additive')
            end
            
            % Set information about all imaging channels in the experiment.
            % The channel names specified determine how many channels there
            % will be. If there is channel information for additional
            % channels that don't have names, that information will be
            % ignored. If there is too little channel information, default
            % values will be generated.
            
            % Channel names and the corresponding tags in the file names.
            this.channelNames = strtrim(regexpi(this.Get('channelNames'), ':', 'split'));
            this.channelTags = strtrim(regexpi(this.Get('channelTags'), ':', 'split'));
            
            % Split the channel information strings.
            colorsStr = strtrim(regexpi(this.Get('channelColors'), ':', 'split'));
            colors = cellfun(@str2num, colorsStr, 'UniformOutput', false)';
            minsStr = strtrim(regexpi(this.Get('channelMin'), ':', 'split'));
            mins = cellfun(@str2double, minsStr)';
            maxesStr = strtrim(regexpi(this.Get('channelMax'), ':', 'split'));
            maxes = cellfun(@str2double, maxesStr)';
            
            % Allocate memory.
            this.channelColors = cell(length(this.channelNames),1);
            this.channelMin = zeros(length(this.channelNames),1);
            this.channelMax = zeros(length(this.channelNames),1);
            
            % Insert the specified channel information into the
            % ImageParameters object if it exists and is correct. Use
            % default values otherwise.
            for i = 1:length(this.channelNames)
                % Colors.
                if length(colors) >= i && all(size(colors{i}) == [1 3])
                    this.channelColors{i} = colors{i};
                else
                    if i == 1
                        % First channel is white light.
                        this.channelColors{i} = ones(1,3);
                    else
                        % Following channels cycle through red, green
                        % and blue.
                        this.channelColors{i} = zeros(1,3);
                        this.channelColors{i}(rem(i-2,3)+1) = 1;
                    end
                end
                
                % Minimum intensity for display.
                if length(mins) >= i && ~isnan(mins(i))
                    this.channelMin(i) = mins(i);
                else
                    this.channelMin(i) = 0;
                end
                
                % Maximum intensity for display.
                if length(maxes) >= i && ~isnan(maxes(i))
                    this.channelMax(i) = maxes(i);
                else
                    this.channelMax(i) = 1;
                end
            end
            
            this.xCalibrationMicrons =...
                this.Get('pixelSize') / this.Get('magnification');
        end
        
        function oBits = get.bits(this)
            oBits = this.Get('bits');
        end
        
        function oDT = get.dT(this)
            oDT = this.Get('dT');
        end
        
        function oCond = get.condition(this)
            oCond = this.Get('condition');
        end
        
        function oNum = get.numZ(this)
            oNum = this.Get('numZ');
        end
        
        function oHeight = get.voxelHeight(this)
            oHeight = this.Get('voxelHeight');
        end
        
        function oNum = get.zStacked(this)
            oNum = this.Get('zStacked');
        end
        
        function oPath = GetAnalysisPath(this)
            % Returns the path of the folder containing processing results.
            %
            % The folder is in the experiment folder and is named Analysis.
            %
            % Outputs:
            % oPath - Character array with full path name.
            
            oPath = fullfile(this.GetExPath(), 'Analysis');
        end
        
        function oPath = GetGroundTruthPath(this, aSuffix, aThrowIfNoGt)
            % Finds the path of a ground truth folder if one exists.
            %
            % The ground truth folder can be located either in the analysis
            % folder or in the same folder as the image sequence. The name
            % of the ground truth folder is the name of the image sequence
            % folder followed by the suffix. If the ground truth folder is
            % in the analysis folder, the image sequence name may have been
            % abbreviated to the two last letters ('01' or '02').
            %
            % Inputs:
            % aSuffix - The suffix which specifies the type of ground
            %           truth. Either '_GT' for gold or '_ST' for silver.
            % aThrowIfNoGt - I true, an error is thrown if no ground truth
            %                folder exists, otherwise, an empty array is
            %                returned.
            %
            % Outputs:
            % oPath - The full path of the ground truth folder.
            
            seqDir = this.GetSeqDir();
            oPath = fullfile(this.GetAnalysisPath(), [seqDir aSuffix]);
            
            % Handle ground truth folders where only the two last letters
            % of the image sequence name are included in the folder name.
            % That naming was used in the cell tracking challenges, but
            % does not make sense for image sequence names which do not end
            % with two digits. 
            if ~exist(oPath, 'dir')
                oPath = fullfile(this.GetAnalysisPath(),...
                    [seqDir(end-1:end) aSuffix]);
            end
            
            % If the ground truth folder is not found, we check if the
            % ground truth folder is next to the image sequence, as in the
            % folder structure in the cell tracking challenges.
            if ~exist(oPath, 'dir')
                oPath = fullfile([this.seqPath aSuffix]);
            end
            
            if ~exist(oPath, 'dir')
                if aThrowIfNoGt
                    error('No ground truth folder found.')
                else
                    oPath = [];
                end
            end
        end
        
        function oColor = GetColor(this, aChannel)
            % Returns the color used to display a specific channel.
            %
            % Inputs:
            % aChannel - Index or name of the channel.
            %
            % Outputs:
            % oColor - Color in the form of a 3 element vector with RGB
            %          values in the range between 0 and 1.
            
            
            if isnumeric(aChannel)
                channelIndex = aChannel;
            else
                channelIndex = find(strcmp(this.channelNames, aChannel));
            end
            oColor = this.channelColors{channelIndex};
        end
        
        function oPath = GetDataSetFileName(this, aVer)
            % Returns the path of a folder with classification data.
            %
            % This type of folder is meant to store data used to train and
            % test classifiers. The data is extracted from a specific
            % tracking result and is stored in a corresponding dataset
            % folder. The name of the folder starts with 'DataSets' and
            % ends with the label of the corresponding tracking result.
            %
            % Inputs:
            % aVer - Label of the desired tracking result version. The
            %        version label does not include 'CellData'.
            %
            % Outputs:
            % oPath - Character array with full path name of the dataset
            %         folder corresponding to tracking version aVer.
            
            oPath = fullfile(this.GetExPath(),...
                'Analysis',...
                ['CellData' aVer],...
                'TrainingData',...
                [this.GetSeqDir() '.mat']);
        end
        
        function oDim = GetDim(this)
            % Returns 2 for 2D images and 3 for 3D z-stacks.
            %
            % The output is the same for image sequences and single images
            % and it is not changed if the data has multiple channels.
            
            if this.numZ == 1
                oDim = 2;
            else
                oDim = 3;
            end
        end
        
        function oPath = GetExPath(this)
            % Returns the full path name of the experiment folder.
            %
            % The experiment folder is a folder containing a number of
            % folders with image sequences, a Settings.csv file and an
            % Analysis folder.
            %
            % Outputs:
            % oPath - Character array with full path name.
            %
            % See also:
            % GetSeqDir
            
            oPath = fileparts(this.seqPath);
        end
        
        function oOpts = GetOpts(this)
            % Returns a struct with all settings of the image sequence.
            %
            % Outputs:
            % oOpts - Struct with settings values where the names of the
            %         settings are field names.
            
            oOpts = this.values;
        end
        
        function [oNames, oIndices] = GetReflectChannels(this)
            % Returns the names of all reflection microscopy channels.
            %
            % All channels that have a color which is not a shade of gray
            % are considered to be reflection microscopy channels. These
            % channels are usually fluorescence channels.
            %
            % Outputs:
            % oNames - Cell array with channel names.
            % oIndices - Indices of the channels.
            
            oNames = {};
            oIndices = [];
            for i = 1:length(this.channelNames)
                if this.IsReflectChannel(i)
                    oNames = [oNames; this.channelNames(i)]; %#ok<AGROW>
                    oIndices = [oIndices; i]; %#ok<AGROW>
                end
            end
        end
        
        function oFolders = GetSegImportFolders(this)
            % Returns folders for segmentations that can be imported.
            %
            % Outputs:
            % oFolders - Cell array with the names of folders containing
            %            16-bit tif label images representing a
            %            segmentation generated using some other software
            %            like for example CellProfiler.
            
            oFolders = GetNames(fullfile(this.GetExPath(), 'Analysis'), '');
            oFolders = regexpi(oFolders, '^Segmentation.*', 'once', 'match');
            oFolders(cellfun(@isempty, oFolders)) = [];
            % TODO: Maybe check if there exists a subfolder with the same
            % name as the image sequence folder. This could take too long
            % though.
        end
        
        function oDir = GetSeqDir(this)
            % Returns the name of the image sequence folder.
            %
            % The function returns only the name of the folder and not the
            % full path.
            %
            % Outputs:
            % oDir - Character array with folder name.
            %
            % See also:
            % GetExPath
            
            [~, oDir] = FileParts2(this.seqPath);
        end
        
        function oReflect = IsReflectChannel(this, aChannel)
            % Checks if a channel was imaged using reflection microscopy.
            %
            % All channels where the color is not a shade of gray are
            % considered to be reflection microscopy channels. These
            % channels are usually fluorescence channels.
            %
            % Inputs:
            % aChannel - Index or name of a channel.
            %
            % Outputs:
            % oTrans - True if the channel is a reflection microscopy
            %          channel.
            
            oReflect = ~this.IsTransChannel(aChannel);
        end
        
        function oTrans = IsTransChannel(this, aChannel)
            % Checks if a channel was imaged using transmission microscopy.
            %
            % All channels where the color is a shade of gray are
            % considered to be transmission microscopy channels.
            %
            % Inputs:
            % aChannel - Index or name of a channel.
            %
            % Outputs:
            % oTrans - True if the channel is a transmission microscopy
            %          channel.
            
            % Get the index of the channel.
            if isnumeric(aChannel)
                channelIndex = aChannel;
            else
                channelIndex = find(strcmp(this.channelNames, aChannel));
            end
            
            oTrans = all(this.channelColors{channelIndex} ==...
                this.channelColors{channelIndex}(1));
        end
        
        function oMicrons = PixelToMicroM(this, aPixels)
            % Converts a distance from pixels to micrometers.
            %
            % The function assumes that pixels are square.
            %
            % Inputs:
            % aPixels - A distance or an array of distances in pixels.
            %
            % Outputs:
            % oMicrons - A distance or an array of distances in
            %            micrometers.
            
            oMicrons = aPixels * this.xCalibrationMicrons;
        end
        
        function oPixels = MicroMToPixel(this, aMicrons)
            % Converts a distance from micrometers to pixels.
            %
            % The function assumes that pixels are square.
            %
            % Inputs:
            % aMicrons - A distance or an array of distances in
            %            micrometers.
            %
            % Outputs:
            % oPixels - A distance or an array of distances in pixels.
            
            oPixels = aMicrons / this.xCalibrationMicrons;
        end
        
        function oSquareMicrons = Pixel2ToMicroM2(this, aPixels)
            % Converts an area from pixels to square micrometers.
            %
            % The function assumes that pixels are square.
            %
            % Inputs:
            % aPixels - An area or an array of areas in pixels.
            %
            % Outputs:
            % oSquareMicrons - An area or an array of areas in square
            %                  micrometers.
            
            oSquareMicrons = aPixels * this.xCalibrationMicrons^2;
        end
        
        function oPixels = MicroM2ToPixel2(this, aSquareMicrons)
            % Converts an area from square micrometers to pixels.
            %
            % The function assumes that pixels are square.
            %
            % Inputs:
            % aSquareMicrons - An area or an array of areas in square
            %                  micrometers.
            %
            % Outputs:
            % oPixels - An area or an array of areas in pixels.
            
            oPixels = aSquareMicrons / this.xCalibrationMicrons^2;
        end
        
        function oCubicMicrons = VoxelToMicroM3(this, aVoxels)
            % Converts a volume from voxels to cubic micrometers.
            %
            % The function assumes that pixels are square, but the
            % z-resolution may be different from the x- and y-resolutions.
            %
            % Inputs:
            % aVoxels - A volume or an array of volumes in voxels.
            %
            % Outputs:
            % oCubicMicrons - A volume or an array of volumes in cubic
            %                 micrometers.
            
            oCubicMicrons = aVoxels * this.xCalibrationMicrons^3 * this.voxelHeight;
        end
        
        function oVoxels = MicroM3ToVoxel(this, aCubicMicrons)
            % Converts a volume from cubic micrometers to voxels.
            %
            % The function assumes that pixels are square, but the
            % z-resolution may be different from the x- and y-resolutions.
            %
            % Inputs:
            % aCubicMicrons - A volume or an array of volumes in cubic
            %                 micrometers.
            %
            % Outputs:
            % oVoxels - A volume or an array of volumes in voxels.
            
            oVoxels = aCubicMicrons / this.xCalibrationMicrons^3 / this.voxelHeight;
        end
        
        
        function oFrame = TToFrame(this, aT)
            % Converts a time point in hours to a frame index.
            %
            % Inputs:
            % aT - Time point or an array of time points in hours since the
            %      start of the experiment. The setting startT should be
            %      specified if the experiment started before the imaging.
            %
            % Outputs:
            % oFrame - Frame index or array of frame indices. The frame
            %          indices may not be integers.
            
            oFrame = 1 + (aT - this.Get('startT')) / (this.dT/3600);
        end
        
        function oT = FrameToT(this, aFrame)
            % Converts a frame index to a time point in hours.
            %
            % Inputs:
            % aFrame - Frame index or array of frame indices.
            %
            % Outputs:
            % oT - Time point or array of time points, in hours since the
            %      start of the experiment. The setting startT should be
            %      specified if the experiment started before the imaging.
            
            oT = this.Get('startT') + (aFrame - 1) * (this.dT/3600);
        end
        
        function oHours = FramesToHours(this, aFrames)
            % Converts a time interval from frames to hours.
            %
            % Inputs:
            % aFrames - A frame count or an array of frame counts.
            %
            % Outputs:
            % oHours - A time interval or an array of time intervals in
            %          hours.
            
            oHours = aFrames * this.dT / 3600;
        end
        
        function oFrames = HoursToFrames(this, aHours)
            % Converts a time interval from hours to frames.
            %
            % Inputs:
            % aHours - A time interval or an array of time intervals in
            %          hours.
            %
            % Outputs:
            % oFrames - A frame count or an array of frame counts. The
            %           frame counts may not be integers.
            
            oFrames = aHours * 3600 / this.dT;
        end
    end
end