%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% D-STEM - Distributed Space Time Expecation Maximization              %
%%%                                                                      %
%%% Author: Francesco Finazzi                                            %
%%% E-mail: francesco.finazzi@unibg.it                                   %
%%% Affiliation: University of Bergamo                                   %
%%%              Dept. of Management, Economics and Quantitative Methods %
%%% Author website: http://www.unibg.it/pers/?francesco.finazzi          %
%%% Author: Yaqiong Wang                                                 %
%%% E-mail: yaqiongwang@pku.edu.cn                                       %
%%% Affiliation: Peking University,                                      %
%%%              Guanghua school of management,                          %
%%%              Business Statistics and Econometrics                    %
%%% Code website: https://github.com/graspa-group/d-stem                 %
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

classdef stem_fda
   
    properties (SetAccess=private)
        
        spline_type=[]      %[string]      (1x1) the type of basis, 'Bspline' or 'Fourier'
        spline_range=[];    %[double]       (2x1) the range of the spline
        
        spline_nbasis =[]       %-[integer >0] (1x1) the number of basis spline
        spline_nbasis_beta =[]  %-[integer >0] (1x1) the number of basis spline for beta
        spline_nbasis_sigma =[] %-[integer >0] (1x1) the number of basis spline for sigma_eps
            
        spline_order=[];    %[integer >0]   (1x1) the order of the spline
        spline_knots=[];    %[double]       (sx1) the spline knots
        spline_basis=[];    %[basis obj]    (1x1) the spline basis 
        spline_order_beta=[];    %[integer >0]   (1x1) the order of the spline for Beta
        spline_knots_beta=[];    %[double]       (sx1) the spline knots for Beta
        spline_basis_beta=[];    %[basis obj]    (1x1) the spline basis for Beta
        spline_order_sigma=[];    %[integer >0]   (1x1) the order of the spline for Sigma
        spline_knots_sigma=[];    %[double]       (sx1) the spline knots for Sigma
        spline_basis_sigma=[];    %[basis obj]    (1x1) the spline basis for Sigma
        flag_beta_spline = 0;   %[interger] (1x1) the indicator of Beta(h)
        flag_sigma_eps_spline = 0;   %[interger] (1x1) the indicator of Sigma(h)
        flag_logsigma = 1;    %[interger] (1x1) the indicator of is on logsigma or not, with 1 indicating using the log and temporally used by ourselves
        flag_sqrsigma = 0;   %[interger] (1x1) the indicator of is on sqrtsigma or not, with 1 indicating using the sqrt and temporally used by ourselves
    end
    
    methods
        
        function obj = stem_fda(obj_fda)
            %DESCRIPTION: object constructor
            %
            %INPUT
            %fda = []        %[struct]
            %
            %for type is Fourier
            %spline_range =[]        -[double]     (2x1) the range of the spline
            %spline_nbasis =[]       -[integer >0] (1x1) the number of basis spline
            %spline_nbasis_beta =[]  -[integer >0] (1x1) the number of basis spline for beta
            %spline_nbasis_sigma =[] -[integer >0] (1x1) the number of basis spline for sigma_eps
            %
            %for type is Bspline
            %spline_range=[]    -   [double]            (2x1) the range of the spline
            %spline_order=[]    -   [integer >0]        (1x1) the order of the spline
            %spline_knots=[]    -   [double]            (sx1) the spline knots
            %spline_order_beta=[]    -   [integer >0]        (1x1) the order of the spline
            %spline_knots_beta=[]    -   [double]            (sx1) the spline knots
            %spline_order_sigma=[]    -   [integer >0]        (1x1) the order of the spline
            %spline_knots_sigma=[]    -   [double]            (sx1) the spline knots
            %
            %OUTPUT
            %obj                -   [stem_fda object]   (1x1)
            
     
            if sum(strcmp(obj_fda.spline_type,{'Fourier','Bspline'}))==0
                error('The spline type must be Fourier or Bspline');
            elseif strcmp(obj_fda.spline_type,'Fourier')
                obj.spline_type = obj_fda.spline_type;
                if isempty(obj_fda.spline_nbasis)||isempty(obj_fda.spline_range)
                    error('All the input arguments must be provided');
                end
                obj.spline_range=obj_fda.spline_range;
                %obj.spline_nbasis=obj_fda.spline_nbasis;
                if mod(obj_fda.spline_nbasis,2)==0
                    warning('The Fourier basis number must be odd, the number is increased by 1.')
                end
                obj.spline_basis=create_fourier_basis(obj.spline_range, obj_fda.spline_nbasis);
                obj.spline_nbasis=getnbasis(obj.spline_basis);
                
                if not(isempty(obj_fda.spline_nbasis_beta))
                    obj.flag_beta_spline = 1;
                    %obj.spline_nbasis_beta=obj_fda.spline_nbasis_beta;
                    if mod(obj_fda.spline_nbasis_beta,2)==0
                        warning('The Fourier basis number must be odd, the number is increased by 1.')
                    end
                    obj.spline_basis_beta=create_fourier_basis(obj.spline_range, obj_fda.spline_nbasis_beta);
                    obj.spline_nbasis_beta=getnbasis(obj.spline_basis_beta);
                end
                
                if not(isempty(obj_fda.spline_nbasis_sigma))
                    obj.flag_sigma_eps_spline = 1;
                    %obj.spline_nbasis_sigma=obj_fda.spline_nbasis_sigma;
                    if mod(obj_fda.spline_nbasis_sigma,2)==0
                        warning('The Fourier basis number must be odd, the number is increased by 1.')
                    end
                    obj.spline_basis_sigma=create_fourier_basis(obj.spline_range, obj_fda.spline_nbasis_sigma);
                    obj.spline_nbasis_sigma=getnbasis(obj.spline_basis_sigma);
                end
                
            else
                obj.spline_type = obj_fda.spline_type;
                if isempty(obj_fda.spline_knots)||isempty(obj_fda.spline_range)
                    error('All the input arguments must be provided');
                end
                if max(obj_fda.spline_knots)>obj_fda.spline_range(2)
                    error('The highest element of spline_knots cannot be higher than spline_range(2)');
                end
                if min(obj_fda.spline_knots)<obj_fda.spline_range(1)
                    error('The lowest element of spline_knots cannot be lower than spline_range(1)');
                end
                
                obj.spline_range = obj_fda.spline_range;
                obj.spline_order=obj_fda.spline_order;
                obj.spline_knots=obj_fda.spline_knots;

                norder=obj.spline_order+1;
                nbasis=length(obj.spline_knots)+norder-2;
                obj.spline_basis=create_bspline_basis(obj.spline_range, nbasis, norder, obj.spline_knots);
                
                if not(isempty(obj_fda.spline_order_beta))&&isempty(obj_fda.spline_knots_beta)
                    error('Spline knots for beta must be provided');
                end
                if not(isempty(obj_fda.spline_order_sigma))&&isempty(obj_fda.spline_knots_sigma)
                    error('Spline knots for sigma_eps must be provided');
                end

                if not(isempty(obj_fda.spline_order_beta))
                    obj.flag_beta_spline = 1;
                    if max(obj_fda.spline_knots_beta)>obj_fda.spline_range(2)
                        error('The highest element of spline_knots cannot be higher than spline_range(2)');
                    end
                    if min(obj_fda.spline_knots_beta)<obj_fda.spline_range(1)
                        error('The lowest element of spline_knots cannot be lower than spline_range(1)');
                    end

                    obj.spline_order_beta = obj_fda.spline_order_beta;
                    obj.spline_knots_beta = obj_fda.spline_knots_beta;
                    norder=obj.spline_order_beta+1;
                    nbasis=length(obj.spline_knots_beta)+norder-2;
                    obj.spline_basis_beta=create_bspline_basis(obj.spline_range, nbasis, norder, obj.spline_knots_beta);

                end
                if not(isempty(obj_fda.spline_order_sigma))
                    
                    obj.flag_sigma_eps_spline = 1;
                    if max(obj_fda.spline_knots_sigma)>obj_fda.spline_range(2)
                        error('The highest element of spline_knots cannot be higher than spline_range(2)');
                    end
                    if min(obj_fda.spline_knots_sigma)<obj_fda.spline_range(1)
                        error('The lowest element of spline_knots cannot be lower than spline_range(1)');
                    end
                    
                    obj.spline_order_sigma = obj_fda.spline_order_sigma;
                    obj.spline_knots_sigma = obj_fda.spline_knots_sigma;

                    norder=obj.spline_order_sigma+1;
                    nbasis=length(obj.spline_knots_sigma)+norder-2;
                    obj.spline_basis_sigma=create_bspline_basis(obj.spline_range, nbasis, norder, obj.spline_knots_sigma);
                end

            end    
        end
             
        %Class set methods
        function obj = set.spline_order(obj,spline_order)
            if spline_order<1
                error('spline_order must be > 0');
            end
            obj.spline_order=spline_order;
        end
        
        function obj = set.spline_range(obj,spline_range)
            if not(length(spline_range)==2)
                error('spline_range must be a 2x1 vector');
            end
            if spline_range(2)<=spline_range(1)
                error('The upper bound of spline_range must be higher than the lower bound');
            end
            obj.spline_range=spline_range;
        end
        
        function obj = set.spline_knots(obj,spline_knots)
            if length(spline_knots)<2
                error('spline_knots must be at least 2x1');
            end
            if any(diff(spline_knots)<=0)
                error('spline_knots must be a vector of sorted and non equal elements');
            end
            obj.spline_knots=spline_knots;
        end
        
        function obj = set.spline_order_beta(obj,spline_order_beta)
            if spline_order_beta<1
                error('spline_order for beta must be > 0');
            end
            obj.spline_order_beta=spline_order_beta;
        end
        
        function obj = set.spline_order_sigma(obj,spline_order_sigma)
            if spline_order_sigma<1
                error('spline_order for sigma must be > 0');
            end
            obj.spline_order_sigma=spline_order_sigma;
        end
        
        function obj = set.spline_knots_beta(obj,spline_knots_beta)
            if length(spline_knots_beta)<2
                error('spline_knots for beta must be at least 2x1');
            end
            if any(diff(spline_knots_beta)<=0)
                error('spline_knots for beta must be a vector of sorted and non equal elements');
            end
            obj.spline_knots_beta=spline_knots_beta;
        end
        
        function obj = set.spline_knots_sigma(obj,spline_knots_sigma)
            if length(spline_knots_sigma)<2
                error('spline_knots for sigma must be at least 2x1');
            end
            if any(diff(spline_knots_sigma)<=0)
                error('spline_knots for sigma must be a vector of sorted and non equal elements');
            end
            obj.spline_knots_sigma=spline_knots_sigma;
        end
        
    end
end
