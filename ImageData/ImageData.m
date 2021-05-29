classdef ImageData < ImageParameters
    % Class containing all information about an image sequence.
    %
    % The class can read images with the file extensions tif, tiff, png,
    % jpg, and jpeg. Z-stacks can be represented using either tif-stacks or
    % single images. Time sequences and multiple channels are represented
    % using single images. All images should be gray scale images. Color
    % images are converted to gray scale.
    %
    % The the objects contain information about file names, information
    % about detected microwells and processing settings. The processing
    % settings are read from a csv settings file and are present in the
    % super-class ImageParameters, which in turn is a super-class of Map.
    % It takes much longer to generate an ImageData object than an
    % ImageParameters object, because it requires information from the
    % image sequence folder. When images are read in, they are cached, to
    % save time the next time the image is read. Images are only cached if
    % no additional inputs are given to the imwrite function, and they are
    % only cached for one frame at a time. If images have been cached for
    % one frame and the user asks for an image in another frame, all the
    % cached images are discarded. Images are cached in the function
    % GetImage, and images from all channels and z-planes are cached.
    %
    % See also:
    % AllSettings, ImageParameters, Map
    
    properties
        filenames = {};             % Cell array with one cell per channel.
        % The cells contain cell arrays of
        % strings with the file names of all
        % images in that channel.
        
        imageWidth = [];            % The width of the image in pixels.
        imageHeight = [];           % The height of the image in pixels.
        WellX = [];                 % x-coordinate of a circular microwell.
        WellY = [];                 % y-coordinate of a circular microwell.
        WellR = [];                 % Radius of a circular microwell.
        sequenceLength = [];        % The number of images in the image sequence.
        version = [];               % Name of the tracking version that will be or has been computed.
        cachedImages = {};          % Cell array with cached images for one frame.
        cachedFrame = [];           % The frame for which images have been cached.
        segImData = [];             % ImageData object for a folder with a segmentation that can be loaded.
        sequenceMaxIntensity = [];
        sequenceMinIntensity = [];
    end
    
    methods
        
        function this = ImageData(aSeqPath, varargin)
            % Constructs an empty object or one with data about a sequence.
            %
            % The constructor throws an ImageData:noImages error if no
            % images are found, and an ImageData:tooFewImages error if
            % fewer than sequenceLength images are found.
            %
            % Inputs:
            % aSeqPath - Full path of the folder containing the image
            %            sequence.
            %
            % Property/Value inputs:
            % Any properties of the object, and corresponding values.
            
            [settingsArgs, propertyArgs] = SelectArgs(varargin,...
                {'SettingsFile' 'SpreadSheet'});
            
            % Generate input arguments for ImageParameters. This is
            % necessary to the constructor to take no input arguments.
            if nargin == 0
                inputs = {};
            else
                inputs = [{aSeqPath} settingsArgs];
            end
            
            this = this@ImageParameters(inputs{:});
            
            if nargin == 0
                % Return an empty object.
                return
            end
            
            imageNames = GetNames(this.seqPath, {'tif' 'tiff' 'png' 'jpg' 'jpeg'});
            
            % Find the file names associated with the different channels.
            for i = 1:length(this.channelNames)
                matches = regexp(imageNames, this.channelTags{i}, 'once');
                names = imageNames(~cellfun(@isempty, matches));
                this.filenames{i} = strcat(this.seqPath, filesep, names);
            end
            
            if isempty(this.filenames{1})
                error('ImageData:noImages',...
                    'The image sequence folder %s does not contain any images %d.',...
                    aSeqPath)
            end
            
            info = imfinfo(this.filenames{1}{1});
            
            % Get width and height. The (1) is to handle tif-stacks.
            this.imageWidth = info(1).Width;
            this.imageHeight =  info(1).Height;
            
            % Use all images if the user did not specify a sequence length.
            if isempty(this.Get('sequenceLength'))
                if this.Get('zStacked')
                    this.sequenceLength = length(this.filenames{1});
                else
                    this.sequenceLength = floor(length(this.filenames{1})/this.numZ);
                end
            else
                this.sequenceLength = this.Get('sequenceLength');
            end
            
            % Check that there are enough files. Fluorescence channels
            % are allowed to have less images for now.
            if length(this.filenames{1}) < this.sequenceLength
                error('ImageData:tooFewImages',...
                    'The specified sequence length exceeds the number of images for %s.',...
                    this.seqPath)
            end
            
            % Set properties according to additional input arguments.
            for i = 1 : 2 : length(propertyArgs)
                this.(propertyArgs{i}) = propertyArgs{i+1};
            end
            
            this.cachedImages = cell(length(this.channelNames), this.numZ);
            this.cachedFrame = nan;
            
            % Create an ImageData object for a folder with label images
            % that can be loaded as a segmentation. This is only done if
            % the segmentation algorithm loads a segmentation.
            if any(strcmpi(this.Get('SegAlgorithm'),...
                    {'Segment_import' 'Segment_import_binary'}))
                if isempty(this.Get('SegImportFolder'))
                    warning('No import folder has been specified.')
                    return
                end
                this.LoadSegImData()
            end
        end
        
        function oImageData = Clone(this)
            % Returns a deep copy of the object.
            oImageData = ImageData();
            props = properties(ImageData);
            for i = 1:length(props)
                p = findprop(this, props{i});
                if ~p.Dependent
                    oImageData.(props{i}) = this.(props{i});
                end
            end
        end
        
        function oSize = GetSize(this)
            % Returns the image or z-stack size.
            %
            % Outputs:
            % oSize - A 2 or 3 element vector with the height, width and
            %         number of z-planes (for 3D data) of the images or
            %         z-stacks.
            
            if this.GetDim() == 2
                oSize = [this.imageHeight this.imageWidth];
            else
                oSize = [this.imageHeight this.imageWidth this.numZ];
            end
        end
        
        function oIm = GetImage(this, aFrame, varargin)
            % Returns an image with the original numeric type.
            %
            % The returned image will be of the same type as the saved file
            % (usually uint8 or uint16). For 3D image sequences, the
            % function can return either a particular z-slice or a maximum
            % intensity projection, depending on the ZPlane parameter. This
            % function is the only function to read images from files. All
            % other functions used to retrieve images should call this
            % function. This function caches images from the current frame.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % Channel - Name or index of the channel to be read. By
            %           default, the first channel is read.
            % ZPlane - The index of the z-plane to be read. This input only
            %          affects 3D sequences. The indexing of the z-planes
            %          starts at 1. If 0 is given, the maximum intensity
            %          projection will be returned. The default value is 0.
            %          The input can also be an array of z-plane indices to
            %          compute the maximum intensity projection of.
            % PixelRegion - Two element cell array with 2- or 3-element
            %               vectors defining sub-images to be read. The two
            %               vectors define pixel intervals in the two image
            %               dimensions. In a 3 element vector, element 2
            %               specifies a step length, so that the image can
            %               be down-sampled. The same input can be given to
            %               the build in function imread, if the image is a
            %               tif-image. For other file types, the whole
            %               image is read and then cropped. The inputs X1,
            %               X2, Y1 and Y2 can also be used to crop out a
            %               sub-volume. The difference is that in that
            %               case, the full image is read and cached for
            %               future use. If PixelRegion is used, no caching
            %               is done. PixelRegion should not be used
            %               together with the X- and Y-arguments.
            % X1 - First pixel in x-dimension for desired sub-volume.
            % X2 - Last pixel in x-dimension for desired sub-volume.
            % Y1 - First pixel in y-dimension for desired sub-volume.
            % Y2 - Last pixel in y-dimension for desired sub-volume.
            %
            % Outputs:
            % oIm - Image number aFrame in the image sequence. If the image
            %       sequence is in 3D, the function returns the maximum
            %       intensity projection or one of the z-planes depending
            %       on the ZPlane parameter.
            %
            % See also:
            % GetDoubleImage, GetIntensityCorrectedImage, GetUint8Image,
            % GetShownImage, GetZStack, GetDoubleZStack, GetUint8ZStack
            
            
            % Get additional input arguments for this function.
            [aChannel, aZPlane, aPixelRegion, aX1, aX2, aY1, aY2] = GetArgs(...
                {'Channel', 'ZPlane', 'PixelRegion', 'X1', 'X2', 'Y1', 'Y2'},...
                {1, 0, {}, 1, this.imageWidth, 1, this.imageHeight},...
                true,...
                varargin);
            
            % Get the index of the channel to be read.
            if isnumeric(aChannel)
                channelIndex = aChannel;
            else
                channelIndex = find(strcmp(this.channelNames, aChannel));
            end
            
            if this.cachedFrame ~= aFrame
                % Remove all cached images.
                this.cachedImages = cell(length(this.channelNames), this.numZ);
            end
            
            if this.GetDim() == 2
                if ~isempty(this.cachedImages{channelIndex, 1}) && isempty(aPixelRegion)
                    % Use a cached image.
                    oIm = this.cachedImages{channelIndex, 1};
                else
                    if isempty(aPixelRegion)
                        oIm = imread(this.filenames{channelIndex}{aFrame});
                    else
                        if ~isempty(regexp(this.filenames{channelIndex}{aFrame},...
                                '(tif|tiff)$', 'once'))
                            % For tifs, we can cut out a pixel region in the
                            % call to imread.
                            oIm = imread(this.filenames{channelIndex}{aFrame},...
                                'PixelRegion', aPixelRegion);
                        else
                            % For other formats, the whole image is read and
                            % then the desired pixel region is cropped out.
                            oIm = imread(this.filenames{channelIndex}{aFrame});
                            oIm = CutPixelRegion(oIm, aPixelRegion);
                        end
                    end
                    
                    if size(oIm,3) > 1
                        % Convert color images to gray scale.
                        oIm = mean(oIm, 3);
                    end
                    
                    % Cache the returned image.
                    if isempty(aPixelRegion)
                        this.cachedImages{channelIndex, 1} = oIm;
                        this.cachedFrame = aFrame;
                    end
                end
            else
                if isequal(aZPlane, 0)
                    % Maximum intensity projection of the whole z-stack.
                    oIm = max(...
                        this.GetZStack(aFrame,...
                        'Channel', aChannel,...
                        'PixelRegion', aPixelRegion),...
                        [], 3);
                elseif length(aZPlane) == 1
                    if ~isempty(this.cachedImages{channelIndex, aZPlane})  &&...
                            isempty(aPixelRegion)
                        % Use a cached image.
                        oIm = this.cachedImages{channelIndex, aZPlane};
                    else
                        if this.zStacked
                            if isempty(regexp(this.filenames{channelIndex}{aFrame},...
                                    '(tif|tiff)$', 'once'))
                                error('Only tif-files can have zStacked set to 1.')
                            end
                            if isempty(aPixelRegion)
                                oIm = imread(this.filenames{channelIndex}{aFrame}, aZPlane);
                            else
                                oIm = imread(this.filenames{channelIndex}{aFrame}, aZPlane,...
                                    'PixelRegion', aPixelRegion);
                            end
                        else
                            if isempty(aPixelRegion)
                                oIm = imread(this.filenames{channelIndex}...
                                    {(aFrame-1)*this.numZ + aZPlane});
                            else
                                if ~isempty(regexp(this.filenames{channelIndex}{aFrame},...
                                        '(tif|tiff)$', 'once'))
                                    % For tifs, we can cut out a pixel region
                                    % in the call to imread.
                                    oIm = imread(this.filenames{channelIndex}...
                                        {(aFrame-1)*this.numZ + aZPlane},...
                                        'PixelRegion', aPixelRegion);
                                else
                                    % For other formats, the whole image is
                                    % read and then the desired pixel region is
                                    % cropped out.
                                    oIm = imread(this.filenames{channelIndex}...
                                        {(aFrame-1)*this.numZ + aZPlane});
                                    oIm = CutPixelRegion(oIm, aPixelRegion);
                                end
                            end
                        end
                        
                        if size(oIm,3) > 1
                            % Convert color images to gray scale.
                            oIm = mean(oIm, 3);
                        end
                        
                        % Cache the returned image.
                        if isempty(aPixelRegion)
                            this.cachedImages{channelIndex, aZPlane} = oIm;
                            this.cachedFrame = aFrame;
                        end
                    end
                else
                    % Maximum intensity projection of a range of z-planes.
                    oIm = max(...
                        this.GetZStack(aFrame,...
                        'Channel', aChannel,...
                        'ZPlane', aZPlane,...
                        'PixelRegion', aPixelRegion),...
                        [], 3);
                end
            end
            
            if (aX1 > 1 || aX2 < this.imageWidth || aY1 > 1 || aY2 < this.imageHeight)
                oIm = oIm(aY1:aY2, aX1:aX2);
            end
        end
        
        function oIm = GetDoubleImage(this, aFrame, varargin)
            % Returns an image with double values between 0 and 255.
            %
            % Except for the re-scaling and the conversion to a double
            % matrix, the function does the same thing as GetImage.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % The same as GetImage.
            %
            % Outputs:
            % oIm - Double matrix with values between 0 and 255.
            %
            % See also:
            % GetImage, GetIntensityCorrectedImage, GetUint8Image,
            % GetShownImage, GetZStack, GetDoubleZStack, GetUint8ZStack
            
            oIm = double(this.GetImage(aFrame, varargin{:}))/(2.^this.bits-1)*255;
        end
        
        function oIm = GetIntensityCorrectedImage(this, aFrame, aMethod, varargin)
            % Returns an image with normalized intensity.
            %
            % The function does the same thing as GetDoubleImage, but
            % adjusts the intensity of the image to have the mean 127.5,
            % either by adding a constant to all pixels or by multiplying
            % all pixels by a constant.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            % aMethod - Specifies if the correction should be done by
            %           adding a constant ('additive'), by multiplying with
            %           a constant ('multiplicative'), or not at all
            %           ('none'). The default is 'additive'.
            %
            % Property/Value inputs:
            % The same as GetImage.
            %
            % Outputs:
            % oIm - Image with normalized pixel intensities.
            %
            % See also:
            % GetImage, GetDoubleImage, GetUint8Image, GetShownImage,
            % GetZStack, GetDoubleZStack, GetUint8ZStack
            
            im = GetDoubleZStack(this, aFrame, varargin{:});
            
            switch lower(aMethod)
                case {'none', 0}
                    oIm = im;
                case {'additive', 1}
                    oIm = im + 127.5 - mean(im(:));
                case 'multiplicative'
                    oIm = im * 127.5 / mean(im(:));
                case 'sequencerange'
                    oIm = this.GetSequenceRescaledImage(aFrame, varargin{:});
            end
        end
        
        function ComputeSequenceMinAndMax(this)
            % Find min and max voxel values in the image sequence.
            if isempty(this.sequenceMaxIntensity)
                this.sequenceMaxIntensity = -inf;
                this.sequenceMinIntensity = inf;
                for t = 1:this.sequenceLength
                    fprintf('Computing min and max in frame %d / %d\n',...
                        t, this.sequenceLength)
                    im = GetDoubleZStack(this, t);
                    imMax = max(im(:));
                    imMin = min(im(:));
                    this.sequenceMaxIntensity =...
                        max(this.sequenceMaxIntensity, imMax);
                    this.sequenceMinIntensity =...
                        min(this.sequenceMinIntensity, imMin);
                    
                end
                fprintf('Sequence has voxels in the range [%f, %f]\n',...
                    this.sequenceMinIntensity, this.sequenceMaxIntensity)
            end
        end
        
        function oIm = GetSequenceRescaledImage(this, aFrame, varargin)
            % Rescales voxel values so that the min and max of the image
            % sequence are 0 and 255 respectively.
            
            this.ComputeSequenceMinAndMax()
            
            oIm = GetDoubleZStack(this, aFrame, varargin{:});
            % Rescale voxel values so that all voxel values are between 0
            % and 255 in the image sequence.
            oIm = (oIm - this.sequenceMinIntensity) /...
                (this.sequenceMaxIntensity - this.sequenceMinIntensity) * 255;
        end
        
        function oLim = GetTLim(this, aUnit, varargin)
            % Returns limits that should be used on the time axis in plots.
            %
            % The function finds the time interval to be plotted and can
            % add customizable margins on both sides.
            %
            % Inputs:
            % aUnit - The time unit to be used. The alternatives are
            %         'hours' and 'frames'.
            %
            % Property/Value inputs:
            % Margins - Two element array with margins to the left and
            %           right of the plotted time interval, given as
            %           fractions of the plotted time interval. As an
            %           example [0.01 0.05] gives a 1% margin to the left
            %           and a 5% margin to the right. The default is [0 0].
            
            % Parse property/value inputs:
            aMargins = GetArgs({'Margins'}, {[0 0]}, true, varargin);
            
            % Determine the plotted time interval in the specified unit.
            switch lower(aUnit)
                case 'frames'
                    oLim = [1 this.sequenceLength];
                case 'hours'
                    oLim = this.FrameToT([1 this.sequenceLength]);
                otherwise
                    error('Unknown time unit %s', aUnit)
            end
            
            % Make sure that the upper limit is larger than the lower.
            if oLim(2) == oLim(1)
                oLim(2) = oLim(2) + eps(oLim(2));
            end
            
            % Add margins to the left and right of the plotted interval.
            dLim = oLim(2) - oLim(1);
            oLim = oLim + [-aMargins(1) aMargins(2)] * dLim;
        end
        
        function oIm = GetUint8Image(this, aFrame, varargin)
            % Returns an 8-bit integer image.
            %
            % Except for the the conversion, the function does the same
            % thing as GetImage. uint8 images are faster to display in
            % axes than double images.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % The same as GetImage.
            %
            % Outputs:
            % oIm - uint8 image.
            %
            % See also:
            % GetImage, GetDoubleImage, GetIntensityCorrectedImage,
            % GetShownImage, GetZStack, GetDoubleZStack, GetUint8ZStack
            
            oIm = this.GetImage(aFrame, varargin{:});
            if ~isa(oIm, 'uint8')
                oIm = uint8(oIm/2^(this.bits-8)); % Integer division.
            end
        end
        
        function oImage = GetShownImage(this, aFrame, varargin)
            % Returns an image to be displayed in an axes.
            %
            % When displaying a single gray scale channel with no
            % rescaling, the method returns an uint8 image. When displaying
            % a single gray scale channel with rescaling, the method
            % returns a single channel double image with values between 0
            % and 1. When displaying multiple channels, the method returns
            % a 3 channel RBG image with values between 0 and 1. The
            % function is used only for display and the output is not meant
            % to be used for processing.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % Channels - Cell array of names or indices of all channels
            %            that should be displayed.
            % All property/value inputs taken by the MATLAB function imread
            % can also be given as property/value inputs.
            %
            % Outputs:
            % oImage - uint8 gray scale image or a 3 channel RGB image with
            %          values between 0 and 1.
            %
            % See also:
            % GetShownZStack, GetImage, GetDoubleImage,
            % GetIntensityCorrectedImage, GetUint8Image, GetZStack,
            % GetDoubleZStack, GetUint8ZStack
            
            % Separate input arguments for imread.
            [getShownImageArgs, imreadArgs] = SelectArgs(varargin, {'Channels'});
            
            % Get additional input arguments for this function.
            aChannels = GetArgs({'Channels'}, {1}, true, getShownImageArgs);
            
            % Get the indices of the channels to be read.
            visible = false(length(this.channelNames),1);
            if isnumeric(aChannels)
                visible(aChannels) = true;
            else
                for i = 1:length(aChannels)
                    visible(strcmp(this.channelNames, aChannels{i})) = true;
                end
            end
            
            if length(aChannels) == 1  &&...
                    this.channelMin(visible) == 0 &&...
                    this.channelMax(visible) == 1 &&...
                    this.IsTransChannel(aChannels)
                % Unaltered gray scale image.
                oImage = this.GetUint8Image(aFrame,...
                    'Channel', aChannels,...
                    imreadArgs{:});
            elseif length(aChannels) == 1  &&...
                    this.IsTransChannel(aChannels)
                % Rescaled gray scale image.
                oImage = this.GetDoubleImage(aFrame, 'Channel', aChannels, imreadArgs{:})/255;
                cmin = this.channelMin(visible);
                cmax = this.channelMax(visible);
                oImage = min(oImage, cmax); % Satturate.
                oImage = max(0, oImage-cmin+eps) / (cmax-cmin+eps); % Clip.
            else
                % Colored image or a scaled gray scale image.
                oImage = MergeImage(this, aFrame,...
                    'Visible', visible,...
                    imreadArgs{:});
            end
        end
        
        function oStack = GetShownZStack(this, aFrame, varargin)
            % Returns a z-stack for display.
            %
            % The function returns either a uint8 3-dimensional z-stack, or
            % a 4-dimensional z-stack where the forth dimension is
            % RGB-values for colors of the voxels. The uint8 output is used
            % to save time for z-stacks with a single channel and no
            % re-scaling of the intensity values. The function is used only
            % for display and the output is not meant to be used for
            % processing.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % Channels - Cell array of names or indices of all channels
            %            that should be displayed. By default, the first
            %            channel is displayed.
            % ZPlane - Array of z-plane indices to be read.
            % All property/value inputs taken by the MATLAB function imread
            % can also be given as property/value inputs.
            %
            % Outputs:
            % oImage - uint8 gray scale z-stack or a 4-dimensional array
            %          with RGB values between 0 and 1. The RGB-dimension
            %          is the fourth dimension.
            %
            % See also:
            % GetShownImage, GetZStack, GetDoubleZStack, GetUint8ZStack
            
            % Separate input arguments for imread.
            [getZStackArgs, imreadArgs] = SelectArgs(varargin,...
                {'Channels', 'ZPlane'});
            
            % Get additional input arguments for this function.
            [aChannels, aZPlane] = GetArgs(...
                {'Channels', 'ZPlane'},...
                {1, 1:this.numZ},...
                true,...
                getZStackArgs);
            
            % Allocates the whole stack. It is not known which data type
            % the output will have, so it cannot be pre-allocated using
            % zeros.
            oStack(:,:,aZPlane(end),:) = this.GetShownImage(aFrame,...
                'Channels', aChannels,...
                'ZPlane', aZPlane(end),...
                imreadArgs{:});
            for i = aZPlane(end-1):-1:aZPlane(1)
                oStack(:,:,i,:) = this.GetShownImage(aFrame,...
                    'Channels', aChannels,...
                    'ZPlane', i,...
                    imreadArgs{:});
            end
        end
        
        function oStack = GetZStack(this, aFrame, varargin)
            % Returns a z-stack with the original numeric type.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % Channel - Name or index of the channel to be read. By
            %           default, the first channel is read.
            % ZPlane - Array of z-plane indices to be read.
            % All property/value inputs taken by GetImage
            %
            % Outputs:
            % oStack - 3D array of a z-stack. The type is the same as the
            %          type of the saved file, and dimension 3 specifies
            %          different z-planes.
            %
            % See also:
            % GetImage, GetDoubleImage, GetIntensityCorrectedImage,
            % GetUint8Image,  GetShownImage, GetDoubleZStack,
            % GetUint8ZStack
            
            
            % Separate input arguments for imread.
            [getZStackArgs, imreadArgs] = SelectArgs(varargin,...
                {'Channel', 'ZPlane'});
            
            % Get additional input arguments for this function.
            [aChannel, aZPlane] = GetArgs(...
                {'Channel', 'ZPlane'},...
                {1, 1:this.numZ},...
                true,...
                getZStackArgs);
            
            % Allocates the whole stack. It is not known which data type
            % the output will have, so it cannot be pre-allocated using
            % zeros.
            for i =  length(aZPlane) : -1 : 1
                oStack(:,:,i) = this.GetImage(aFrame,...
                    'Channel', aChannel,...
                    'ZPlane', aZPlane(i),...
                    imreadArgs{:});
            end
        end
        
        function oStack = GetDoubleZStack(this, aFrame, varargin)
            % Returns a z-stack with double values between 0 and 1.
            %
            % The function reads all 2D images associated with a
            % particular time point and returns them as a 3D z-stack.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % Channel - Name or index of the channel to be read. By
            %           default, the first channel is read.
            % X1 - First pixel in x-dimension for desired sub-volume.
            % X2 - Last pixel in x-dimension for desired sub-volume.
            % Y1 - First pixel in y-dimension for desired sub-volume.
            % Y2 - Last pixel in y-dimension for desired sub-volume.
            % Z1 - First pixel in z-dimension for desired sub-volume.
            % Z2 - Last pixel in z-dimension for desired sub-volume.
            %
            % Outputs:
            % oStack - 3D array with a z-stack. Dimension 3 specifies
            %          different z-planes.
            %
            % See also:
            % GetImage, GetDoubleImage, GetIntensityCorrectedImage,
            % GetUint8Image,  GetShownImage, GetZStack, GetUint8ZStack
            
            % Separate input arguments for GetDoubleImage.
            [getDoubleZStackArgs, getDoubleImageArgs] =...
                SelectArgs(varargin, {'Z1', 'Z2'});
            
            % Get additional input arguments for this function.
            [aZ1, aZ2] = GetArgs(...
                {'Z1', 'Z2'},...
                {1, this.numZ},...
                true,...
                getDoubleZStackArgs);
            
            zPlanes = aZ1:aZ2;
            for i = length(zPlanes) : -1 : 1
                oStack(:,:,i) = this.GetDoubleImage(aFrame,...
                    'ZPlane', zPlanes(i),...
                    getDoubleImageArgs{:});
            end
        end
        
        function oStack = GetUint8ZStack(this, aFrame, varargin)
            % Returns a z-stack with 8-bit integer values.
            %
            % The function reads all 2D images associated with a particular
            % time point and returns them as a 3D z-stack. The pixel values
            % are converted to uint8.
            %
            % Inputs:
            % aFrame - Index of the time point to be read.
            %
            % Property/Value inputs:
            % All property/value inputs taken by the MATLAB function
            % imread.
            %
            % Outputs:
            % oStack - 3D array of a z-stack. Dimension 3 specifies
            %          different z-planes.
            %
            % See also:
            % GetImage, GetDoubleImage, GetIntensityCorrectedImage,
            % GetUint8Image,  GetShownImage, GetZStack, GetDoubleZStack
            
            oStack = zeros(this.imageHeight, this.imageWidth, this.numZ, 'uint8');
            for i = 1:this.numZ
                oStack(:,:,i) = this.GetUint8Image(aFrame, varargin{:}, 'ZPlane', i);
            end
        end
        
        function oDir = GetCellDataDir(this, varargin)
            % Returns the full path of a folder with tracking results.
            %
            % By default, the the folder of the current tracking version is
            % returned, but the user can also specify other tracking
            % versions. If no tracking version is specified, and there is
            % no current tracking version, the function will generate an
            % error.
            %
            % Property/Value inputs:
            % Version - Label of tracking version, excluding the
            %           CellData-prefix. If no tracking version is
            %           specified, the current tracking version is used.
            %
            % Outputs:
            % oDir - Full path of the CellData-folder with tracking
            %        results.
            
            aVersion = GetArgs({'Version'}, {this.version}, true, varargin);
            
            % Check the version name.
            if ~ischar(aVersion)
                if isempty(aVersion)  % Checks for [].
                    error('No tracking version has been specified.')
                else
                    error('The specified tracking version is not a string.')
                end
            end
            
            oDir = fullfile(this.GetExPath(), 'Analysis', ['CellData' aVersion]);
        end
        
        function oPath = GetLogPath(this, varargin)
            % Returns the path of a text file for processing information.
            %
            % The text file will contain information about the program, and
            % can also contain user specified notes. These files are
            % created using the function WriteLog.
            %
            % Property/Value inputs:
            % Version - Label of tracking version, excluding the
            %           CellData-prefix. If no tracking version is
            %           specified, the current tracking version is used.
            %
            % Outputs:
            % oPath - Full path of the txt-file.
            %
            % See also:
            % WriteLog
            
            oPath = fullfile(this.GetCellDataDir(varargin{:}),...
                'Logs', [this.GetSeqDir() '.txt']);
        end
        
        function oDir = GetResumePath(this, varargin)
            % Returns the full path of a folder with intermediate results.
            %
            % The files with intermediate tracking results can be used to
            % resume processing after a crash or a termination of the
            % program. By default, the current tracking version is used,
            % but the label of another tracking version can be given as an
            % additional input.
            %
            % Property/Value inputs:
            % Version - Label of tracking version, excluding the
            %           CellData-prefix. If no tracking version is
            %           specified, the current tracking version is used.
            %
            % Outputs:
            % oDir - Character array with a full path name.
            
            oDir = fullfile(this.GetCellDataDir(varargin{:}),...
                'Resume', this.GetSeqDir());
        end
        
        function LoadSegImData(this)
            % Crates an ImageData object for a folder with label images.
            %
            % The created ImageData object can be used to access
            % label images that are supposed to be loaded as a
            % segmentation. This function needs to be called if the setting
            % SegImportFolder is changed.
            
            segFolder = fullfile(...
                this.GetAnalysisPath(),...
                this.Get('SegImportFolder'),...
                this.GetSeqDir());
            this.segImData = ImageData(segFolder);
            this.segImData.Set('numZ', this.numZ);
            this.segImData.Set('zStacked', this.zStacked);
        end
    end
end