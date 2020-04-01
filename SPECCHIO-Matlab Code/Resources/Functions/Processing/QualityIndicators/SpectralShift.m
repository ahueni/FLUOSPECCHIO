classdef SpectralShift < SpecchioQualityIndicesInterface
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
        function shift = spectral_shift_evaluation(this, wvl, radiance)
%             Oxygen A spectral shift evaluation
            pos_OA = 760.7302;
            mask_OA = (750 <= wvl) & (wvl <= 770);
            wvl_mask = wvl(mask_OA);
            reg_OA = radiance(mask_OA);
            min_OA = wvl_mask(reg_OA == min(reg_OA));
            diff_OA = min_OA - pos_OA;
            
%             Oxygen B spectral shift evaluation
            pos_OB = 687.777;
            mask_OB = (680<=wvl)&(wvl <=695);
            wvl_mask = wvl(mask_OB);
            reg_OB = radiance(mask_OB);
            min_OB = wvl_mask(reg_OB == min(reg_OB));
            diff_OB = min_OB - pos_OB;
            
            shift = nanmean([diff_OA, diff_OB]);
        end

    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = SpectralShift(context)
           this.levelContext = context; 
        end
        
        function execute(this)
            import ch.specchio.types.*;
            attribute = this.levelContext.spaceContext.starterContext.specchioClient.getAttributesNameHash().get('Spectral Shift');
            wvl = this.levelContext.spaceContext.space.getAverageWavelengths;
            WR = this.levelContext.spaceContext.ValuesToUpdate.get(uint32(this.levelContext.spectrumIds.get(this.levelContext.WR_idx)));
            WR2 = this.levelContext.spaceContext.ValuesToUpdate.get(uint32(this.levelContext.spectrumIds.get(this.levelContext.WR2_idx)));

            
            shift_WR1 = spectral_shift_evaluation(this, wvl, WR);
            shift_WR2 = spectral_shift_evaluation(this, wvl, WR2);

    
            %sv_WR
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(shift_WR1);
            this.levelContext.spaceContext.MetaData.get(uint32(this.levelContext.spectrumIds.get(this.levelContext.WR_idx))).add(mp);
            %sv_VEG
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(0);
            this.levelContext.spaceContext.MetaData.get(uint32(this.levelContext.spectrumIds.get(this.levelContext.VEG_idx))).add(mp);
            %sv_WR2
            mp = MetaParameter.newInstance(attribute);
            mp.setValue(shift_WR2);
            this.levelContext.spaceContext.MetaData.get(uint32(this.levelContext.spectrumIds.get(this.levelContext.WR2_idx))).add(mp);
        end
    end
end