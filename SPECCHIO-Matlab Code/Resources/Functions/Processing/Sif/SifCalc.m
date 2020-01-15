classdef SifCalc < SpecchioCalculationInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public)
        levelContext; % Containing the information needed from SpecchioLevelInterface to do the calculation on a single group
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = private)
        % Add some small helper functions here
        function [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = sif_calc(this, veg, wr1, wr2)
            wr_mean = mean([wr1, wr2], 2);
            [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = ...
                FLOX_SpecFit_master_FLUOSPECCHIO(...
                this.levelContext.spaceContext.wavelength,wr_mean,veg);
        end
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = SifCalc(context) 
            this.levelContext = context;
        end
        
        function [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = execute(this)      
            [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = ...
                sif_calc(this, this.levelContext.vectors.get(this.levelContext.VEG_idx),...
                this.levelContext.vectors.get(this.levelContext.WR_idx), ...
                this.levelContext.vectors.get(this.levelContext.WR2_idx));
        end
    end
end  