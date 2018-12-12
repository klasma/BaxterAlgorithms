function oTitle = GetTitle(aProperty, a3D)
% Returns short descriptions to put as titles on plots.
%
% Inputs:
% aProperty - The name of the property to be plotted.
% a3D - True if a 3D dataset is analyzed.
%
% See also:
% GetTitle

switch aProperty
    case 'avgSpeed'
        oTitle = 'Average speed (total distance traveled / lifetime)';
    case 'avgAxisRatio'
        oTitle = 'Average ratio between major and minor axes';
    case 'avgSize'
        if a3D
            oTitle = 'Average volume of cell';
        else
            oTitle = 'Average area of cell seen from above';
        end
    case 'divisionTime'
        oTitle = 'Time between divisions';
    case 'timeToFirstDivision'
        oTitle = 'Time to division for cells present in the first frame';
    case 'timeOfBirth'
        oTitle = 'Time when the cell is created through division';
    case 'lifeSpan'
        oTitle = 'The time that the cell is present in the experiment.';
    case 'deltaT'
        oTitle = 'Delta-T, (difference in division time between sisters)';
    case 'timeToDeath'
        oTitle = 'Time from birth to death';
    otherwise
        % Handle fluorescence properties.
        channel = regexp(aProperty, '(?<=Fluor(Max|Avg|Tot)).*', 'match', 'once');
        metric = regexp(aProperty, '(?<=Fluor)\w{3}', 'match', 'once');
        if ~isempty(metric)
            switch lower(metric)
                case 'max'
                    oTitle = sprintf('Maximum fluorescence (%s)', channel);
                case 'avg'
                    oTitle = sprintf('Average fluorescence (%s)', channel);
                case 'tot'
                    oTitle = sprintf('Total fluorescence (%s)', channel);
            end
        else
            oTitle = 'UNKNOWN PROPERTY';
        end
end
end