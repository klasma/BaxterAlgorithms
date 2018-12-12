classdef PushButton < handle
    % PushButtons are buttons with images on them.
    %
    % A PushButton holds the uicontrol button object, the original image,
    % and a resized image.
    %
    % See also:
    % ToggleButton
    
    properties
        uicontrol           % uicontrol of the pushbutton type.
        rawImage            % The original RGB-image.
        resizedImage = [];  % Image which has been resized based on the button size.
    end
    
    methods
        function this = PushButton(aUicontrolObj, aImagePath)
            % Constructor, reads the raw image from a file.
            %
            % Inputs:
            % aUicontrolObj - The uicontorol object for the button.
            % aImagePath - Path of the image.
            
            this.uicontrol = aUicontrolObj;
            this.rawImage = imread(FindFile('Icons', aImagePath));
        end
        
        function Draw(this)
            % Resizes and draws the image.
            
            % Get the button size without changing the Units property.
            set(this.uicontrol, 'Units', 'Pixels')
            posArray = get(this.uicontrol, 'Position');
            set(this.uicontrol, 'Units', 'Normalized')
            
            this.resizedImage = imresize(this.rawImage, [posArray(4) posArray(3)]);
            set(this.uicontrol, 'CData', this.resizedImage)
        end
    end
end