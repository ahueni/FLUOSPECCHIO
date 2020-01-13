classdef CalibrateSpace < SpecchioCalculationInterface
    % ==================================================
    % Protected Properties
    % ==================================================
    properties (SetAccess = protected, GetAccess = protected)
        context; % Containing the information needed from SpecchioLevelInterface to do the calculation on a single group
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
    methods (Access = private)
        % Add some small helper functions here
    end
    
    % ==================================================
    % Abstract Methods
    % ==================================================
    methods (Access = public)
        function this = calculate(this)
           % Do Something with the data received (Call all helper
           % functions in order to process the space as needed)
        end
    end
end