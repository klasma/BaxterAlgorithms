function [Nuc_bw4,Nuc_bw4_perim,NucLabel,Data] = Nuc_ConsiderCyt(Img,AnaSettings,MiPerPix,Cyt)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
           %Import Settings
            NucTophatDisk=strel('disk',round(50*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(4*(0.34/MiPerPix)));
            NucErodeDisk=strel('diamond',round(6*(0.34/MiPerPix)));
            NucErodeDisk2=strel('square',round(8*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(4*(0.34/MiPerPix)));    
            Low=AnaSettings{1};
            Max=AnaSettings{2};
            Scaling=AnaSettings{3};
   
            
            
        %Pre-Processing    
            NucWeiner=wiener2(Img);
            NucTopHat=imtophat(NucWeiner,NucTophatDisk); % Clean image with tophat filter for thresholding 

        %Remove Extreme Values    
            NucOpen=NucTopHat;
            NucMaxValue= Max*intmax(class(Img));
            NucOverbright=NucTopHat>NucMaxValue;
            NucOpen(NucOverbright)=NucMaxValue;
                NucMed=median(NucOpen(NucOpen>1),'all');
                CytMed=median(Cyt(Cyt>1),'all');
                Ratio=uint16(NucMed)/uint16(CytMed);
                CytSub=Cyt.*Ratio.*Scaling;
            NucOpen=NucOpen-CytSub;
   
    %Otsu Thresholding
        NucMT1=multithresh(NucOpen,20); %Calculate 20 brightness thresholds for image 
        NucQuant1=imquantize(NucOpen,NucMT1); %Divide Image into the 20 brightness baskets
        NucBrightEnough=NucQuant1>Low;
        NucPos=NucBrightEnough;

    
    %Erode to separate close nuclei
        Nuc_bw1=imclose(NucPos, NucCloseDisk);
        Nuc_bw1=bwareaopen(Nuc_bw1, 250);
        Nuc_bw2=imerode(Nuc_bw1,NucErodeDisk);
        Nuc_bw2=imerode(Nuc_bw2,NucErodeDisk2);
        GaussNuc=imgaussfilt(NucOpen,8);
        GaussNuc(~Nuc_bw2)=0;

       D = -bwdist(~Nuc_bw2); %Make uplocal minima since Nuclei are pretty circular
       D_Min=imhmin(D,2);

    %Watershed Transform to find individual cells
       L=watershed(D_Min);
       L(~Nuc_bw1) = 0;
       L=bwlabel(L);
       
%        rgb=label2rgb(L);
       Nuc_bw4=imbinarize(L);
%         figure, 
%         imshow(rgb)
          
       Nuc_bw4_perim = imdilate(bwperim(Nuc_bw4),strel('disk',3));
       NucLabel=L;
       Data = {Max}; %Use for plotting overlay image
end

