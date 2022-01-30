Area=squeeze(Data(:,:,1,:));
Tomato=squeeze(Data(:,:,2,:));
TooLow=~(Tomato>0.1);
Area2=Area;
Tomato2=Tomato;
Area2(TooLow) =[NaN];
Tomato2(TooLow)=[NaN];
% 
TotArea=sum(Area2,'omitnan');
AvTomato=(Tomato2);
figure, plot3(1:384,Area2,Tomato2,'o')
grid on
% % Area=sum(squeeze(Data(:,:,1,:)),'omitnan');
% % AvTomato=mean(squeeze(Data(:,:,2,:)),'omitnan');
% figure, plot3(1:384,Area,AvTomato,'o')
% grid on