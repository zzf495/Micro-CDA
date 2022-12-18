%% Title:  Micro-CDA: Micro-Clustering Domain Adaptation
%%% This manuscript has been submitted to IEEE/CAA Journal of Automatica
%%% Sinica for the consideration of publication
clc; clear all;
addpath(genpath('./utils/'));
path='./data/AWA2-DA/';
suffix='-resnet50-noft.mat';
domains1 = {'TC1','TC2','TN1','TN2'};
domains2 = {'TN2','TN1','TC1','TC2'};
result=[];
accIteration=[];
options=defaultOptions(struct(),...
                'T',10,...              % The number of iterations
                'dim',100,...           % The dimension reduced
                'alpha',0.5,...         % The weight of domain alignment (MMD)
                'beta',10,...           % The weight of manifold regularization w.r.t Ltt
                'gamma',5,...           % The weight of manifold regularization w.r.t Lxx
                'delta',5,...           % The weight of manifold regularization w.r.t Lsu and Luu
                'zeta',10,...           % The weight of manifold regularization w.r.t \hat{L}_{uu}
                'lambda',0.01,...       % The weight of regularization term
                'k',3,...               % The number of neighbor number w.r.t Eqs. (22) and (23)
                'nu',0.1,...            % The number of intra-class micro-clusters
                'ktt',5,...             % The neighbor number of Xt w.r.t Eq. (3), it is fixed as 5 in all the experiments
                'mu',0.5);              % The relative importance of marginal and conditional distributions
optsPCA.ReducedDim=512;                 % The dimension reduced before training
for i = 1:4
    %% Load data
    src = [path domains1{i} suffix];
    tgt = [path domains2{i} suffix];
    fprintf('%d: %s_vs_%s\n',i,domains1{i},domains2{i});
    load(src);
    %%% Load Xs
    feas = resnet50_features;
    feas = feas ./ repmat(sum(feas,2),1,size(feas,2));
    Xs= double(normr(feas))';
    Ys = double(labels'+1);
    %%% Load Xt
    load(tgt);
    feas = resnet50_features;
    feas = feas ./ repmat(sum(feas,2),1,size(feas,2));
    Xt=double(normr(feas))';
    Yt = double(labels'+1);
    %% Run PCA to reduce the dimensionality
    domainS_features_ori=Xs';domainT_features=Xt';
    X = double([domainS_features_ori;domainT_features]);
    P_pca = PCA(X,optsPCA);
    domainS_features = domainS_features_ori*P_pca;
    domainT_features = domainT_features*P_pca;
    %% Run KTL-DDS
    [acc,acc_ite]=Micro_CDA(Xs,Ys,Xt,Yt,options);
    accIteration=[accIteration;acc_ite];
    result(i)=acc;
end
fprintf('Mean accuracy: %.4f\n',mean(result));
