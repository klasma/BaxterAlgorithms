% function [outputArg1,outputArg2] = Partition(AnaSettings,inputArg2)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
AnaImage;

Channels=ImageAnalyses{6,:}{2};

S=struct;
WellField=strcat('W',char(Well));
TimeField=strcat('T',char(Timepoint));
for j= 1:length(Channels)
    PartChan=Channels{j};
    PartChan = strcat('Chan',num2str(PartChan,'%02.f'));
for i= 1:length(AnaSettings(:))
    PartMask=(AnaSettings{i});
    PartMaskField=strrep(PartMask,'~','Inverse_');
    
    a=eval(PartMask);
        if ~exist('Cyt_WS','var')
        Cyt_WS=ones(size(a));
        end
        Cyt_WS_Part=Cyt_WS+4;
        Test_1 = Cyt_WS==0 & a ==0;
        Test_2 = Cyt_WS>0 & a ==0;
        Test_3 = Cyt_WS==0 & a>0;
        Cyt_WS_Part(Test_1)=1;
        Cyt_WS_Part(Test_2)=2;
        Cyt_WS_Part(Test_3)=3;
        for h = 1:max(Cyt_WS_Part,[],'all','omitnan')
            CellField=strcat('Cell',num2str(h,'%02.f'));
            CurrCell=Cyt_WS_Part==h;
            CellValues=AnaImage(CurrCell);
                CellName(1,h) = h; 
                Sum(1,h)= sum(CellValues,'all');
                Mean(1,h)= mean(CellValues,'all');
                varNames = {'Cell','Sum','Mean'};         
%             S=setfield(S,WellField,TimeField,PartChan,PartMaskField,CellField,'Max',Max);
        end
        CellTable=table(CellName',Sum',Mean','VariableNames',varNames);
        S=setfield(S,WellField,TimeField,PartChan,PartMaskField,CellTable);
       
    
end

end