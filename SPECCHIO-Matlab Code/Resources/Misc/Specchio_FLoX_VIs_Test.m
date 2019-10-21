%%%%%%%%%%%%%%%%%%%%%
% Bastian Buman
% Testing Matlab - Specchio - FLoX -> Data
% 09-Sep-2019 14:55:17
% Version 1.0
%%%%%%%%%%%%%%%%%%%%%
%% %% Start connection to Specchio:
% dynamic classpath setting 
% javaaddpath ({'C:\Users\basti\Documents\Specchio\specchio-client.jar'});

% Import the classes of the SPECCHIO client package:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;

% Create a client factory instance and get a list of all connection details:
cf = SPECCHIOClientFactory.getInstance();
db_descriptor_list = cf.getAllServerDescriptors();

% Create client for the first entry in the database connection list:
index = 0;
specchio_client = cf.createClient(db_descriptor_list.get(index)); % zero indexed?    

% Check connection to db:
%db_descriptor_list.get(0);
hierarchy_id = 1341;
%FLoX_Vegetation_Indices(1342);

%% Calculate Indices
function FLoX_Vegetation_Indices(hierarchy_id)

    %specchio_client.settings.reflectance_hierarchy_level = 1; % controls the level where the radiance folder is created

    % get spectra ids for this hierarchy
    node = hierarchy_node(hierarchy_id, "", "");
    ids = specchio_client.getSpectrumIdsForNode(node);

    % order data by spectrum number (this should only ever be a single
    % space ...)
    spaces = specchio_client.getSpaces(ids, 'Spectrum Number');
    L_ids = spaces(1).getSpectrumIds(); % get ids sorted by  'Spectrum Number'
    %space = spaces(1);

    % restrict to FloX files
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);

    query.addColumn('spectrum_id')


    cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
    cond.setValue(L_ids);
    cond.setOperator('in');
    query.add_condition(cond);


    cond = SpectrumQueryCondition('spectrum', 'file_format_id');
    file_format_id =specchio_client.getFileFormatId('FloX');
    cond.setValue(num2str(file_format_id));
    cond.setOperator('=');
    query.add_condition(cond);

    ids = specchio_client.getSpectrumIdsMatchingQuery(query);


    % order data by spectrum number (this should only ever be a single
    % space ...)
    spaces = specchio_client.getSpaces(ids, 'Spectrum Number');
    ids = spaces(1).getSpectrumIds(); % get ids sorted by  'Spectrum Number'
    space = spaces(1);

    % load space
    space = specchio_client.loadSpace(space);
    vectors = space.getVectorsAsArray();
    wvl = space.getAverageWavelengths();

    % get file name vector
    filenames = specchio_client.getMetaparameterValues(ids, 'File Name');

    % select groups of 3 and loop over data <-- why 3?
    %group_no = ids.size / 3;
    no_of_bands = space.getDimensionality.intValue; % use explicit conversion as for some reason a Java Integer cannot be used to create a matrix with 'ones'.

    R = ones(no_of_bands, group_no);
    provenance_spectrum_ids= java.util.ArrayList();

    for i=1:9
        compute_VIs(wvl, vectors(i,:)')
    end
end
