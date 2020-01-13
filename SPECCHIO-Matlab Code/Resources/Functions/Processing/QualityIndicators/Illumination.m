classdef Illumination < SpecchioQualityIndicesInterface
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
        function this = Illumination(context)
           this.levelContext = context; 
        end
        
        function execute(this)
            import ch.specchio.types.*;
            attribute = this.levelContext.starterContext.specchioClient.getAttributesNameHash().get('Irradiance Instability');

            
            % QC3. Illumination condition stability. (E_stability)
            % QC3 evaluates if the illumination condition between the consecutive upward measurements are stable.
            % This is evaluated according to the percentage of error between the 2 upwards record on a 2 nm average.
            % QC3 values vary between 0 and 100.  
            wl1     = 748;
            range   = 2;
            WR = this.levelContext.vectors.get(this.levelContext.WR_idx);
            WR2 = this.levelContext.vectors.get(this.levelContext.WR2_idx);
            start_band_ind  = this.levelContext.starterContext.currentSpace.get_nearest_band(java.lang.Double(wl1));
            end_band_ind    = this.levelContext.starterContext.currentSpace.get_nearest_band(java.lang.Double(wl1 + range));
            E1 = mean(WR(start_band_ind:end_band_ind));
            E2 = mean(WR2(start_band_ind:end_band_ind));
    
            E_stability = (abs(E1-E2))/E1*100;
    
            %sv_WR
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(0);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR_idx))).add(mp);
            %sv_VEG
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(100*E_stability);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.VEG_idx))).add(mp);
            %sv_WR2
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(0);
            this.levelContext.starterContext.currentMetaData.get(java.lang.Integer(this.levelContext.spectrumIds.get(this.levelContext.WR2_idx))).add(mp);
        end
    end
end