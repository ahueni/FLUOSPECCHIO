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
        
        function execute(this)
            import ch.specchio.types.*;
            attribute = this.levelContext.starterContext.specchioClient.getAttributesNameHash().get('SNR');
            % calculates the signal qi's 
            % WR
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(100*nanmean(this.levelContext.vectors.get(this.levelContext.DC_WR_idx)./(this.levelContext.vectors.get(this.levelContext.WR_idx)+ this.levelContext.vectors.get(this.levelContext.DC_WR_idx))));
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR_idx))).add(mp);

            % VEG
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(100*nanmean(this.levelContext.vectors.get(this.levelContext.DC_VEG_idx)./(this.levelContext.vectors.get(this.levelContext.VEG_idx)+ this.levelContext.vectors.get(this.levelContext.DC_VEG_idx))));
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.VEG_idx))).add(mp);

            % WR2
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(100*nanmean(this.levelContext.vectors.get(this.levelContext.DC_WR_idx)./(this.levelContext.vectors.get(this.levelContext.WR2_idx)+ this.levelContext.vectors.get(this.levelContext.DC_WR_idx))));
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR2_idx))).add(mp);
            
        end
    end
end