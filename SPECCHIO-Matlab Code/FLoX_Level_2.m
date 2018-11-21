%
%   FLoX_Level_2 - SPECCHIO Database Centric Processing
%
%   Code to process all data within a Radiance hierarchy to Reflectances.
%
%   hierarchy_id: hierarchy_id of the SPECCHIO Radiance hierarchy
%   specchio_pathname: path to local SPECCHIO Java installation
%
%   (c) 2018 ahueni, RSL, University of Zurich
%
%

function FLoX_Level_2(hierarchy_id, specchio_pathname)

    % debugging settings: used if no arguments are supplied to function
    if nargin() == 0
        hierarchy_id = 827 % 
        specchio_pathname = '/Applications/SPECCHIO_G4/SPECCHIO.app/Contents/Java/';
    end


    user_data.settings.reflectance_hierarchy_level = 1; % controls the level where the radiance folder is created
    
    user_data.switch_channels_for_rox = true; % set to true if up and downwelling channels were switched during construction

    % this path setting is sufficient on MacOS with Matlab2017b
     javaaddpath ({
         [specchio_pathname 'rome-0.8.jar'],...
         [specchio_pathname 'jettison-1.3.8.jar'],...
         [specchio_pathname 'specchio-client.jar'], ...   
         [specchio_pathname 'specchio-types.jar']});

     import ch.specchio.client.*;
     import ch.specchio.queries.*;
     import ch.specchio.gui.*;
     import ch.specchio.types.*;

     
     % connect to SPECCHIO
     user_data.cf = SPECCHIOClientFactory.getInstance();
     user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
     index = 0;
     user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));
     
     % get spectra ids for this hierarchy
     node = hierarchy_node(hierarchy_id, "", "");
     L_ids = user_data.specchio_client.getSpectrumIdsForNode(node);
     
     % restrict to ROX files
     query = Query('spectrum');
     query.setQueryType(Query.SELECT_QUERY);
     
     query.addColumn('spectrum_id')
     
     
     cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
     cond.setValue(L_ids);
     cond.setOperator('in');
     query.add_condition(cond);
         
     
     cond = SpectrumQueryCondition('spectrum', 'file_format_id');
     file_format_id = user_data.specchio_client.getFileFormatId('RoX');
     cond.setValue(num2str(file_format_id)); 
     cond.setOperator('=');
     query.add_condition(cond);
     
     ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

     
     % order data by spectrum number (this should only ever be a single
     % space ...)
     spaces = user_data.specchio_client.getSpaces(ids, 'Spectrum Number');
     ids = spaces(1).getSpectrumIds();
     space = spaces(1);
     
     % load space
     space = user_data.specchio_client.loadSpace(space);
     spectra = space.getVectorsAsArray();
  
     % get file name vector
     filenames = user_data.specchio_client.getMetaparameterValues(ids, 'File Name');
     
     % select groups of 3 and loop over data
     group_no = ids.size / 3;
     no_of_bands = space.getDimensionality.intValue; % use explicit conversion as for some reason a Java Integer cannot be used to create a matrix with 'ones'.
     
     R = ones(no_of_bands, group_no);
     provenance_spectrum_ids= java.util.ArrayList();
     
     for i=0:group_no-1
         
         group_start = i*3;
         
         group_filenames = filenames.subList(group_start, group_start+3);
         
        % select WR by file name
        WR_pos = false(3,1);
        for j=0:2
            
            filename = java.lang.String(group_filenames.get(j));
            if(filename.contains(java.lang.String('WR')))
               
                WR_pos(j+1) = true; % zero indexed
                
            end
            
        end
        
        WR_indices = false(ids.size, 1);
        TGT_indices = WR_indices;
        WR_indices(group_start+1:group_start+1+2) = WR_pos;
        TGT_indices(group_start+1:group_start+1+2) = ~WR_pos;
        
        % calculate average WR and TGT, but only if there is more than 1
        % spectrum
        WR_arr = spectra(WR_indices, :);
      
        if(sum(WR_indices) > 1)
            WR_avg = mean(WR_arr);
        else
            WR_avg = WR_arr;
        end
        
        % calculate average TGT (just in case the channels were switched)       
        TGT_arr = spectra(TGT_indices, :);
        
        if(sum(TGT_indices) > 1)
            TGT_avg = mean(TGT_arr);
        else
            TGT_avg = TGT_arr;
        end        
        
        
        
        if 1==0
           figure 
           plot(space.getAverageWavelengths(), WR_arr, 'b')
           hold
           plot(space.getAverageWavelengths(), WR_avg, 'r')
           plot(space.getAverageWavelengths(), spectra(TGT_indices, :), 'g')
           
           figure
           plot(space.getAverageWavelengths(), TGT_avg, 'b')
           hold
           plot(space.getAverageWavelengths(), WR_avg, 'r')
           if user_data.switch_channels_for_rox == false
               legend({'TGT', 'WR avg'});
           else
               legend({'WR', 'TGT avg'});
           end
           
        end
        
        % calculate R
        
        if user_data.switch_channels_for_rox == false
            R(:,i+1) = (TGT_avg ./ WR_avg);
        else
            R(:,i+1) = (WR_avg ./ TGT_avg);
        end
        
        if 1==0
           figure 
           plot(space.getAverageWavelengths(), R, 'b')
        end
        
        
        % compile provenance_spectrum_ids: get target id by using
        % TGT_indices logical vector
        provenance_spectrum_ids.add(java.lang.Integer(ids.get(find(TGT_indices, 1) - 1)));
        
        
         
         
     end
     
     if 1==0
         figure
         plot(space.getAverageWavelengths(), R, 'b')
         ylim([0 1]);
     end
     
     % prepare target sub hierarchy
     % get directory of first spectrum
     s = user_data.specchio_client.getSpectrum(provenance_spectrum_ids.get(0), false);  % load first spectrum to get the hierarchy
     current_hierarchy_id = s.getHierarchyLevelId();
     
     % move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
     for i=1:user_data.settings.reflectance_hierarchy_level
         parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
         current_hierarchy_id = parent_id;
     end
     
     campaign = user_data.specchio_client.getCampaign(s.getCampaignId());
     user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId(campaign, 'Reflectance', parent_id);
     
     
     % Insert R   
     insert_reflectances(R, provenance_spectrum_ids, user_data);
     
     
