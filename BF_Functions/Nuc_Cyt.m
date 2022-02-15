function [NucLabel,Nuc_bw4,NucPos,NucBrightEnough,NucMT1,NucOpen,Nuc_eq,NucTopHat,Nuc_bw4_perim,NucOverbright,NucQuant1,NucWeiner,NucArea] = Nuc_Cyt(Img,Low,Max,Scaling,CytTopHat,cyt_bw4,MiPerPix)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            NucTophatDisk=strel('disk',round(250*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(12*(0.34/MiPerPix)));
            NucErodeDisk=strel('disk',round(6*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(6*(0.34/MiPerPix)));    

NucWeiner=wiener2(Img);
    NucTopHat=imtophat(NucWeiner,NucTophatDisk); % Clean image with tophat filter for thresholding 
%     NucOpen=imerode(NucTopHat,NucOpenDisk);
%      NucOpen=imreconstruct(NucOpen,NucTopHat);
    Nuc_eq =imadjust(NucTopHat);   %Make it easy to see
    
     NucMaxValue= Max*intmax(class(Img));
    
    NucOverbright=NucTopHat>NucMaxValue;
    
    NucTopHat(NucOverbright)=mean(NucTopHat,'all');
   NucOpen=NucTopHat;
    CytTopHat(~cyt_bw4)=0;
    NucOpen(~cyt_bw4)=0;
    NucMed=median(NucOpen(NucOpen>1),'all');
CytMed=median(CytTopHat(CytTopHat>1),'all');
Ratio=double(NucMed)/double(CytMed);
NucOpen=NucOpen-CytTopHat.*Ratio.*Scaling;
    NucOpen=imopen(NucOpen,NucOpenDisk);
    
        NucMT1=multithresh(NucOpen,20); %Calculate 20 brightness thresholds for image 
        NucQuant1=imquantize(NucOpen,NucMT1); %Divide Image into the 20 brightness baskets
%         NucMT1=1;
%         NucQuant1=1;
        NucBrightEnough=NucQuant1>Low;
%         NucBrightEnough=NucOpen>Low;
        NucPos=NucOpen;
        NucPos(~NucBrightEnough)=0;
%         NucPos=imadjust(NucPos);


          Nuc_bw2=imerode(NucPos,NucErodeDisk);
          Nuc_bw3 = bwareaopen(Nuc_bw2, 250); %%Be sure to check this threshold
          Nuc_bw4 = imclose(Nuc_bw3, NucCloseDisk);
          Nuc_bw4 = imfill(Nuc_bw4,'holes');
          Nuc_bw4(~cyt_bw4)=0;
        Nuc_bw4_perim = imdilate(bwperim(Nuc_bw4),strel('disk',2));
       
       NucConn=bwconncomp(Nuc_bw4);
       NucLabel = labelmatrix(NucConn);
       NucArea = imoverlay(Nuc_eq, Nuc_bw4_perim, [.3 1 .3]);

       
            
  
%        NucTopHat(~Nuc_bw4)=0;
% CytTopHat(~cyt_bw4)=0;
% NucMed=median(NucTopHat(NucTopHat>1),'all');
% CytMed=median(CytTopHat(CytTopHat>1),'all');
% Ratio=double(NucMed)/double(CytMed);
% Nuc=NucTopHat-CytTopHat.*Ratio;
% Nuc=imdilate(Nuc,NucCloseDisk);
       
       
       
end

