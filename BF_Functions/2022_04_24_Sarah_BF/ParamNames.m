function [ExportParamNames] = ParamNames(numPlanes)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
        NamCell = {}; 
        ExportParamNames = {'Well','Timepoint','Analysis Pass','Area Mask','LabelMax'};
         for g=1:numPlanes
         IntName=strcat('P',num2str(g),'Intensity_OverMask');
         InvName=strcat('P',num2str(g),'Intensity_NotOverMask');
         PlaneName={IntName,InvName};
         NamCell=[NamCell,PlaneName];
         end
         ExportParamNames = [ExportParamNames, NamCell];
end

