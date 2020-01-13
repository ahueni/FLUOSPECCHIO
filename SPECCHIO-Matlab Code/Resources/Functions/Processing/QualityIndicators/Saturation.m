classdef Saturation < SpecchioQualityIndicesInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public)
        levelContext; % Containing the information needed from SpecchioLevelInterface to do the calculation on a single group
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
    methods (Access = private)
        % Add some small helper functions here
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = Saturation(context)
           this.levelContext = context; 
        end
        
        function newValues = execute(this)
            newValues = java.util.ArrayList;
            if this.levelContext.starterContext.currentInstrumentType == 2
                %FLUO
                max_count = 200000;
            else
                %FULL
                max_count = 54000;
            end
            
            %sv_e
            newValues.add(sum(this.levelContext.vectors.get(this.levelContext.WR_idx) == max_count));
            %sv_L
            newValues.add(sum(this.levelContext.vectors.get(this.levelContext.VEG_idx) == max_count));
            %sv_E2
            newValues.add(sum(this.levelContext.vectors.get(this.levelContext.WR2_idx) == max_count));

        end
    end
end