function [AllData] = LabelAnalysis(LiveData,Img2,Well,Timepoint,AllData)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    for stella=1:length(LiveData)
        wellname=matlab.lang.makeValidName(strcat('w',Well));
        timename=matlab.lang.makeValidName(strcat('t',Timepoint));
        
         area= nnz(LiveData{1,stella}.bw4);
         AllData.(wellname).(timename)(stella,1)= stella;
         AllData.(wellname).(timename)(stella,2)= area;
        for milo=1:length(Img2(1,1,:))
            DataImage=Img2(:,:,milo);
            SumInt=sum(DataImage(LiveData{1,stella}.bw4));
            InvInt=sum(DataImage(~LiveData{1,stella}.bw4));
            Place=2+milo*2;
            Place2=3+milo*2;
            AllData.(wellname).(timename)(stella,Place)= SumInt;
            AllData.(wellname).(timename)(stella,Place2)= InvInt;
        end
    end
end

