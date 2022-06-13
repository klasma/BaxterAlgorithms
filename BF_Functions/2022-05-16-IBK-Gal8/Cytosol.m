function [cyt_bw4,cyt_bw4_perim,CytLabel,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            CytTophatDisk=strel('disk',round(250*(0.34/MiPerPix))); % EditHere
            CytOpenDisk =strel('disk',round(4*(0.34/MiPerPix)));
            CytErodeDisk=strel('disk',round(1*(0.34/MiPerPix)));
            CytCloseDisk=strel('disk',round(4*(0.34/MiPerPix))); 
            MinCellSize=2000*((0.34/MiPerPix)^2);
Low=AnaSettings{1};
Max=AnaSettings{2};
CytTopHat=imtophat(AnaImage,CytTophatDisk); % Clean image with tophat filter for thresholding 
    CytOpen=imerode(CytTopHat,CytOpenDisk);
     CytOpen=imreconstruct(CytOpen,CytTopHat);
%     cyt_eq =imadjust(CytTopHat,[0 0.25],[]);   %Make it easy to see
    
    CytMaxValue= Max*intmax(class(AnaImage));
    CytOverbright=CytOpen>CytMaxValue;
    CytBright=CytOpen;
    CytAvg=mean(CytOpen,'all');
    CytBright(CytOverbright)=CytMaxValue;
        CytMT1=multithresh(CytBright,20); %Calculate 20 brightness thresholds for image 
        CytQuant1=imquantize(CytBright,CytMT1); %Divide Image into the 20 brightness baskets
%          figure, imshow(label2rgb(CytQuant1))
        CytBrightEnough=CytQuant1>Low;
        
        CytPos=CytBrightEnough;
%         CytPos(~CytBrightEnough)=0;
           cyt_bw2=imerode(CytPos,CytErodeDisk);
          cyt_bw3 = bwareaopen(cyt_bw2, MinCellSize); %%Be sure to check this threshold
          cyt_bw4 = imclose(cyt_bw3, CytCloseDisk);
          CytPos(~cyt_bw4)=0;
        cyt_bw4_perim = imdilate(bwperim(cyt_bw4),strel('disk',2));
%        CytArea = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
%         CytCytOverlay = imoverlay(cyt_eq, cyt_bw4_perim, [.3 1 .3]);
        CytLabel = cyt_bw4; % added because too many output parameters in GUI - fix later
        
        Data = {Max};
end

