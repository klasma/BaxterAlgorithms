function oLabel = GetLabel(aProperty, a3D, varargin)
% Returns strings with units to put on the y-axes in plots.
%
% Inputs:
% aProperty - The name of the property to be plotted.
% a3D - True if a 3D dataset is analyzed
%
% Property/Value inputs:
% Short - If this input is true, a short version of the label
%         with only the name and the unit is returned.
%         Otherwise, the label can contain more information.
%         The default is false.
%
% See also:
% GetTitle

aShort = GetArgs({'Short'}, {false}, true, varargin);

if aShort
    switch aProperty
        case 'avgSpeed'
            oLabel = 'Speed (\mum/hr)';
        case 'avgAxisRatio'
            oLabel = 'Ratio';
        case 'avgSize'
            if a3D
                oLabel = 'Volume (\mum^3)';
            else
                oLabel = 'Area (\mum^2)';
            end
        case {'divisionTime' 'timeToFirstDivision',...
                'timeOfBirth', 'deltaT', 'timeToDeath',...
                'lifeSpan'}
            oLabel = 'Time (hours)';
        otherwise
            % Handle fluorescence properties.
            metric = regexp(aProperty, '(?<=Fluor)\w{3}', 'match', 'once');
            if ~isempty(metric)
                switch lower(metric)
                    case 'max'
                        oLabel = 'Relative intensity';
                    case 'avg'
                        oLabel = 'Relative intensity';
                    case 'tot'
                        if a3D
                            oLabel = 'Relative intensity * \mum^3';
                        else
                            oLabel = 'Relative intensity * \mum^2';
                        end
                end
            else
                oLabel = 'UNKNOWN PROPERTY';
            end
    end
else
    switch aProperty
        case 'avgSpeed'
            oLabel = 'Velocity (\mum/hr)';
        case 'avgAxisRatio'
            oLabel = 'Axis ratio';
        case 'avgSize'
            if a3D
                oLabel = 'Volume (\mum^3)';
            else
                oLabel = 'Area (\mum^2)';
            end
        case 'divisionTime'
            oLabel = 'Time to division (hours)';
        case 'timeToFirstDivision'
            oLabel = 'Time to first division (hours)';
        case 'timeOfBirth'
            oLabel = 'Time of birth (hours)';
        case 'lifeSpan'
            oLabel = 'Life span (hours)';
        case 'deltaT'
            oLabel = 'Time between sister divisions (hours)';
        case 'timeToDeath'
            oLabel = 'Time to death (hours)';
        otherwise
            % Handle fluorescence properties.
            metric = regexp(aProperty, '(?<=Fluor)\w{3}', 'match', 'once');
            if ~isempty(metric)
                switch lower(metric)
                    case 'max'
                        oLabel = 'Fluorescence (relative to max)';
                    case 'avg'
                        oLabel = 'Fluorescence (relative to max)';
                    case 'tot'
                        if a3D
                            oLabel = 'Fluorescence (relative to max) * Volume in \mum^3';
                        else
                            oLabel = 'Fluorescence (relative to max) * Area in \mum^2';
                        end
                end
            else
                oLabel = 'UNKNOWN PROPERTY';
            end
    end
end
end