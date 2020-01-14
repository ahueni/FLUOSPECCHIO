classdef RadCalc < SpecchioCalculationInterface
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
        function L = rad_cal(this, DN, DN_DC, IT, gain)
            DN_dc = DN - DN_DC;
            DN_dc_it = DN_dc / IT;
            L = DN_dc_it .* gain;
        end
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = RadCalc(context) 
            this.levelContext = context;
        end
        
        function newVectors = execute(this)
            newVectors = java.util.ArrayList();
            newVectors.add(this.rad_cal(this.levelContext.vectors.get(this.levelContext.VEG_idx),...
                 this.levelContext.vectors.get(this.levelContext.DC_VEG_idx),... 
                 this.levelContext.spaceContext.integrationTime.get(this.levelContext.VEG_idx)/1000,...
                 this.levelContext.spaceContext.calUpCoef));
             newVectors.add(this.rad_cal(this.levelContext.vectors.get(this.levelContext.WR_idx),...
                 this.levelContext.vectors.get(this.levelContext.DC_WR_idx),...
                 this.levelContext.spaceContext.integrationTime.get(this.levelContext.WR_idx)/1000,...
                 this.levelContext.spaceContext.calUpCoef));
             newVectors.add(this.rad_cal(this.levelContext.vectors.get(this.levelContext.WR2_idx),...
                 this.levelContext.vectors.get(this.levelContext.DC_WR_idx),...
                 this.levelContext.spaceContext.integrationTime.get(this.levelContext.WR2_idx)/1000,...
                 this.levelContext.spaceContext.calUpCoef));
        end
    end
end  