function [oScenario, oSNR, oDensity] = PTC12parameters(aSeqDir)
% Extracts images properties from folder names of the 2012 ISBI PTC.
%
% Inputs:
% aSeqDir - Name of the folder containing the image sequence. This should
%           only be the name and not the full path.
%
% Outputs:
% oScenario - Particle type in lower case ('vesicle', 'receptor',
%             'microtubule' or 'virus').
% oSNR - Signal to noise ratio as a double variable (usually 1, 2, 4 or 7).
% oDensity - Particle density ('low', 'mid' or 'high').

% Break the folder name into words separated by space.
words = regexp(aSeqDir, '\s', 'split');

if length(words) < 5
    error('The image sequence name does not match the format of the 2012 ISBI PTC.')
end

% Extract the properties.
oScenario = lower(words{1});
oSNR = str2double(words{3});
oDensity = words{5};

% Check that the properties are consistent.
if ~any(strcmpi(oScenario, {'vesicle' 'receptor' 'microtubule' 'virus'}))
    error('Unknown scenario %s', oScenario)
end
if isnan(oSNR) || oSNR < 1 || round(oSNR) ~= oSNR
    error('%s is not a valid SNR', words{3})
end
if ~any(strcmpi(oDensity, {'low' 'mid' 'high'}))
    error('Unknown density %s', oDensity)
end
end