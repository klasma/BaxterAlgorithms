function [cyt_bw4,cyt_bw4_perim,CytLabel] = Cytosol(AnaImage,AnaSettings,MiPerPix)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            CytTophatDisk=strel('disk',round(250*(0.34/MiPerPix))); % EditHere
            CytOpenDisk =strel('disk',round(5*(0.34/MiPerPix)));
            CytErodeDisk=strel('disk',round(2*(0.34/MiPerPix)));
            CytCloseDisk=strel('disk',round(5*(0.34/MiPerPix))); 
Low=AnaSettings{1};
Max=AnaSettings{2};
CytTopHat=imtophat(AnaImage,CytTophatDisk); % Clean image with tophat filter for thresholding 
    CytOpen=imerode(CytTopHat,CytOpenDisk);
     CytOpen=imreconstruct(CytOpen,CytTopHat);
    cyt_eq =imadjust(CytTopHat,[0 0.25],[]);   %Make it easy to see
    
    CytMaxValue= Max*intmax(class(AnaImage));
    CytOverbright=CytOpen>CytMaxValue;
    CytBright=CytOpen;
    CytAvg=mean(CytOpen,'all');
    CytBright(CytOverbright)=CytAvg;
        CytMT1=multithresh(CytBright,20); %Calculate 20 brightness thresholds for image 
        CytQuant1=imquantize(CytBright,CytMT1); %Divide Image into the 20 brightness baskets
        CytBrightEnough=CytQuant1>Low;
        
        CytPos=CytOpen;
%         CytPos(~CytBrightEnough)=0;
           cyt_bw2=imerode(CytPos,CytErodeDisk);
          cyt_bw3 = bwareaopen(cyt_bw2, 2000); %%Be sure to check this threshold
          cyt_bw4 = imclose(cyt_bw3, CytCloseDisk);
          CytPos(~cyt_bw4)=0;
        cyt_bw4_perim = imdilate(bwperim(cyt_bw4),strel('disk',2));
       CytArea = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
        CytCytOverlay = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
        CytLabel = 'CytLabel'; % added because too many output parameters in GUI - fix later
end

