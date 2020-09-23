function ComputeRegionPropsCells(aCells, aImData)
% Computes parameters of cell regions, that can be used for analysis.
%
% The function computes region properties and properties of fluorescence
% channels for the blobs in Cell objects and saves them in the regionprops
% field in the Blob objects. This is done to make the data analysis step
% faster. Keep in mind that this function has to be called whenever the
% cells have been modified. Otherwise this pre-computed data will be
% incorrect.
%
% Inputs:
% aCells - Array of cell objects.
% aImData - ImageData object associated with the image sequence.
%
% See also:
% Cell, Blob

channels = aImData.GetReflectChannels();
blobSeq = Cells2Blobs(aCells, aImData, 'Sub', true);

% Compute region properties.
for i = 1:length(aCells)
    fprintf('Computing region properties for cell %d / %d.\n', i, length(aCells))
    for j = 1:length(aCells(i).blob)
        aCells(i).blob(j).Update(aImData);
    end
end

% Computes the maximum, average and total fluorescence inside the blob
% outline for all fluorescence channels and saves the results in the blob
% objects.
for chIndex = 1:length(channels)
    for t = 1:length(blobSeq)
        % Read in fluorescence image.
        fluor = aImData.GetDoubleZStack(t, 'Channel', channels{chIndex})/255;
        for bIndex = 1:length(blobSeq{t})
            b = blobSeq{t}(bIndex);
            
            if any(isnan(b.boundingBox))
                % The blob has no region associated with it.
                fMax = nan;
                fAvg = nan;
                fTot = nan;
            else
                % Fluorescence values of all the blob pixels.
                fluorPixels = b.GetPixels(fluor);
                
                % Convert to logical just in case.
                fMax = max(fluorPixels);
                fAvg = mean(fluorPixels);
                fTot = sum(fluorPixels);
            end
            
            % Store the computed values in the blob.
            b.regionProps.(['FluorMax' channels{chIndex}]) = fMax;
            b.regionProps.(['FluorAvg' channels{chIndex}]) = fAvg;
            b.regionProps.(['FluorTot' channels{chIndex}]) = fTot;
        end
    end
end
end