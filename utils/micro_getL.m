function [L,D]=micro_getL(S,normFlag)
    if nargin==1
       normFlag=1; 
    end
    n=size(S,1);
    D=diag(sparse(sum(S)));
    Dw = diag(sparse(sqrt(1 ./ (sum(S)+eps))));
    Dw(Dw==inf)=0;
    if normFlag==1
        L = eye(n) - Dw * S * Dw;
    else
        L=D-S;
    end

end