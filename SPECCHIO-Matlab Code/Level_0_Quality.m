function Level_0_Quality(hierarchy_id, db_connector_id)
%% Function FLoX_level_0 QIs
%   INPUT:
%   hierarchy_id        : hierarchy_id of the SPECCHIO DN hierarchy
%   db_connector_id     : index into the list of known database connection (identical to SPECCHIO client app)
% 
%   OUTPUT:
%   Stores QIs in SPECCHIO DB
%   
%   MISC:   
%   user_data           : A structure array used to store all specchio-related functionality. 
%   Structure array     : is a data type that groups related data using data containers called fields. Each field 
%                         can contain any type of data. Access data in a field using dot notation of the form structName.fieldName.
%   Specchio API        : https://specchio.ch/javadoc/
%   
%   SpectralSpace       : A Specchio-Class 
%
%   AUTHOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   EDITOR:
%   
%
%   DATE:
%   27-Sep-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
    index = db_connector_id;


    % Channel switching (true if up and downwelling was switched)
    user_data.switch_channels_for_flox = channelswitched;
    user_data.switch_channels_for_rox = channelswitched;

    % Import specchio functionality:
    import ch.specchio.client.*;
    import ch.specchio.queries.*;
    import ch.specchio.gui.*;
    import ch.specchio.types.*;
    import ch.specchio.*;

    % connect to SPECCHIO
    user_data.cf = SPECCHIOClientFactory.getInstance();
    user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
    user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));

    % get spectra ids for this hierarchy
    node = hierarchy_node(hierarchy_id, "", "");
    DN_ids = user_data.specchio_client.getSpectrumIdsForNode(node);

    % group by instrument and calibration: use space factory
    spaces = user_data.specchio_client.getSpaces(DN_ids, 'Acquisition Time');
    wvl = spaces(1).getAverageWavelengths();
    space_rstr = user_data.specchio_client.loadSpace(spaces(1));
    spectra_rstr = space_rstr.getVectorsAsArray();
    
    
    
end