end



function insert_reflectances(R, provenance_spectrum_ids, user_data)
    
    import ch.specchio.types.*;
    new_spectrum_ids = java.util.ArrayList();
    
     if 1==0
         figure
         plot(R, 'b')
         ylim([0 1]);
     end    
    
    
    for i=0:provenance_spectrum_ids.size()-1
        
        % copy the spectrum to new hierarchy
        new_spectrum_id = user_data.specchio_client.copySpectrum(provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);

        % replace spectral data
        user_data.specchio_client.updateSpectrumVector(new_spectrum_id, R(:,i+1));       
        new_spectrum_ids.add(java.lang.Integer(new_spectrum_id));

        disp(',');
    end
    

    
    % change EAV entry to new Processing Level by removing old and inserting new
    attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');
    
    user_data.specchio_client.removeEavMetadata(attribute, new_spectrum_ids, 0);
    
    
    e = MetaParameter.newInstance(attribute);
    e.setValue(2.0);
    user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);
    
    % set unit to reflectance
    
    category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
    R_id = category_values.get('Reflectance');
    user_data.specchio_client.updateSpectraMetadata(new_spectrum_ids, 'measurement_unit', R_id);
    
    
    % set Processing Atttributes
%     processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
%    
%     e = MetaParameter.newInstance(processing_attribute);
%     e.setValue('Radiance calculation in Matlab');
%     user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);
 


end
