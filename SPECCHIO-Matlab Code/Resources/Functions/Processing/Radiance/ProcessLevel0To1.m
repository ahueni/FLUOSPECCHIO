classdef ProcessLevel0To1 < SpecchioLevelInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public) 
        level = 1;
        starterContext; % Containing the information needed from Starter to do all calculations, qi and db-updates
        spectrumIds; % Spectrum Ids of current Group
        vectors;    %vectors of current Group
        calcValuesToUpdate = java.util.HashMap(); % A hashmap with: String key = db-Column identifier for this attribute, 
                                                % ArrayList Value = values to insert ordered by processing Order (eq. SpectrumID order)
        qiValuesToUpdate = java.util.HashMap();   % A hashmap with: String key = db-Column identifier for this attribute, 
                                                % ArrayList Value = values to insert ordered by processing Order (eq. SpectrumID order)
        % Define the indices as they are in vectors
        DC_VEG_idx =    4;
        DC_WR_idx =     3;
        VEG_idx =       1;
        WR_idx =        0;
        WR2_idx =       2;
        provenance_spectrum_ids;
        metaParameters;
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = toProvenanceId(this)
            provenance_spectrum_ids = java.util.ArrayList;
            provenance_spectrum_ids.add(java.lang.Integer(this.spectrumIds.get(this.WR_idx)));
            provenance_spectrum_ids.add(java.lang.Integer(this.spectrumIds.get(this.VEG_idx)));
            provenance_spectrum_ids.add(java.lang.Integer(this.spectrumIds.get(this.WR2_idx)));
            this.provenance_spectrum_ids = provenance_spectrum_ids;
        end
        
        function this = prepareMetaParams(this)
            metaParameters = java.util.HashMap;
            metaParameters.put(java.lang.Integer(this.spectrumIds.get(this.WR_idx)), java.util.ArrayList);
            metaParameters.put(java.lang.Integer(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
            metaParameters.put(java.lang.Integer(this.spectrumIds.get(this.WR2_idx)), java.util.ArrayList);
            this.metaParameters = metaParameters;
        end
        
        function this = ProcessLevel0To1(context, spectrumIds, vectors)
            % PROCESSLEVEL0TO1 constructor for ProcessLevel0To1 class
            % context refers to a Starter object and is needed to use
            % SPECCHIO-Client and its functions
            import ch.specchio.types.*;
            this.starterContext = context;
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
            this.calcValuesToUpdate.put('Radiance', radCalc.execute());
        end
        
        function this = qualityIndices(this)
            % add QI-functions here each function should return
            % this containing the changed space
            saturation = Saturation(this);
            snr = SignalDifference(this);
            illumination = Illumination(this);
            target = Target(this);
            saturation.execute();
            snr.execute();
            illumination.execute();
            target.execute();
            this.metaParameters;
        end 
    end
end