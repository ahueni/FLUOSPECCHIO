classdef (Abstract) SpecchioCalculationInterface
    % ==================================================
    % Protected Properties
    % ==================================================
    properties (Abstract)
        levelContext; % Containing the information needed from SpecchioLevelInterface to do the calculation
        % on a List of ordered vectors of a single ordered group
    end
    
    % ==================================================
    % Abstract Methods
    % ==================================================
    methods (Abstract)
        % executes a specific calculation for a given List of Vectors
        % returns an Arraylist of new Vectors in processing order
        % (according to spectrumIds)
        execute(this) 
    end
end