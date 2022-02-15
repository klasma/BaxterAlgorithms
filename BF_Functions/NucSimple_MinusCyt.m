function [NucLabel,Nuc_bw4,NucPos,NucBrightEnough,NucOpen,Nuc_eq,NucTopHat,Nuc_bw4_perim,NucOverbright,NucWeiner,NucArea] = NucSimple_MinusCyt(Img,Low,Max,MiPerPix,cyt_bw4,Cyt,Ratio)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            NucTophatDisk=strel('disk',round(250*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(5*(0.34/MiPerPix)));
            NucErodeDisk=strel('disk',round(6*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(4*(0.34/MiPerPix)));    
%Pre-Processing
NucWeiner=wiener2(Img);
    NucTopHat=imtophat(NucWeiner,NucTophatDisk); % Clean image with tophat filter for thresholding 
    Nuc_eq =imadjust(NucTopHat);   %Make it easy to see
    
    NucCyt=NucTopHat-Cyt*Ratio;
    NucCyt(~cyt_bw4)=0;
    NucCyt(NucCyt<0)=0;
      
    NucOpen=imopen(NucCyt,NucOpenDisk);
    NucMaxValue= Max*intmax(class(Img));
    NucOverbright=NucTopHat>NucMaxValue;
    NucOpen(NucOverbright)=0;
    
    
    NucOpen(~cyt_bw4)=0;
    NucOpen=NucOpen-Cyt*Ratio;
%         
        NucBrightEnough=NucOpen>Low;
        NucPos=NucOpen;
        NucPos(~NucBrightEnough)=0;
%         NucPos=imadjust(NucPos);
          Nuc_bw2=imerode(NucPos,NucErodeDisk);
          Nuc_bw3 = bwareaopen(Nuc_bw2, 250); %%Be sure to check this threshold
          Nuc_bw4 = imclose(Nuc_bw3, NucCloseDisk);
          Nuc_bw4 = imfill(Nuc_bw4,'holes');
        Nuc_bw4_perim = imdilate(bwperim(Nuc_bw4),strel('disk',3));
       
       NucConn=bwconncomp(Nuc_bw4);
       NucLabel = labelmatrix(NucConn);
       NucArea = imoverlay(Nuc_eq, Nuc_bw4_perim, [.3 1 .3]);
       
end

