function [S] = micro_getAsymmetricGraph(Xs,U,Ys,YU,k)
%% Input
%%%     Xs                      The source samples with m * ns
%%%     Us                      The centroids with m * nu
%%%     Ys                      The source labels with ns * 1
%%%     Ys                      The micro-clusters labels with nu * 1
%%%     k                       The knn number
    C=length(unique(Ys));
    ns=size(Xs,2);
    l=size(U,2);
    S=zeros(ns,l);
    for c=1:C
        idx1=(Ys==c);
        idx2=(YU==c);
        pos1=find(idx1);
        pos2=find(idx2);
        nsc=length(find(idx1));
        Xsc=Xs(:,idx1);
        Usc=U(:,idx2);
        distP2D=EuDist2(Xsc',Usc');
        [d, idx] = sort(distP2D,2,'ascend');
        linkNum=min(k,length(find(idx2)));
        for i = 1:nsc
            idxa0 = idx(i,1:linkNum);
            realX=pos1(i);
            realY=pos2(idxa0);
            tmp1=1./(d(i,1:linkNum)+eps);
            tmp2=sum(tmp1);
            tmp=tmp1./tmp2;
            S(realX,realY)=tmp;
        end
    end
end

