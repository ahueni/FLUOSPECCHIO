classdef ProcessLevel0To1 < SpecchioGroupInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public) 
        spaceContext; % Containing the information needed from Starter to do all calculations, qi and db-updates
        spectrumIds; % Spectrum Ids of current Group
        vectors;    %vectors of current Group
        calcValuesToUpdate  = java.util.HashMap(); % A hashmap with: String key = db-Column identifier for this attribute, 
                                                % ArrayList Value = values to insert ordered by processing Order (eq. SpectrumID order)
        qiValuesToUpdate    = java.util.HashMap();   % A hashmap with: String key = db-Column identifier for this attribute, 
                                                % ArrayList Value = values to insert ordered by processing Order (eq. SpectrumID order)
        % Define the indices as they are in vectors
        DC_VEG_idx  = 4;
        DC_WR_idx   = 3;
        VEG_idx     = 1;
        WR_idx      = 0;
        WR2_idx     = 2;
        provenance_spectrum_ids;
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = toProvenanceId(this)
            provenance_spectrum_ids = java.util.ArrayList;
            provenance_spectrum_ids.add(uint32(this.spectrumIds.get(this.WR_idx)));
            provenance_spectrum_ids.add(uint32(this.spectrumIds.get(this.VEG_idx)));
            provenance_spectrum_ids.add(uint32(this.spectrumIds.get(this.WR2_idx)));
            this.provenance_spectrum_ids = provenance_spectrum_ids;
        end
        
        function this = prepareMetaParams(this)
            this.spaceContext.MetaData.put(uint32(this.spectrumIds.get(this.WR_idx)), java.util.ArrayList);
            this.spaceContext.MetaData.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
            this.spaceContext.MetaData.put(uint32(this.spectrumIds.get(this.WR2_idx)), java.util.ArrayList);
        end
        
        function this = ProcessLevel0To1(context, spectrumIds, vectors)
            % PROCESSLEVEL0TO1 constructor for ProcessLevel0To1 class
            % context refers to a Starter object and is needed to use
            % SPECCHIO-Client and its functions
            import ch.specchio.types.*;
            this.spaceContext = context;
            this.spectrumIds = spectrumIds;
            this.vectors = vectors; 
            this = this.toProvenanceId();
            this = this.prepareMetaParams();
        end
        
        function this = calculations(this)
            % add calculation functions here each function should return
            % an java.util.ArrayList containing the changed values in
            % processing order (ordered by spectrumIds)
            radCalc = RadCalc(this);
            newSpectra = radCalc.execute();
            this.spaceContext.ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), newSpectra.get(0));
            this.spaceContext.ValuesToUpdate.put(uint32(this.spectrumIds.get(this.WR_idx)),  newSpectra.get(1));
            this.spaceContext.ValuesToUpdate.put(uint32(this.spectrumIds.get(this.WR2_idx)), newSpectra.get(2));
        end
        
        function this = qualityIndices(this)
            % add QI-functions here each function should return
            % this containing the changed space
            saturation = Saturation(this);
            snr = SignalDifference(this);
            illumination = Illumination(this);
            target = Target(this);
                                    
%             Spectral Shift evaluation only if broadrange (FULL) sensor
            if(this.spaceContext.InstrumentType == 1)
                spectral_shift = SpectralShift(this);
                spectral_shift.execute();
            end 
            
            saturation.execute();
            snr.execute();
            illumination.execute();
            target.execute();
            
        end 
    end
end