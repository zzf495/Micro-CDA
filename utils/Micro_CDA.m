function [acc,acc_ite,W] = Micro_CDA(Xs,Ys,Xt,Yt,options)
%% Title:  Micro-CDA: Micro-Clustering Domain Adaptation
%%% This manuscript has been submitted to IEEE/CAA Journal of Automatica
%%% Sinica for the consideration of publication
%% Input
%%%
%%%     T                   The number of iterations
%%%
%%%     dim                 The dimension reduced
%%%
%%%     alpha               The weight of domain alignment (MMD)
%%%
%%%     beta                The weight of manifold regularization w.r.t Ltt
%%%
%%%     gamma               The weight of manifold regularization w.r.t Lxx
%%%
%%%     delta               The weight of manifold regularization w.r.t Lsu and Luu
%%%
%%%     zeta                The weight of manifold regularization w.r.t \hat{L}_{uu}
%%%
%%%     lambda              The weight of regularization term
%%%
%%%     k                   The number of neighbor number w.r.t Eqs. (22) and (23)
%%%
%%%     nu                  The number of intra-class micro-clusters
%%%
%%%     ktt                 The neighbor number of Xt w.r.t Eq. (3)
%%%                         it is fixed as 5 in all the experiments
%%%
%%%      mu                 The relative importance of marginal and conditional distributions
%% Output
%%%
%%%      acc                The classification accuracy (number,0~1)
%%%
%%%      acc_ite            The classification accuracy in each iteration (list)
%%%
%%%      W                  The projection matrix
%%%
    %% set parameters if NULL
    options=defaultOptions(options,...
                'T',10,...              % The number of iterations
                'dim',30,...            % The dimension reduced
                'alpha',5,...           % The weight of domain alignment (MMD)
                'beta',1,...            % The weight of manifold regularization w.r.t Ltt
                'gamma',1,...           % The weight of manifold regularization w.r.t Lxx
                'delta',0.1,...         % The weight of manifold regularization w.r.t Lsu and Luu
                'zeta',0.1,...          % The weight of manifold regularization w.r.t \hat{L}_{uu}
                'lambda',0.1,...        % The weight of regularization term
                'k',10,...               % The number of neighbor number w.r.t Eqs. (22) and (23)
                'nu',0.1,...              % The number of intra-class micro-clusters
                'ktt',5,...              % The neighbor number of Xt w.r.t Eq. (3), it is fixed as 5 in all the experiments
                'mu',0.1);             % The relative importance of marginal and conditional distributions
    %% init parameters
    cmd='';
    T=options.T;
    dim=options.dim;
    alpha=options.alpha;
    beta=options.beta;
    gamma=options.gamma;
    delta=options.delta;
    zeta=options.zeta;
    lambda=options.lambda;
    k=options.k;
    nu=options.nu;
    mu=options.mu;
