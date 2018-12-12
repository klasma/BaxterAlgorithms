classdef ToggleButton < handle
    % Toggle button with two states and an image for each state.
    %
    % A ToggleButton holds the uicontrol button object, and images for the
    % pressed and the un-pressed states of the button. The object can also
    % hold a textbox which is disabled when the button is in the un-pressed
    % state.
    %
    % See also:
    % PushButton
    
    properties
        uicontrol                    % uicontrol of the togglebutton type.
        rawImageUnpressed            % Original image for the un-pressed state.
        rawImagePressed              % Original image for the pressed state.
        resizedImageUnpressed = [];  % Image for the un-pressed state, resized to fit on the button.
        resizedImagePressed = [];    % Image for the pressed state, resized to fit on the button.
        uicontrolTextBox             % Optional text box associated with the button.
    end
    
    methods
        function this = ToggleButton(...
                aUicontrolObj,...
                aImagePathUnpressed,...
                aImagePathPressed,...
                aUicontrolTextBox)
            % Constructor, reads raw images from files.
            %
            % Inputs:
            % aUicontrolObj - uicontrol object to be used for the button.
            % aImagePathUnpressed - Path of image for the un-pressed state.
            % aImagePathPressed - Path of image for the pressed state.
            % aUicontrolTextBox - Text box associated with the button. If
            %                     no text box is needed, this input should
            %                     be [];
            
            this.uicontrol = aUicontrolObj;
            this.uicontrolTextBox = aUicontrolTextBox;
            this.rawImageUnpressed = imread(FindFile('Icons', aImagePathUnpressed));
            this.rawImagePressed = imread(FindFile('Icons', aImagePathPressed));
            this.resizedImageUnpressed = [];
            this.resizedImagePressed = [];
        end
        
        function Draw(this)
            % Resizes and draws image.
            
            % Get the button size without changing the 'Units' property.
            set(this.uicontrol, 'Units', 'Pixels')
            posArray = get(this.uicontrol, 'Position');
            set(this.uicontrol, 'Units', 'Normalized')
            
            % Resize pressed and un-pressed images.
            this.resizedImageUnpressed =...
                imresize(this.rawImageUnpressed, [posArray(4) posArray(3)]);
            this.resizedImagePressed =...
                imresize(this.rawImagePressed, [posArray(4) posArray(3)]);
            
            % Add the correct resized image to the button.
            if get(this.uicontrol, 'Value')
                set(this.uicontrol, 'CData', this.resizedImagePressed)
            else
                set(this.uicontrol, 'CData', this.resizedImageUnpressed)
            end
        end
        
        function Unselect(this)
            % Changes the state to un-pressed and disables the textbox.
            
            set(this.uicontrol, 'CData', this.resizedImageUnpressed)
            set(this.uicontrol, 'Value', 0)
            if ~isempty(this.uicontrolTextBox)
                set(this.uicontrolTextBox, 'Enable', 'off')
            end
        end
        
        function Select(this)
            % Changes the state to pressed and enables the textbox.
            
            set(this.uicontrol, 'CData', this.resizedImagePressed)
            set(this.uicontrol, 'Value', 1)
            if ~isempty(this.uicontrolTextBox)
                set(this.uicontrolTextBox, 'Enable', 'on')
            end
        end
    end
end