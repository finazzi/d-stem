%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% D-STEM - Distributed Space Time Expecation Maximization      %
%                                                              %
% Author: Francesco Finazzi                                    %
% E-mail: francesco.finazzi@unibg.it                           %
% Affiliation: University of Bergamo - Dept. of Engineering    %
% Author website: http://www.unibg.it/pers/?francesco.finazzi  %
% Code website: https://code.google.com/p/d-stem/              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Data  building     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load the no2 ground level observations
load ../Demo/Data/no2_ground/no2_ground_background.mat
sd_g.Y{1}=no2_ground.data;
sd_g.Y_name{1}='no2 ground';
n1=size(sd_g.Y{1},1);
T=size(sd_g.Y{1},2);

%X_beta
%load the covariates for the NO2 monitoring stations
load ../Demo/Data/no2_ground/no2_ground_covariates.mat
sd_g.X_beta{1}=X;
sd_g.X_beta_name{1}={'wind speed','pressure','temperature','elevation','emission','population','saturday','sunday'};

X=ones(n1,1,1);
sd_g.X_z{1}=X;
sd_g.X_z_name{1}={'constant'};

x1_temp=sd_g.X_beta{1}(:,4,1);
x2_temp=sd_g.X_beta{1}(:,6,1);
X=cat(4,x1_temp,x2_temp);
sd_g.X_g{1}=X;
sd_g.X_g_name{1}={'elevation','population'};

%No downscaler
sd_g.X_rg=[];
sd_g.X_rg_name=[];

st_varset_g=stem_varset(sd_g.Y,sd_g.Y_name,sd_g.X_rg,sd_g.X_rg_name,sd_g.X_beta,sd_g.X_beta_name,sd_g.X_z,sd_g.X_z_name,sd_g.X_g,sd_g.X_g_name);

%coordinates
st_gridlist_g=stem_gridlist();
sd_g.coordinates=[no2_ground.lat,no2_ground.lon];
st_grid=stem_grid(sd_g.coordinates,'deg','sparse','point');
st_gridlist_g.add(st_grid);
clear no2_ground

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Model building     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

st_datestamp=stem_datestamp('01-01-2009','31-12-2009',T);

%stem_data object creation
st_data=stem_data(st_varset_g,st_gridlist_g,[],[],st_datestamp);
%stem_par object creation
st_par=stem_par(st_data,'exponential');
%stem_model object creation
st_model=stem_model(st_data,st_par);
clear sd_g

%Data transform
st_model.stem_data.log_transform;
st_model.stem_data.standardize;

%st_par object initialization
st_par.beta=st_model.get_beta0();
st_par.alpha_g=[0.6 0.6];
st_par.theta_g=[100 100]';
for i=1:length(st_par.alpha_g)
    v_g(:,:,i)=1;
end
st_par.v_g=v_g;
st_par.sigma_eta=0.2;
st_par.G=0.8;
st_par.sigma_eps=0.3;
 
st_model.set_initial_values(st_par);

%Model estimation
exit_toll=0.002;
max_iterations=100;
st_EM_options=stem_EM_options(exit_toll,max_iterations);
st_model.EM_estimate(st_EM_options);
st_model.set_varcov;
st_model.set_logL;

load ../Demo/Data/kriging/krig_elevation_005;
krig_coordinates=[krig_elevation.lat(:),krig_elevation.lon(:)];
krig_mask=krig_elevation.data_mask(:);
%kriging
st_krig=stem_krig(st_model);
st_krig_grid=stem_grid(krig_coordinates,'deg','regular','pixel',[80,170],'square',0.05,0.05);
back_transform=1;
no_varcov=0;
block_size=1000;
X_krig='../Demo/Data/kriging/blocks';
st_krig_result=st_krig.kriging('no2 ground',st_krig_grid,block_size,krig_mask,X_krig,back_transform,no_varcov);    

        