%     -------------------------------
    Xs=normr(Xs')';
    Xt=normr(Xt')';
    acc=0;
    acc_ite=[];
    %% Init
    X=[Xs,Xt];
    X=normr(X')';
    [m,ns]=size(Xs);
    nt=size(Xt,2);
    n=ns+nt;
    C=length(unique(Ys));
    M0 = marginalDistribution(Xs,Xt,C);
    U=[];
    YU=[];
    mapping=[];
    H=centeringMatrix(n);
    XHX=X*H*X';
    % Init Us
    U=[];
    YU=[];
    WG=eye(m);
    manifold.k = options.ktt;
    manifold.Metric = 'Cosine';
    manifold.WeightMode = 'Cosine';
    manifold.NeighborMode = 'KNN';
    % Init Lt
    [Ltt,~,~]=computeL(Xt,manifold);
    Ltt=Ltt./norm(Ltt,'fro');
    XtLttXt=Xt*Ltt*Xt';
    % Init Us
    for i=1:C
        idx=Ys==i;
        Xsc=Xs(:,idx);
        if 0<nu&&nu<1
            selectNum=floor(length(find(idx))*nu)+1;
        else
            selectNum=min(nu,length(find(idx)));
        end
        % Use Kmeans to initialize U
        [~, center] = litekmeans(Xsc', selectNum);
        for j=1:selectNum
            mapping=[mapping; i];
        end
        U=[U,center'];
        YU=[YU;i*ones(selectNum,1)];
    end
    nu=size(U,2);
    % Correct U by IMcro-CL
    [U,S_su]=IMcro_CL(Xs,Ys,U,YU,options);
    % Initialize marginal matrix by Eq. (14)
    M=M0./norm(M0,'fro');
    % Init projection matrix W
    XstUs=[Xs,U];
    S_sumOf_su=[zeros(ns,ns),S_su;S_su',zeros(nu,nu)];
    Lsu=micro_getL(S_sumOf_su);
    Lsu=Lsu./norm(Lsu,'fro');
    [Ss,Sb,Ls,Lb,~,~] = micro_getLapgraph(U,YU,1);
    Ls=Ls./norm(Ls,'fro');
    Lb=Lb./norm(Lb,'fro');
    left=alpha*X*M*X'+beta*XtLttXt+delta*XstUs*Lsu*XstUs'+delta*U*Ls*U'+lambda*eye(m);
    right=XHX+zeta*U*(Lb)*U';
    [W,~]=eigs(left,right,dim,'sm');
    W=real(W);
    WX=W'*[X,U];
    WX=L2Norm(WX')';
    WXs=WX(:,1:ns);
    WXt=WX(:,ns+1:n);
    WU=WX(:,n+1:end);
    % Init pseudo-labels
    realYtpseudo=classifySVM([WXs,WU],[Ys;YU],WXt);
    fprintf('[init] acc:%.4f \n',getAcc(realYtpseudo,Yt)*100);
    for i=1:T
        % Update S_{s->u} by Eq.(22)
        [S_su] = micro_getAsymmetricGraph(WXs,WU,Ys,YU,k);
         % Update Us by Eq.(27)
        if i==1
           S1=S_su./(sum(S_su,1)+eps);
           U=Xs*S1;
        else
            sumOf=2*delta+zeta;
            par1=delta/sumOf; % Xs * S
            par3=delta/sumOf;  % Us * G_+
            par4=zeta/sumOf; % Us * G_-
            S1=S_su./(sum(S_su,1)+eps);
            S3=Ss./(sum(Ss,1)+eps);
            S4=Sb./(sum(Sb,1)+eps);
            U=par1*Xs*S1+U*(par3*S3-par4*S4);
        end
        % Update S_{t->u} by Eq.(23)
        [S_tu] = micro_getAsymmetricGraph(WXt,WU,ones(nt,1),ones(nu,1),k);
         % Update Ls and Lb w.r.t U and \hat{U} by Eqs. (24) and (25)
        [Ss,Sb,Ls,Lb,~,~] = micro_getLapgraph(W'*U,YU,1);
        Ls=Ls./norm(Ls,'fro');
        Lb=Lb./norm(Lb,'fro');
        % Update conditional matrix by Eq.(15)
        Mc= conditionalDistribution(Xs,Xt,Ys,realYtpseudo,C);
        M=(1-mu)*M0+mu*(Mc);
        M=M./norm(M,'fro');
        % Update projection matrix W by Eq.(28)
        XstUs=[Xs,U];
        S_sumOf_su=[zeros(ns,ns),S_su;S_su',zeros(nu,nu)];
        Lsu=micro_getL(S_sumOf_su);
        Lsu=Lsu./norm(Lsu,'fro');
        S_st=[S_su;S_tu];
        S_st=S_st*S_st';
        Lst=micro_getL(S_st);
        Lst=Lst./norm(Lst,'fro');
        left=X*(alpha*M+gamma*Lst)*X'+delta*XstUs*Lsu*XstUs'+delta*U*Ls*U'...
                +beta*(XtLttXt)+lambda*eye(m); 
        right=XHX+zeta*U*(Lb)*U';
        [W,~]=eigs(left,right,dim,'sm');
        % Classification
        W=real(W);
        WX=W'*[X,U];
        WX=L2Norm(WX')';
        WXs=WX(:,1:ns);
        WXt=WX(:,ns+1:ns+nt);
        WU=WX(:,n+1:end);
        realYtpseudo=classifySVM([WXs,WU],[Ys;YU],WXt,cmd);
        %% Acc
        acc=getAcc(realYtpseudo,Yt);
        acc_ite(i)=acc;
        fprintf('[%2d] acc:%.4f \n',i,acc*100);
    end
end