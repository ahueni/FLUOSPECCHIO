classdef Target < SpecchioQualityIndicesInterface
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
        
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = Target(context)
           this.levelContext = context; 
        end
        
        function execute(this)
            import ch.specchio.types.*;
            attribute = this.levelContext.starterContext.specchioClient.getAttributesNameHash().get('Target/Reference Designator');
            
            %sv_WR
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(93);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR_idx))).add(mp);
            %sv_VEG
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(92);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.VEG_idx))).add(mp);
            %sv_WR2
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(93);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR2_idx))).add(mp);
        end
    end
end