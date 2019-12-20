function hierarchyId = createHierarchy(user_data, name, parent_id)
hierarchyId = user_data.specchio_client.getSubHierarchyId(user_data.campaign, ...
    name, parent_id);
end