B={};
for tt=1:length(TPs)
celly=TPs{tt,end};
A=struct2cell(celly);
C={TPs{tt,1:end-1}};
D=repmat(C,size(A,2),1);
A=vertcat(D',A);
B=horzcat(B,A);
end