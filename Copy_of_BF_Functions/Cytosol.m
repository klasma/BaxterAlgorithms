function [CytBright,CytArea,CytCytOverlay,cyt_bw4,CytPos,CytBrightEnough,CytMT1,CytOpen,cyt_eq,CytTopHat,cyt_bw4_perim] = Cytosol(cyt,CytTophatDisk,CytMax,CytOpenDisk,CytErodeDisk,CytLow,CytCloseDisk)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
 CytTopHat=imtophat(cyt,CytTophatDisk); % Clean image with tophat filter for thresholding 
    CytOpen=imerode(CytTopHat,CytOpenDisk);
     CytOpen=imreconstruct(CytOpen,CytTopHat);
    cyt_eq =imadjust(CytTopHat,[0 0.25],[]);   %Make it easy to see
    
    CytMaxValue= CytMax*intmax(class(cyt));
    CytOverbright=CytOpen>CytMaxValue;
    CytBright=CytOpen;
    CytBright(CytOverbright)=0;
        CytMT1=multithresh(CytBright,20); %Calculate 20 brightness thresholds for image 
        CytQuant1=imquantize(CytBright,CytMT1); %Divide Image into the 20 brightness baskets
        CytBrightEnough=CytQuant1>CytLow;
        
        CytPos=CytBright;
        CytPos(~CytBrightEnough)=0;
          cyt_bw2=imerode(CytPos,CytErodeDisk);
          cyt_bw3 = bwareaopen(cyt_bw2, 2000); %%Be sure to check this threshold
          cyt_bw4 = imclose(cyt_bw3, CytCloseDisk);
          CytPos(~cyt_bw4)=0;
        cyt_bw4_perim = imdilate(bwperim(cyt_bw4),strel('disk',3));
       CytArea = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
        CytCytOverlay = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
end

