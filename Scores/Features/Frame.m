function oFrame = Frame(aBlob, ~)
% Blob feature which extracts the zero based frame index of the blob.
%
% Inputs:
% aBlob - Blob object.
%
% Outputs:
% oFrame - Zero based index of the frame that the blob belongs to.

oFrame = aBlob.t;
end