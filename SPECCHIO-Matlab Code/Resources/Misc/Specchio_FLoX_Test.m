%%%%%%%%%%%%%%%%%%%%%
% Bastian Buman
% Testing Matlab - Specchio - FLoX -> Data
% 06-Sep-2019 09:07:21
% Version 1.0
%%%%%%%%%%%%%%%%%%%%%

%% Start connection to Specchio:
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
db_descriptor_list.get(0);

%% 1. - Get Reflectance data using Hierarchy iD: 1342
% get spectra ids for this hierarchy
hierarchy_id = 1342;
node = hierarchy_node(hierarchy_id, "", "");
ids = specchio_client.getSpectrumIdsForNode(node);

% Check how many spectra we found
ids.size()

% List the spectrum ids:
ids.toArray

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

%% 4. - Plot Regions
% Plot O2-B region and SIF-B
figure('Name', 'O2-B')
plot(wvl, vectors)
title("Telluric O2-B absorption region [670 - 695 nm]")
xlabel('Wavelength [nm]')
ylabel(unit)
ylim([0 0.1])
xlim([670 695])
x = [685 685]
y = [0 0.1]
line(x, y, 'Color', 'red', 'LineStyle', '--')
x = [690 690]
y = [0 0.1]
line(x, y, 'Color', 'red', 'LineStyle', '--')
text(685, 0.09, '\leftarrow SIF-B 685 - 690 nm')
text(690, 0.09, '\rightarrow')

% Plot O2-A region and SIF-A
figure('Name', 'O2-A')
plot(wvl, vectors)
title("Telluric O2-A absorption region [755 - 780 nm]")
xlabel('Wavelength [nm]')
ylabel(unit)
ylim([0 0.1])
xlim([730 750])
x = [730 7730]
y = [0 0.1]
line(x, y, 'Color', 'red', 'LineStyle', '--')
x = [740 740]
y = [0 0.1]
line(x, y, 'Color', 'red', 'LineStyle', '--')
text(730, 0.09, '\leftarrow SIF-A 730 - 740 nm')
text(740, 0.09, '\rightarrow')

