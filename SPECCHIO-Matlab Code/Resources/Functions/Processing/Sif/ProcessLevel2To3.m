classdef ProcessLevel2To3 < SpecchioGroupInterface
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
        out_table;
        outF_SFM;
        outR_SFM;
        outF_SpecFit;
        outR_SpecFit;
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
%           SPECFIT:
            this.spaceContext.outF_SpecFit_Metadata.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
            this.spaceContext.outR_SpecFit_Metadata.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
%             SFM:
%             this.spaceContext.outF_SFM_Metadata.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
%             this.spaceContext.outR_SFM_Metadata.put(uint32(this.spectrumIds.get(this.VEG_idx)), java.util.ArrayList);
        end
        
        function this = ProcessLevel2To3(context, spectrumIds, vectors)
            import ch.specchio.types.*;
            this.spaceContext = context;
            this.spectrumIds = spectrumIds;
            this.vectors = vectors; 
            this = this.toProvenanceId();
            this = this.prepareMetaParams();
        end
        
        function this = calculations(this)
            sifCalc = SifCalc(this);
            [this.out_table, this.outF_SFM, this.outR_SFM,...
                this.outF_SpecFit, this.outR_SpecFit] = sifCalc.execute();
            this = splitOutputs(this);
            this = sifMetrics(this);
        end
        
        function this = splitOutputs(this)
            this.spaceContext.outF_SpecFit_ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), this.outF_SpecFit);
            this.spaceContext.outR_SpecFit_ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), this.outR_SpecFit);
%             SFM
%             this.spaceContext.outF_SFM_ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), this.outF_SFM);
%             this.spaceContext.outR_SFM_ValuesToUpdate.put(uint32(this.spectrumIds.get(this.VEG_idx)), this.outR_SFM);
        end
        
        function this = sifMetrics(this)
            import ch.specchio.types.*;

            for k=1:width(this.out_table)
                attributeName = this.out_table.Properties.VariableNames{k};
                if(~(contains(attributeName, 'FLD')))
                    
                    attribute = this.spaceContext.starterContext.specchioClient.getAttributesNameHash().get(attributeName);
                    try
                        mp = MetaParameter.newInstance(attribute);

                        % VIs have to be numeric:
                        if(isfinite(this.out_table.(k)))
                            mp.setValue(this.out_table.(k));
                        else
                            mp.setValue(-999);
                        end

                        if(contains(attributeName, 'f_SFM'))
    %                         this.spaceContext.outF_SFM_Metadata.get(uint32(this.spectrumIds.get(this.VEG_idx))).add(mp);
                        elseif(contains(attributeName, 'r_SFM'))
    %                         this.spaceContext.outR_SFM_Metadata.get(uint32(this.spectrumIds.get(this.VEG_idx))).add(mp);
                        elseif(contains(attributeName, 'f_SpecFit') || contains(attributeName, 'f_max_FR') ...
                                || contains(attributeName, 'f_max_FR_wvl') || contains(attributeName, 'f_max_R') ...
                                || contains(attributeName, 'f_max_R_wvl') || contains(attributeName, 'f_int'))
                            this.spaceContext.outF_SpecFit_Metadata.get(uint32(this.spectrumIds.get(this.VEG_idx))).add(mp);
                        elseif(contains(attributeName, 'r_SpecFit'))
                            this.spaceContext.outR_SpecFit_Metadata.get(uint32(this.spectrumIds.get(this.VEG_idx))).add(mp);
                        end
                    catch
                        
                    end
                end
            end 
        end
 
        function this = qualityIndices(this)
           
        end 
    end
end