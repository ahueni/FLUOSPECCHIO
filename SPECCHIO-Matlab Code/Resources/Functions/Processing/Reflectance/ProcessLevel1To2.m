classdef ProcessLevel1To2 < SpecchioGroupInterface
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
        VEG_idx     = 1;
        WR_idx      = 2;
        WR2_idx     = 0;
        provenance_spectrum_ids; 
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = toProvenanceId(this)
            provenance_spectrum_ids = java.util.ArrayList;
            provenance_spectrum_ids.add(uint32(this.spectrumIds.get(this.VEG_idx)));
            this.provenance_spectrum_ids = provenance_spectrum_ids;
        end
        
        function this = prepareMetaParams(this)
            this.spaceContext.MetaData.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
        end
        
        function this = ProcessLevel1To2(context, spectrumIds, vectors)
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
            refCalc = RefCalc(this);
            newSpectra = refCalc.execute();
            this.spaceContext.ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), newSpectra.get(0));
        end
        
        function this = vis(this)
            import ch.specchio.types.*;
            [VIs] = computeVIs(this.spaceContext.wavelength, ...
                this.spaceContext.ValuesToUpdate.get(uint32(this.spectrumIds.get(this.VEG_idx))));
            
            for k=1:width(VIs)
                attribute = this.spaceContext.starterContext.specchioClient.getAttributesNameHash().get(VIs.Properties.VariableNames{k});
                mp = MetaParameter.newInstance(attribute);
                
                % VIs have to be numeric:
                if(isfinite(VIs.(k)))
                    mp.setValue(VIs.(k));
                else
                    mp.setValue(1);
                end
                
                this.spaceContext.MetaData.get(uint32(this.spectrumIds.get(this.VEG_idx))).add(mp);
            end
        end
        
        function this = qualityIndices(this)
            % add QI-functions here each function should return
            % this containing the changed space
        end 
    end
end