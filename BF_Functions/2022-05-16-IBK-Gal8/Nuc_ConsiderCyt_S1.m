function [Nuc_bw4,Nuc_bw4_perim,NucLabel,Data] = Nuc_ConsiderCyt(Img,AnaSettings,MiPerPix,Cyt)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            NucTophatDisk=strel('disk',round(50*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(4*(0.34/MiPerPix)));
            NucErodeDisk=strel('diamond',round(8*(0.34/MiPerPix)));
            NucErodeDisk2=strel('square',round(8*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(4*(0.34/MiPerPix)));    
    Low=AnaSettings{1};
    Max=AnaSettings{2};
    Scaling=AnaSettings{3};
    NucWeiner=wiener2(Img);
    NucTopHat=imtophat(NucWeiner,NucTophatDisk); % Clean image with tophat filter for thresholding 

%     NucOpen=imopen(NucTopHat,NucOpenDisk);
    NucOpen=NucTopHat;
    NucMaxValue= Max*intmax(class(Img));

    NucOverbright=NucTopHat>NucMaxValue;
    
    
    NucOpen(NucOverbright)=NucMaxValue;
            

    NucMed=median(NucOpen(NucOpen>1),'all');
    CytMed=median(Cyt(Cyt>1),'all');
        Ratio=double(NucMed)/double(CytMed);
        CytSub=Cyt.*Ratio.*Scaling;
        NucOpen=NucOpen-CytSub;
%         NucOpen=imopen(NucOpen,NucOpenDisk);
    
  
        NucMT1=multithresh(NucOpen,20); %Calculate 20 brightness thresholds for image 
        NucQuant1=imquantize(NucOpen,NucMT1); %Divide Image into the 20 brightness baskets
%             NucMT1=1;
%             NucQuant1=1;
            NucBrightEnough=NucQuant1>Low;
%             NucBrightEnough=NucOpen>Low;
        NucPos=NucBrightEnough;
%         NucPos(~NucBrightEnough)=0;
%         NucPos=imadjust(NucPos);
    

%             Nuc_bw1 = imclose(NucPos, NucCloseDisk);    
n=1
Nuc_bw1=imclose(NucPos, NucCloseDisk);
%  Nuc_bw1 = imfill(Nuc_bw1,'holes');
% for i=1:1:n           
    Nuc_bw2=imerode(Nuc_bw1,NucErodeDisk);
    Nuc_bw2=imerode(Nuc_bw1,NucErodeDisk2);
% %     Nuc_bw1 = imclose(Nuc_bw1, NucCloseDisk);
% end
% Nuc_bw1=imerode(NucPos,NucErodeDisk);
%             Nuc_bw1 = imclose(Nuc_bw1, NucCloseDisk);
%             Nuc_bw1=imerode(Nuc_bw1,NucErodeDisk2);
%             Nuc_bw1 = imclose(Nuc_bw1, NucCloseDisk);
% %             Nuc_bw1=imerode(Nuc_bw1,NucErodeDisk);
%              Nuc_bw1 = imclose(Nuc_bw1, NucCloseDisk);
% %              Nuc_bw1=imerode(Nuc_bw1,NucErodeDisk2);
%             Nuc_bw1 = bwareaopen(Nuc_bw1, 250); %%Be sure to check this threshold
%             Nuc_bw2 = imclose(Nuc_bw1, NucCloseDisk);
            
%             Nuc_bw3 = bwareaopen(Nuc_bw2, 50); %%Be sure to check this threshold
%             Nuc_bw4=Nuc_bw3;
%              Nuc_bw4 = imclose(Nuc_bw3, NucCloseDisk);
        Nuc_bw3=imclose(Nuc_bw2, NucCloseDisk);   
        Nuc_bw4 = imfill(Nuc_bw3,'holes');
%            [centers, radii, metric]=imfindcircles(Nuc_bw3,AnaSettings{5});
       D = -bwdist(~Nuc_bw4);
       L=watershed(D);
        L(~Nuc_bw1) = 0;
       rgb=label2rgb(L);
        figure, 
        imshow(rgb)
%         imshow(viscircles(centers, radii,'EdgeColor','b'))
          
        Nuc_bw4_perim = imdilate(bwperim(Nuc_bw4),strel('disk',3));
       
       NucConn=bwconncomp(Nuc_bw4);
       NucLabel = labelmatrix(NucConn);
%        NucArea = imoverlay(Nuc_eq, Nuc_bw4_perim, [.3 1 .3]);
       
Data = {Max};
end

