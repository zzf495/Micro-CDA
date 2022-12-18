function [U,S]=IMcro_CL(Xs,Ys,Us,YUs,options)
    %% Parameter setting
    T=1e2;%options.T;
    delta=options.delta;
    zeta=options.zeta;
    k=options.k;
    epsilon=1e-4;
    %% Initialization
    nu=size(Us,2);
    U=Us;
    objVal=[];
    [Ss,Sb,~,~,~,~] = micro_getLapgraph(Us,YUs,1);
    S3=Ss./(sum(Ss,1)+eps);
    S4=Sb./(sum(Sb,1)+eps);
    for i=1:T
        S = micro_getAsymmetricGraph(Xs,Us,Ys,YUs,k);
         %% Update Us
        sumOf=2*delta+zeta;
        par1=delta/sumOf; % Xs * S
        par3=delta/sumOf;  % Us * G_+
        par4=zeta/sumOf; % Us * G_-
        S1=S./(sum(S,1)+eps);
        Us=par1*Xs*S1+Us*(par3*S3-par4*S4);
        % Calculate obj
        [~,Ypseudo]=max(S,[],2);
        hotY=hotmatrix(Ypseudo,nu,1);
        objVal(i)=norm(Xs*hotY-Us,'fro');
        if i>=3
           if abs(objVal(i)-objVal(i-1))<=epsilon&& abs(objVal(i-2)-objVal(i-1))<=epsilon
               fprintf('Converge at %d-th iteration with obj value:%.6f\n',i,objVal(i));
               return ;
           end
        end
    end
%     fprintf('Not converge at %d-th iteration\n',T);
end

