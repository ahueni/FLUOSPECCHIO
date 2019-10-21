%%%%%%%%%%%%%%%%%%%%%
% Bastian Buman
% Testing Matlab - Specchio access
% 06-Sep-2019 08:18:25
% Version 1.0
%%%%%%%%%%%%%%%%%%%%%

%% Start connection to Specchio:
% dynamic classpath setting 
% javaaddpath ({'C:\Users\basti\Documents\Specchio\specchio-client.jar'});

% Import the classes of the SPECCHIO client package:
import ch.specchio.client.*;

% Create a client factory instance and get a list of all connection details:
cf = SPECCHIOClientFactory.getInstance();
db_descriptor_list = cf.getAllServerDescriptors();

% Create client for the first entry in the database connection list:
specchio_client = cf.createClient(db_descriptor_list.get(0)); % zero indexed?

% Check connection to db:
db_descriptor_list.get(0);

%% 1. - Filter data: Our condition is that the altitude must be 10 m or higher.
% Import the query package:
import ch.specchio.queries.*;

% Create a query object:
query = Query();

% Get the attribute that we want to restrict:
attr = specchio_client.getAttributesNameHash().get('Altitude');

% Create query condition for the altitude attribute and configure it:
cond = EAVQueryConditionObject(attr);
cond.setValue('10.0');
cond.setOperator('>=');
query.add_condition(cond);

% Get spectrum ids that match the query:
ids = specchio_client.getSpectrumIdsMatchingQuery(query);

% Check how many spectra we found
ids.size()

% List the spectrum ids:
ids.toArray

% Add another condition to restrict the maximum altitude:
% cond = EAVQueryConditionObject(attr);
% cond.setValue('20.0');
% cond.setOperator('<');
% query.add_condition(cond);

% Get spectrum ids that match the query:
% ids = specchio_client.getSpectrumIdsMatchingQuery(query);

%% 2. - Load Spectral data:
% Create spectral spaces and order the spectra by their acquisition time 
% (note: this does not load the spectral vectors yet but only prepares the ‘containers’) :
spaces = specchio_client.getSpaces(ids, 'Acquisition Time');

% Find out how many space we have received:
spaces.length()

% Get the first space (note: the spaces are now a Matlab array and are 
% therefore indexed starting at 1):
space = spaces(1);

% The order of the ids may have changed because the vectors in the space are 
% ordered by their Acquisition Time; therefore get the ids in their correct 
% sequence to match the vector sequence:
ids = space.getSpectrumIds(); % get them sorted by 'Acquisition Time’

% Load the spectral data from the database into the space:
space = specchio_client.loadSpace(space);

% Get the spectral vectors as Matlab array:
vectors = space.getVectorsAsArray();

% Get the wavelengths are a vector:
wvl = space.getAverageWavelengths();

% Get the unit of the spectra:
unit = char(space.getMeasurementUnit.getUnitName);

%% 3. - Plot loaded Spectra:
% Plot the spectra:
figure
plot(wvl, vectors)
xlabel('Wavelength [nm]')
ylabel(unit)
ylim([0 1])

%% 4. - Load Metadata:
% Get the file names of the spectra held by the current space:
filenames_ = specchio_client.getMetaparameterValues(ids, 'File Name');

% Create legend with filenames and add it to plot:
% legend_str = zeros(size(filenames_));
for i=1:size(filenames_)
    legend_str{i} = filenames_.get(i-1);
end
legend (legend_str)

% Get lat/lon as vectors and plot them:
lat = specchio_client.getMetaparameterValues(ids, 'Latitude').get_as_double_array();
lon = specchio_client.getMetaparameterValues(ids, 'Longitude').get_as_double_array();
figure
plot(lon, lat, 'o');

