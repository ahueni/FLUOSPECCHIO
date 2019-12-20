function hierarchyId = createHierarchy(user_data, name)
hierarchyId = user_data.specchio_client.getSubHierarchyId(user_data.campaign, ...
    name, user_data.parent_id);
end