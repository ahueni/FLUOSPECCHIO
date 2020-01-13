classdef (Abstract) SpecchioQualityIndicesInterface
    % ==================================================
    % Protected Properties
    % ==================================================
    properties (Abstract)
        levelContext; % Containing the information needed from 
        % SpecchioLevelInterface to do the quality indices
        % on a List of ordered vectors of a single ordered group
    end
    
    % ==================================================
    % Abstract Methods
    % ==================================================
    methods (Abstract)
        % executes a specific quality index for a given List of Vectors
        % returns an Arraylist of new Values in processing order
        % (according to spectrumIds)
        execute(this) % executes a specific quality Index for a given space
    end
end