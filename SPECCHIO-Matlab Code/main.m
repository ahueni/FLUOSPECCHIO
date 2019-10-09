%% Script: Main processing routine for the FLOXBOX 
%   INPUT:
%   hierarchy_id        : hierarchy_id of the SPECCHIO DN hierarchy
%   Java class path     : \MATLAB\R2019a\toolbox\local\classpath.txt -->
%                         make sure to include your specchio installation (specchio-client.jar)
%                         at the top of the classpath.txt
%
%   db_connector_id     : index into the list of known database connection (identical to SPECCHIO client app)
% 
%   OUTPUT:
%   Processing raw (Level-0) FLOXBOX data to Radiance (Level-1) and
%   Reflectance (Level-2)
%   
%   MISC:   
%   The FLOXBOX has two sensors: (1) is the FLAME (in these files sometimes called ROX), full range sensor, files
%   are named F*.csv; (2) is the QEpro, higher resolution for SIF retrieval (in these files someties called FLOX), files are named *.csv. 
%   Naming these sensors ROX or FLOX respectively is wrong, and will be changed to FLAME and QEpro.
%
%   AUTHOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   EDITOR:
%  
%
%   DATE:
%   V1, 19-Sep-2019
%   V2, 25-Sep-2019
%   V3, 04-Oct-2019

%% Processing
% Define Hierarchy Levels:
rawDataID               = 190;
radianceDataID          = 185;
reflectanceDataID       = 178;
% rawDataID_OEN           = 179;
% radianceData_OEN        = 180;
% reflectanceDataID_OEN   = 181;

% Define Connection info:
connectionID        = 2;

% Box setup:
switchedChannels    = false;

% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

% connect to SPECCHIO
user_data.cf                    = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list    = user_data.cf.getAllServerDescriptors();
user_data.specchio_client       = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));

% get spectra ids for this hierarchy
node    = hierarchy_node(rawDataID, "", "");
DN_ids  = user_data.specchio_client.getSpectrumIdsForNode(node);

% group spectra by spectral number: but as the spectral number can be
% repeated within a day, it is better to group by UTC or Acquisition time
% group_collection = user_data.specchio_client.sortByAttributes(user_data.space.getSpectrumIds, 'Spectrum Number');
group_collection    = user_data.specchio_client.sortByAttributes(DN_ids, 'Acquisition Time (UTC)');
groups              = group_collection.getSpectrum_id_lists;


% Split DNs up into a reasonable amount of threads figure out a good way to
% do it
threads         = 4;
remainder       = mod(size(groups),threads);
split           = floor(size(groups)/threads);
Gr_a            = java.util.ArrayList(groups.subList (0, split-1));
Gr_b            = java.util.ArrayList(groups.subList (split, 2*split-1));
Gr_c            = java.util.ArrayList(groups.subList (2*split, 3*split-1));
Gr_d            = java.util.ArrayList(groups.subList (3*split, 4*split+remainder));    
Gr_all          = java.util.ArrayList();
Gr_all.add(0, Gr_a);
Gr_all.add(1, Gr_b);
Gr_all.add(2, Gr_c);
Gr_all.add(3, Gr_d);

% Create an arraylist that contains the arraylists of the individual
% groups:
Gr_selected_DNs = java.util.ArrayList();
for i=0:size(Gr_all)-1
    selection = java.util.ArrayList();
    for k=0:size(Gr_all.get(i))-1
        for l=0:size(Gr_all.get(i).get(k).getSpectrumIds)-1
            selection.add(k,int32(Gr_all.get(i).get(k).getSpectrumIds.get(l)));
        end
    end
%     disp(num2str(i));
    Gr_selected_DNs.add(i, selection);
end

%% Level 0 -> Level 1
% Process Level 0 (DN) to Level 1 (Radiance)
parfor i=0:size(Gr_selected_DNs)-1
    FLOXBOX_Level_1(connectionID, switchedChannels, Gr_selected_DNs.get(i));
end

%% Level 1 -> Level 2
% Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
% it currently stores SIF not the Reflectance.
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);
