function [S_same,S_diff,Ls,Ld,Ds,Dd] = micro_getLapgraph(Us,YUs,k)
       n=size(Us,2);
       S_same=zeros(n,n);
       S_diff=zeros(n,n);
       dist= EuDist2(Us',Us');
       [sortDist,idx]=sort(dist,2,'ascend');
       if k<=0
          k=65536;
       end
       for i=1:n
           %% same
           Ytmp=YUs(idx(i,:));
           idx_same= find(Ytmp==YUs(i));
           if 0<k&&k<1
              realNum=min(length(idx_same),max(floor(k*length(idx_same))+1,1));
           else
              realNum=min(length(idx_same),k+1);
           end
           realIdx=idx(i,idx_same(2:realNum));
           tmp1=1./(sortDist(i,2:realNum)+eps);
           tmp2=sum(tmp1);
           tmp=tmp1./tmp2;
           S_same(i,realIdx)=tmp;
           %% diff
           idx_diff= find(Ytmp~=YUs(i));
           if 0<k&&k<1
              realNum=min(length(idx_diff),max(floor(k*length(idx_diff))+1,1));
           else
              realNum=min(length(idx_diff),k+1);
           end
           realIdx=idx(i,idx_diff(2:realNum));
           tmp1=1./(sortDist(i,2:realNum)+eps);
           tmp2=sum(tmp1);
           tmp=tmp1./tmp2;
           S_diff(i,realIdx)=tmp;
       end
       S_same=(S_same+S_same')/2;
       S_diff=(S_diff+S_diff')/2;
       [Ls,Ds]=micro_getL(S_same);
       [Ld,Dd]=micro_getL(S_diff);
end
