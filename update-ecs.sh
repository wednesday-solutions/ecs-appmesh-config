if [ ! -f "update.app.properties.json" ]; then
echo Error: update.app.properties.json, or app.properties.json File does not exist
exit 1
fi

echo Starting the update script.
echo
cd_properties_file='update.app.properties.json'

APP_NAME=$(jq -r '.app_name' $cd_properties_file)
ENV_NAME=$(jq -r '.env_name' $cd_properties_file)
APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route1' $cd_properties_file)
APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route2' $cd_properties_file)

if [ ! $APP_NAME ] || [ ! $ENV_NAME ] || [ ! $APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT ] || 
   [ ! $APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT ]; then
echo Error: Please check and verify that all the values in the update.app.properties.json are correctly filled, also please ensure that the values are in correct datatype
exit 1
fi

# Updating the addons create appmesh services file for service1
UPDATE_APP_MESH_SERVICES_FILE_PATH=copilot/service1-v1/addons/3-create-services.yml

# Virtual Route traffic routing
yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[0].Weight = '$APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[1].Weight = '$APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

echo Deploying the app
echo
copilot deploy --name service1-v1 -e "$ENV_NAME"
echo App Deployed.