classdef (Abstract) SpecchioGroupInterface
    % SPECCHIOLEVELINTERFACE defines a common ground to define
    % level-classes which can execute several calculations and 
    % quality-indices on a single group
    
    % ==================================================
    % Protected Properties
    % ==================================================
    properties (Abstract)
        spaceContext; % Containing the information needed from Starter to do all calculations, qi and db-updates
        spectrumIds; % Spectrum Ids of current Group
        vectors;    %vectors of current Group
        provenance_spectrum_ids; % extracted spectrum id's for radiance (level one)                                            
        qiValuesToUpdate; % = java.util.HashMap;    % A hashmap with: String key = db-Column identifier for this attribute, 
                                                    % ArrayList Value = values to insert ordered by processing Order (eq. SpectrumID order)
   end
    
    % ==================================================
    % Abstract Methods
    % ==================================================
    methods (Abstract=true)
        calculations(this)  % contains objects of type SpecchioCalculationInterface
        qualityIndices(this)% contains objects of type SpecchioQualityIndicesInterfac
    end
    
    methods (Access = public)
        function main(this)
            % MAIN calls all needed methods in the correct order
            % to start processing of one space
            calculations(this);
            qualityIndices(this);
       end
    end
end