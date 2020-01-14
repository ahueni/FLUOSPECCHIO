classdef RefCalc < SpecchioCalculationInterface
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
        function [R, wr_mean] = ref_calc(this, veg, wr1, wr2)
            wr_mean = mean([wr1, wr2], 2);
            R = veg ./ wr_mean;
        end
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = RefCalc(context) 
            this.levelContext = context;
        end
        
        function newVectors = execute(this)
            newVectors = java.util.ArrayList();
            newVectors.add(ref_calc(this, this.levelContext.vectors.get(this.levelContext.VEG_idx),...
                this.levelContext.vectors.get(this.levelContext.WR_idx), ...
                this.levelContext.vectors.get(this.levelContext.WR2_idx)));
        end
    end
end  