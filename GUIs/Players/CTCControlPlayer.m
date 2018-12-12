classdef CTCControlPlayer < ZControlPlayer
    % Extends ZControlPlayer to display CTC segmentation ground truths.
    %
    % If the displayed image sequences has a Cell Tracking Challenge SEG
    % ground truth in the Analysis folder, the player will show a dropdown
    % menu with all z-planes that have a ground truth. If the user selects
    % one of the z-planes, the player will jump to the selected frame and
    % z-plane. This makes it easy to display manual segmentation ground
    % truths together with processing results. The actual display of the
    % ground truth must be implemented in classes inheriting from this
    % class. The player can handle both 2D and 3D sequences, but in 2D
    % sequences, there is only a single z-plane.
    %
    % See also:
    % ZControlPlayer, SegmentationPlayer
    
    properties
        gtPanel = [];           % uipanel shown when there is a segmentation ground truth.
        gtSettingsPanel = [];   % SettingsPanel object with the dropdown menu.
        gtT = [];               % Array of time points for the manual ground truth images.
        gtZ = [];               % Array of z-planes for the manual ground truth images.
    end
    
    methods
        function this = CTCControlPlayer(aSeqPaths, varargin)
            % Constructs the player object and a figure associated with it.
            %
            % Inputs:
            % aSeqPath - Cell array with all image sequences that can be
            %            played.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        at the end of the constructor. This allows derived
            %        classes to postpone the call to Draw to the end of the
            %        derived class constructor. The default is true.
            % ControlWidth - Width of the uipanel for controls, as a
            %                fraction of the figure width. The default is
            %                0.1.
            
            % Get additional inputs.
            [aDraw, aControlWidth] = GetArgs(...
                {'Draw', 'ControlWidth'}, {true, 0.1}, true, varargin);
            
            % Create the ZPlayer.
            this = this@ZControlPlayer(aSeqPaths,...
                'Draw', false,...
                'ControlWidth', aControlWidth);
            
            % Create uipanel.
            this.gtPanel = uipanel(...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [1.0025-this.controlWidth, 0.95,...
                this.controlWidth-0.0025, 0.05]);
            
            % Create SettingsPanel inside uipanel.
            info.CTC_GT_plane = Setting(...
                'name', 'CTC GT plane',...
                'type', 'choice',...
                'default', {'select a plane'},...
                'alternatives_basic', {'select a plane'},...
                'tooltip', 'Switches to displaying a different image and z-plane.',...
                'callbackfunction', @this.GTPlaneCallback);
            this.gtSettingsPanel = SettingsPanel(info,...
                'Parent', this.gtPanel,...
                'Split', 0.6,...
                'RemoveFocus', true);
            
            this.UpdateGTPanel()
            
            if aDraw
                this.ReSizeAxes()
                this.ReSizeControls()
                this.Draw();
            end
        end
        
        function Draw3D(this)
            % Displays the image and de-selects ground truth planes.
            %
            % When the user switches to a different frame, the selected
            % ground truth plane needs to be de-selected, as the frame
            % number is no longer correct. This function de-selects the
            % ground truth plane if the frame number is incorrect. The
            % image is displayed in the same way as in ZPlayer.
            
            % Display the image.
            this.Draw3D@ZControlPlayer();
            
            % Get the index of the selected ground truth plane. The -1
            % comes from the fact that there is a 'select a plane' option
            % at the top of the popupmenu.
            index = this.gtSettingsPanel.GetIndex('CTC_GT_plane') - 1;
            if index == 0
                % The user selected 'select a plane'.
                return
            end
            
            % Select 'select a plane' if the frame number is incorrect.
            if this.frame ~= this.gtT(index)
                this.gtSettingsPanel.SetValue(...
                    'CTC_GT_plane', 'select a plane')
            end
        end
        
        function UpdateGTPanel(this)
            % Updates the dropdown menu for frames and z-planes.
            %
            % If the image sequence has no SEG ground truth, the popupmenu
            % is hidden. Otherwise, the popupmenu is shown and the options
            % are changed to match the frames and z-planes that have a SEG
            % ground truth.
            
            [this.gtT, this.gtZ] = CTCGTPlanes(this.GetImData().seqPath);
            
            if ~isempty(this.gtT)
                % There is a ground truth. Display a dropdown menu.
                
                set(this.controlPanel,...
                    'Position', [1.0025-this.controlWidth, 0,...
                    this.controlWidth-0.0025, 0.95])
                set(this.gtPanel,...
                    'Visible', 'on');
                
                % Creates strings with time points and z-planes.
                planeStrings = cell(size(this.gtT));
                for i = 1:length(this.gtT)
                    if ~isnan(this.gtZ(i))  % 3D
                        planeStrings{i} = sprintf('t = %03d, z = %03d',...
                            this.gtT(i), this.gtZ(i));
                    else  % 2D
                        planeStrings{i} = sprintf('t = %03d', this.gtT(i));
                    end
                end
                
                planeStrings = [{'select a plane'}; planeStrings];
                this.gtSettingsPanel.SetAlternatives(...
                    'CTC_GT_plane', 'basic', planeStrings)
                % A ground truth plane that was selected in the previous
                % image sequence may not be available in the new image
                % sequence. Therefore, the plane is de-selected when the
                % image sequence is switched.
                this.gtSettingsPanel.SetValue(...
                    'CTC_GT_plane', 'select a plane')
            else
                % There is no ground truth. Don't display a dropdown menu.
                set(this.controlPanel,...
                    'Position', [1.0025-this.controlWidth, 0,...
                    this.controlWidth-0.0025, 1])
                set(this.gtPanel,...
                    'Visible', 'off');
            end
        end
        
        function SwitchSequence(this, aIndex, varargin)
            % Redefined to update the popupmenu for a new sequence.
            %
            % Inputs:
            % aIndex - The index of the new image sequence.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        a the end of the function. This allows derived classes
            %        to postpone the call to Draw to the end of a redefined
            %        SwitchSequence in the derived class. The default is
            %        true.
            
            this.SwitchSequence@ZControlPlayer(aIndex, varargin{:})
            this.UpdateGTPanel()
        end
        
        function GTPlaneCallback(this, ~, ~)
            % Switches frame and z-plane when the user makes a selection.
            %
            % This is a callback of the popupmenu for segmentation ground
            % truths, which switches to the selected frame and z-plane. The
            % option to show a maximum intensity projection in the
            % z-dimension is turned off.
            
            % The -1 comes from the fact that there is a 'select a plane'
            % option at the top of the popupmenu.
            index = this.gtSettingsPanel.GetIndex('CTC_GT_plane') - 1;
            if index == 0
                % The user selected 'select a plane'.
                return
            end
            
            this.frame = this.gtT(index);
            if ~isnan(this.gtZ(index))
                this.z = this.gtZ(index);
                this.volumeSettingsPanel.SetValue('z', this.z)
                set(this.zSlider, 'Value', this.z)
                this.volumeSettingsPanel.SetValue('z_proj', false)
            end
            this.Draw()
        end
    end
end