function [oT, oZ] = CTCGTPlanes(aSeqPath)
% Returns time points and z-plane indices in segmentation ground truths.
%
% The function looks for segmentation ground truths in the format of the
% Cell Tracking Challenges, and returns lists of time points and z-planes
% which have ground truth segmentations. If no ground truth exists, the
% function will return empty arrays.
%
% Inputs:
% aSeqPath - Full path of the image sequence.
%
% Outputs:
% oT - Time points which have manually segmented cells in the ground truth.
%      The indexing starts from 1.
% oZ - Z-planes which have manually segmented cell outlines in the ground
%      truth. The indexing starts from 1. For 2D data, oZ is a NaN-array of
%      the same size as oT.

% Find the path of the ground truth folder.
[exPath, seqDir] = fileparts(aSeqPath);
gtPath = fullfile(exPath, 'Analysis', [seqDir '_GT']);
if ~exist(gtPath, 'dir')
    % Some ground truth folders only use the last 2 letters from the image
    % sequence name.
    gtPath = fullfile(exPath, 'Analysis', [seqDir(end-1:end) '_GT']);
end

% Return empty arrays if no ground truth folder was found.
if ~exist(gtPath, 'dir')
    oT = [];
    oZ = [];
    return
end

% Get the names of the ground truth files.
imNames = GetNames(fullfile(gtPath, 'SEG'), 'tif');

% Extract the time points and the z-planes from the file names. The
% indexing starts from 0 in the file names and from 1 in the outputs.
oT = str2double(regexp(imNames,...
    '(?<=man_seg_?)\d+', 'match', 'once')) + 1;
oZ = str2double(regexp(imNames,...
    '(?<=man_seg_\d+_)\d+', 'match', 'once')) + 1;
end