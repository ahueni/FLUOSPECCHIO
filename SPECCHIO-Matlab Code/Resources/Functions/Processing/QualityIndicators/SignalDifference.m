classdef SignalDifference < SpecchioQualityIndicesInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public)
        levelContext; % Containing the information needed from SpecchioLevelInterface to do the calculation on a single group
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = SignalDifference(context)
           this.levelContext = context; 
        end
        
        function results = execute(this)
            % calculates the signal qi's 
            results = java.util.ArrayList;
            results.add(nanmean(this.levelContext.vectors.get(this.levelContext.DC_WR_idx)./(this.levelContext.vectors.get(this.levelContext.WR_idx)+ this.levelContext.vectors.get(this.levelContext.DC_WR_idx))));
            results.add(nanmean(this.levelContext.vectors.get(this.levelContext.DC_VEG_idx)./(this.levelContext.vectors.get(this.levelContext.VEG_idx)+ this.levelContext.vectors.get(this.levelContext.DC_VEG_idx))));
            results.add(nanmean(this.levelContext.vectors.get(this.levelContext.DC_WR_idx)./(this.levelContext.vectors.get(this.levelContext.WR2_idx)+ this.levelContext.vectors.get(this.levelContext.DC_WR_idx))));
            
        end
    end
end