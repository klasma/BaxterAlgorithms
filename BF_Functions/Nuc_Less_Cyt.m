 function [Nuc,Ratio] = Nuc_Less_Cyt(NucTopHat,CytTopHat,Nuc_bw4,cyt_bw4,MiPerPix)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            NucTophatDisk=strel('disk',round(250*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(5*(0.34/MiPerPix)));
            NucErodeDisk=strel('disk',round(6*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(4*(0.34/MiPerPix)));    

NucTopHat(~Nuc_bw4)=0;
CytTopHat(~cyt_bw4)=0;
NucMed=median(NucTopHat(NucTopHat>1),'all');
CytMed=median(CytTopHat(CytTopHat>1),'all');
Ratio=double(NucMed)/double(CytMed);
Nuc=NucTopHat-CytTopHat.*Ratio;
Nuc=imdilate(Nuc,NucCloseDisk);
% Nuc=imclose(Nuc,NucCloseDisk);
       
 end

