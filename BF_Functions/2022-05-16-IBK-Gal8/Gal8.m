function [Gal_bw_Perim,Gal8Quant3,Gal_Label,Data] = Gal8(Img,AnaSettings,CytPos,MiPerPix)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            Gal8TophatDisk=strel('disk',round(6*(0.34/MiPerPix)));% EditHere
            Gal8OpenDisk =strel('square',round(2*(0.34/MiPerPix)));
            Gal8DilateDisk=strel('disk',round(1*(0.34/MiPerPix)));
            Gal8OutlineDisk=strel('disk',round(3*(0.34/MiPerPix)));
Gal8MinThreshold=AnaSettings{1};
Gal8_Img=wiener2(Img);
Gal8TH=imtophat(Gal8_Img,Gal8TophatDisk);
Gal8Open=imopen(Gal8TH,Gal8OpenDisk);

Gal8MinValue= Gal8MinThreshold*intmax(class(Img));
Gal8Quant2=Gal8Open-Gal8MinValue;
Gal8Quant2(Gal8Quant2<=0)=0;
Gal8Quant3=bwareaopen(Gal8Quant2,4);
% Gal8Quant3(~Cyt_WS)=0;
Gal8Quant3(~CytPos)=0;
Gal8Quant3=imdilate(Gal8Quant3,Gal8DilateDisk);
Gal8Quant4=imdilate(Gal8Quant3,Gal8OutlineDisk);
Gal_bw_Perim=imbinarize(Gal8Quant4-Gal8Quant3);
GalPals=Img;
GalPals(~Gal8Quant3)=0;

 NucOpenDisk= strel('disk',round(10*(0.34/MiPerPix)));
%  Gal8Fuzz=imopen(Img,NucOpenDisk);
GalConn=bwconncomp(Gal8Quant3);
       Gal_Label = labelmatrix(GalConn);
       
       Data = {1};
% Puncta=regionprops(Gal8Quant3,Img,'Area','Centroid','MeanIntensity');
% Background=regionprops(Gal8Quant3,Gal8Fuzz,'Area','Centroid','MeanIntensity'); %need to figure out way to subtract out surrounding brightness for each individual Point


% RingMeanInt=2; %need to figure out way to subtract out surrounding brightness for each individual Point
% Gal8Signal=sum((vertcat(Puncta.MeanIntensity).*vertcat(Puncta.Area)));
% Gal8Signal=Gal8Signal';
end

