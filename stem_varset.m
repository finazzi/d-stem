%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% D-STEM - Distributed Space Time Expecation Maximization              %
%%%                                                                      %
%%% Author: Francesco Finazzi                                            %
%%% E-mail: francesco.finazzi@unibg.it                                   %
%%% Affiliation: University of Bergamo                                   %
%%%              Dept. of Management, Economics and Quantitative Methods %
%%% Author website: http://www.unibg.it/pers/?francesco.finazzi          %
%%% Code website: https://code.google.com/p/d-stem/                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This file is part of D-STEM.
% 
% D-STEM is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 2 of the License, or
% (at your option) any later version.
% 
% D-STEM is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with D-STEM. If not, see <http://www.gnu.org/licenses/>.

classdef stem_varset < handle
    
    %CONSTANTS
    %ni   - the number of sites for the i-th variable, i=1,...,q
    %ni_b - the number of loading vectors for the i-th variable related to the beta parameter
    %ni_t - the number of loading vectors for the i-th variable related to the latent variable z
    %K    - the number of loading vectors related to the latent variable w_p
    %N    - n1+...+nq total number of observation sites for all the variables
    %T - number of temporal steps
    %TT = T if the space-time varying coefficients are time-variant and TT=1 if they are time-invariant
    %p - dimension of the latent temporal variable z    
    
    properties
        Y={};               %[double]   {qx1}(nixT)         observed data 
        X_bp={};            %[double]   {qx1}(nix1xTT)      loading vectors related to the latent variable w_b 
        X_beta={};          %[double]   {qx1}(nixni_bxTT)   loading vectors related to the beta parameter
        X_z={};             %[double]   {qx1}(nixni_txTT)   loading vectors related to the latent variable z
        X_p={};             %[double]   {qx1}(nix1xTTxK)    loading vectors related to the latent variable w_p
        Y_name={};          %[string]   {qx1}               variable names
        X_bp_name={};       %[string]   {qx1}               name of the loading vectors related to the latent variable w_b
        X_beta_name={};     %[string]   {qxni_b}            name of the loading vectors related to the beta parameter
        X_z_name={};        %[string]   {qxni_t}            name of the loading vectors related to the latent variable z
        X_p_name={};        %[string]   {Kx1}               name of the loading vectors related to the latent variable w_p
        simulated=0;        %[boolean]  (1x1)               1: the Y data are simulated; 0: the Y data are observed data
    end
    
    properties (SetAccess=private)
        N=[];                   %[integer >0]      (1x1) n1+...+nq
        T=[];                   %[integer >0]      (1x1) total number of time steps
        nvar=[];                %[integer >0]      (1x1) total number of variables (q)
        dim=[];                 %[integer]         (qx1) number of time series for each variable

        standardized=0;         %[boolean]         (1x1) 1: Y, X_bp, X_beta, X_z and X_p has been standardized; 0: otherwise
        log_transformed=0;      %[boolean]         (1x1) 1: Y has been log-transformed using the method log_transform; 0: otherwise
        X_bp_tv=1;              %[boolean]         (1x1) 1: the loading vectors related to the latent variable w_b are time variant; 0:otherwise
        X_beta_tv=1;            %[boolean]         (1x1) 1: the loading vectors related to the beta parameter are time variant; 0:otherwise
        X_z_tv=1;               %[boolean]         (1x1) 1: the loading vectors related to the latent variable z are time variant; 0:otherwise
        X_p_tv=1;               %[boolean]         (1x1) 1: the loading vectors related to the latent variable w_p are time variant; 0:otherwise
        
        Y_means={};             %[double]          {qx1} averages of the non-standardized Y
        Y_stds={};              %[double]          {qx1} standard deviations of the non-standardized Y
        X_bp_means={};          %[double]          {qx1} averages of the non-standardized X_bp
        X_bp_stds={};           %[double]          {qx1} standard deviations of the non-standardized X_bp
        X_beta_means={};        %[double]          {qx1}(ni_bx1) averages of the non-standardized X_beta
        X_beta_stds={};         %[double]          {qx1}(ni_bx1) standard deviations of the non-standardized X_beta
        X_z_means={};           %[double]          {qx1}(ni_tx1) averages of the non-standardized X_z
        X_z_stds={};            %[double]          {qx1}(ni_tx1) standard deviations of the non-standardized X_z
        X_p_means={};           %[double]          (qxK) averages of the non-standardized X_p
        X_p_stds={};            %[double]          {qx1}(ni_tx1) standard deviations of the non-standardized X_p
    end
    
    methods
        function obj = stem_varset(Y,Y_name,X_bp,X_bp_name,X_beta,X_beta_name,X_z,X_z_name,X_p,X_p_name)
            %DESCRIPTION: is the constructor of the class stem_varset
            %
            %INPUT
            %            
            %Y               -  [double]   {qx1}(nixT)         observed data
            %Y_name          -  [string]   {qx1}               variable names
            %X_bp            -  [double]   {qx1}(nix1xTT)      loading vectors related to the latent variable w_b
            %X_bp_name       -  [string]   {qx1}               name of the loading vectors related to the latent variable w_b
            %X_beta          -  [double]   {qx1}(nixni_bxTT)   loading vectors related to the beta parameter
            %X_beta_name     -  [string]   {qxni_b}            name of the loading vectors related to the beta parameter
            %X_z             -  [double]   {qx1}(nixni_txTT)   loading vectors related to the latent variable z
            %X_z_name        -  [string]   {qxni_t}            name of the loading vectors related to the latent variable z
            %X_p             -  [double]   {qx1}(nix1xTTxK)    loading vectors related to the latent variable w_p
            %X_p_name        -  [string]   {qxK}               name of the loading vectors related to the latent variable w_p
            %
            %OUTPUT
            %obj             - [stem_varset object] (1x1) the stem_varset object
            
            if not(mod(nargin,2)==0)
                error('Not enough input arguments');
            end
            obj.Y=Y;
            obj.Y_name=Y_name;

            if nargin>=4
                if not(isempty(X_bp))
                    obj.X_bp=X_bp;
                    obj.X_bp_name=X_bp_name;
                end
            end
            if nargin>=6
                if not(isempty(X_beta))
                    obj.X_beta=X_beta;
                    obj.X_beta_name=X_beta_name;
                end
            end
            if nargin>=8
                if not(isempty(X_z))
                    obj.X_z=X_z;
                    obj.X_z_name=X_z_name;
                end
            end      
            if nargin>=10
                if not(isempty(X_p))
                    obj.X_p=X_p;
                    obj.X_p_name=X_p_name;
                end
            end              
        end

        function log_transform(obj)
            %DESCRIPTION: log-transforms the matrix Y
            %
            %INPUT
            %obj - [stem_varset object] (1x1) the stem_varset object
            %
            %OUTPUT
            %
            %none: the matrix Y is updated              

            for i=1:length(obj.Y)
                temp=obj.Y{i};
                num1=sum(temp(:)<0);
                if num1>0
                    disp([num2str(num1),' negative value(s) are considered as zero']);
                    temp(temp(:)<0)=0;
                end
                num2=sum(temp(:)==0);
                if num2>0
                    disp([num2str(num2),' value(s) equal to zero are transformed to 0.05']);
                    temp(temp(:)==0)=0.05;
                end
                temp=log(temp);
                obj.Y{i}=temp;
            end
            obj.log_transformed=1;
        end
        
        function detrend_Y(obj)
            %DESCRIPTION: remove the mean from each time series in Y
            %
            %INPUT
            %obj - [stem_varset object] (1x1) the stem_varset object
            %
            %OUTPUT
            %
            %none: the Y property is updated            
            for i=1:length(obj.Y)
                for j=1:size(obj.Y{i},1)
                    m1=nanmean(obj.Y{i}(j,:));
                    obj.Y{i}(j,:)=(obj.Y{i}(j,:)-m1);
                end
            end                    
        end
        
        function standardize_Y(obj)
            %DESCRIPTION: each time series in Y is standardized
            %
            %INPUT
            %obj - [stem_varset object] (1x1) the stem_varset object
            %
            %OUTPUT
            %
            %none: the Y property is updated        
            
            for i=1:length(obj.Y)
                m1=nanmean(obj.Y{i},2);
                std1=nanstd(obj.Y{i},1,2);
                for j=1:size(obj.Y{i},2)
                    obj.Y{i}(:,j)=(obj.Y{i}(:,j)-m1)./std1;
                end
            end                
        end
        
        function standardize(obj)
            %DESCRIPTION: standardize the matrices Y, X_bp, X_beta, X_z and X_p with respect to their overall mean and overall standard deviation
            %
            %INPUT
            %obj - [stem_varset object] (1x1) the stem_varset object
            %
            %OUTPUT
            %
            %none: the matrices listed above are updated
            
            for i=1:length(obj.Y)
                m1=nanmean(obj.Y{i}(:));
                std1=nanstd(obj.Y{i}(:));
                obj.Y{i}=(obj.Y{i}-m1)/std1;
                obj.Y_means{i}=m1;
                obj.Y_stds{i}=std1;
            end
            for i=1:length(obj.X_bp)
                m1=mean(obj.X_bp{i}(:));
                std1=std(obj.X_bp{i}(:));
                if std1==0
                    m1=0;
                    std1=1;
                end
                obj.X_bp{i}=(obj.X_bp{i}-m1)/std1;
                obj.X_bp_means{i}=m1;
                obj.X_bp_stds{i}=std1;                
            end
            for i=1:length(obj.X_beta)
                for j=1:size(obj.X_beta{i},2)
                    temp=squeeze(obj.X_beta{i}(:,j,:));
                    m1=mean(temp(:));
                    std1=std(temp(:));
                    if std1==0
                        m1=0;
                        std1=1;
                    end
                    obj.X_beta{i}(:,j,:)=(obj.X_beta{i}(:,j,:)-m1)/std1;
                    obj.X_beta_means{i}(j)=m1;
                    obj.X_beta_stds{i}(j)=std1;
                end
            end      
            
            for i=1:length(obj.X_z)
                for j=1:size(obj.X_z{i},2)
                    temp=squeeze(obj.X_z{i}(:,j,:));
                    m1=mean(temp(:));
                    std1=std(temp(:));
                    if std1==0
                        m1=0;
                        std1=1;
                    end
                    obj.X_z{i}(:,j,:)=(obj.X_z{i}(:,j,:)-m1)/std1;
                    obj.X_z_means{i}(j)=m1;
                    obj.X_z_stds{i}(j)=std1;
                end
            end      
            
            for i=1:length(obj.X_p)
                for j=1:size(obj.X_p{i},4)
                    temp=squeeze(obj.X_p{i}(:,:,:,j));
                    m1=mean(temp(:));
                    std1=std(temp(:));
                    if std1==0
                        m1=0;
                        std1=1;
                    end
                    obj.X_p{i}(:,:,:,j)=(obj.X_p{i}(:,:,:,j)-m1)/std1;
                    obj.X_p_means{i}(j)=m1;
                    obj.X_p_stds{i}(j)=std1;
                end
            end               
            obj.standardized=1;
        end
        
        function index = get_Y_index(obj,name)
            %DESCRIPTION: returns the index of the variable given its name
            %
            %INPUT
            %obj    - [stem_varset object]  (1x1) the stem_varset object
            %name   - [string]              (1x1) the name of the variable
            %
            %OUTPUT
            %
            %none: the index of the requested variable     
            
            index=find(strcmp(obj.Y_name,name));
        end
        
        function index = get_X_beta_index(obj,name,variable_idx)
            %DESCRIPTION: returns the index of the variable given its name
            %
            %INPUT
            %obj          - [stem_varset object]  (1x1) the stem_varset object
            %name         - [string]              (1x1) the name of the variable
            %variable_idx - [string]              (1x1) the index of the variable
            %
            %OUTPUT
            %
            %none: the index of the requested loading coefficient     
            if not(isempty(obj.X_beta_name))
                index=find(strcmp(obj.X_beta_name{variable_idx},name));
            else
                index=[];
            end
        end   
        
        function index = get_X_z_index(obj,name,variable_idx)
            %DESCRIPTION: returns the index of the variable given its name
            %
            %INPUT
            %obj          - [stem_varset object]  (1x1) the stem_varset object
            %name         - [string]              (1x1) the name of the variable
            %variable_idx - [string]              (1x1) the index of the variable
            %
            %OUTPUT
            %
            %none: the index of the requested loading coefficient    
            if not(isempty(obj.X_z_name))
                index=find(strcmp(obj.X_z_name{variable_idx},name));
            else
                index=[];
            end
        end        
        
        function index = get_X_p_index(obj,name,variable_idx)
            %DESCRIPTION: returns the index of the variable given its name
            %
            %INPUT
            %obj          - [stem_varset object]  (1x1) the stem_varset object
            %name         - [string]              (1x1) the name of the variable
            %variable_idx - [string]              (1x1) the index of the variable
            %
            %OUTPUT
            %
            %none: the index of the requested loading coefficient    
            if not(isempty(obj.X_p_name))
                index=find(strcmp(obj.X_p_name{variable_idx},name));
            else
                index=[];
            end
        end    
        
        function index = get_X_bp_index(obj,name,variable_idx)
            %DESCRIPTION: returns the index of the variable given its name
            %
            %INPUT
            %obj          - [stem_varset object]  (1x1) the stem_varset object
            %name         - [string]              (1x1) the name of the variable
            %variable_idx - [string]              (1x1) the index of the variable
            %
            %OUTPUT
            %
            %none: the index of the requested loading coefficient    
            if not(isempty(X_bp_name))
                index=find(strcmp(obj.X_bp_name{variable_idx},name));
            else
                index=[];
            end
        end         

        %Class set methods
        function set.Y(obj,Y)
            if not(iscell(Y))
                error('Y must be a cell array');
            end
            for i=1:length(Y)
                if not(size(Y{i},2)==size(Y{1},2))
                    error('Each Y{i} must have the same number of temporal steps');
                end
                obj.dim(i)=size(Y{i},1);
            end
            obj.T=size(Y{1},2);
            obj.N=sum(obj.dim);
            obj.nvar=length(obj.dim);
            obj.Y=Y;
        end

        function set.Y_name(obj,Y_name)
            if not(iscell(Y_name))
                error('Y_name must be a cell array');
            end
            if not(length(Y_name)==length(obj.Y))
                error('The length of Y_name must be equal to length of Y');
            end
            obj.Y_name=Y_name;
        end
        
        function set.X_bp(obj,X_bp)
            if not(iscell(X_bp))
                error('X_bp must be a cell array');
            end
            if not(length(X_bp)==length(obj.Y))
                error('The number of cells of X_bp must be equal to the number of cells of Y');
            end
            for i=1:length(X_bp)
                if not(size(X_bp{i},1)==size(obj.Y{i},1))
                    error('X_bp{i} must have the same number of rows of Y{i}');
                end
                if not(size(X_bp{i},2)==1)
                    error('Each X_bp{i} must be a single covariate');
                end
                if not(size(X_bp{i},3)==obj.T || size(X_bp{i},3)==1)
                    error('Each X_bp{i} must have either 1 or T time steps');
                end
                if not(size(X_bp{1},3)==size(X_bp{i},3))
                    error('All the X_bp{i} must have the same temporal dimension');
                end
                if sum(isnan(X_bp{i}(:)))>0
                    error('X_bp cannot contain NaN');
                end
            end
            if size(X_bp{i},3)==1
                obj.X_bp_tv=0;
            end
            obj.X_bp=X_bp;
        end  
        
        function set.X_bp_name(obj,X_bp_name)
            if not(iscell(X_bp_name))
                error('X_bp_name must be a cell array');
            end
            if not(length(X_bp_name)==length(obj.X_bp))
                error('The length of X_bp_name must be equal to length of X_bp');
            end
            obj.X_bp_name=X_bp_name;
        end      
        
        function set.X_beta(obj,X_beta)
            if not(iscell(X_beta))
                error('X_beta must be a cell array');
            end
            if not(length(X_beta)==length(obj.Y))
                error('The number of cells of X_beta must be equal to the number of cells of Y');
            end
            for i=1:length(X_beta)
                if not(size(X_beta{i},1)==size(obj.Y{i},1))
                    error('X_beta{i} must have the same number of rows of Y{i}');
                end
                if not(size(X_beta{i},3)==obj.T || size(X_beta{i},3)==1)
                    error('Each X_beta{i} must have either 1 or T time steps');
                end
                if not(size(X_beta{1},3)==size(X_beta{i},3))
                    error('All the X_beta{i} must have the same temporal dimension');
                end
                if sum(isnan(X_beta{i}(:)))>0
                    error('X_beta cannot contain NaN');
                end                
            end
            if size(X_beta{1},3)==1
                obj.X_beta_tv=0;
            end
            obj.X_beta=X_beta;
        end  
        
        function set.X_beta_name(obj,X_beta_name)
            if not(iscell(X_beta_name))
                error('X_beta_name must be a cell array');
            end
            if not(length(X_beta_name)==length(obj.X_beta))
                error('The length of X_beta_name must be equal to length of X_beta');
            end
            for i=1:length(X_beta_name)
                if not(length(X_beta_name{i})==size(obj.X_beta{i},2))
                    error('The length of X_beta_name{i} must be equal to the number of covariates of X_beta{i}');
                end
            end
            obj.X_beta_name=X_beta_name;
        end      
        
        function set.X_z(obj,X_z)
            if not(iscell(X_z))
                error('X_z must be a cell array');
            end
            if not(length(X_z)==length(obj.Y))
                error('The number of cells of X_z must be equal to the number of cells of Y');
            end
            for i=1:length(X_z)
                if not(size(X_z{i},1)==size(obj.Y{i},1))
                    error('X_z{i} must have the same number of rows of Y{i}');
                end
                if not(size(X_z{i},3)==obj.T || size(X_z{i},3)==1)
                    error('Each X_z{i} must have either 1 or T time steps');
                end
                if not(size(X_z{i},3)==size(X_z{1},3))
                    error('All the X_z{i} must have the same temporal dimension');
                end
                if sum(isnan(X_z{i}(:)))>0
                    error('X_z cannot contain NaN');
                end                
            end
            if size(X_z{1},3)==1
                obj.X_z_tv=0;
            end
            obj.X_z=X_z;
        end  
        
        function set.X_z_name(obj,X_z_name)
            if not(iscell(X_z_name))
                error('X_z_name must be a cell array');
            end
            if not(length(X_z_name)==length(obj.X_z))
                error('The length of X_z_name must be equal to length of X_z');
            end
            for i=1:length(X_z_name)
                if not(length(X_z_name{i})==size(obj.X_z{i},2))
                    error('The length of X_z_name{i} must be equal to the number of covariates of X_z{i}');
                end
            end            
            obj.X_z_name=X_z_name;
        end      
        
        function set.X_p(obj,X_p)
            if not(iscell(X_p))
                error('X_p must be a cell array');
            end
            if not(length(X_p)==length(obj.Y))
                error('The number of cells of X_p must be equal to the number of cells of Y');
            end
            for i=1:length(X_p)
                if not(size(X_p{i},1)==size(obj.Y{i},1))
                    error('X_p{i} must have the same number of rows of Y{i}');
                end
                if not(size(X_p{i},2)==size(X_p{1},2))
                    error('Each X_p{i} must have the same number of covariates');
                end
                if not(size(X_p{i},3)==obj.T || size(X_p{i},3)==1)
                    error('Each X_p{i} must have either 1 or T time steps');
                end
                if not(size(X_p{i},3)==size(X_p{1},3))
                    error('All the X_p{i} must have the same temporal dimension');
                end
                if not(size(X_p{i},4)==size(X_p{1},4))
                    error('Each X_p{i} must have equal 4th dimension');
                end
                if sum(isnan(X_p{i}(:)))>0
                    error('X_p cannot contain NaN');
                end                
            end
            if size(X_p{1},3)==1
                obj.X_p_tv=0;
            end
            obj.X_p=X_p;
        end  
        
        function set.X_p_name(obj,X_p_name)
            if not(iscell(X_p_name))
                error('X_p_name must be a cell array');
            end
            if not(length(X_p_name)==length(obj.X_p))
                error('The length of X_p_name must be equal to length of X_p');
            end
            for i=1:length(X_p_name)
                if not(length(X_p_name{i})==size(obj.X_p{i},4))
                    error('The length of X_p_name{i} must be equal to k');
                end
            end
            obj.X_p_name=X_p_name;
        end           
        
    end
end