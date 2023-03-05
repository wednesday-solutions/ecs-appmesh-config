if [ ! -f "update.app.properties.json" ]; then
echo Error: update.app.properties.json, or app.properties.json File does not exist
exit 1
fi

AWS_ACCESS_KEY_ID=$1

AWS_REGION=$2

if [ ! $AWS_ACCESS_KEY_ID ] || [ ! $AWS_REGION ]; then
echo Error: No AWS Credentials set in the workflow, please verify the actions.
exit 1
fi

echo Starting the update script.
echo
cd_properties_file='update.app.properties.json'

APP_NAME=$(jq -r '.app_name' $cd_properties_file)
ENV_NAME=$(jq -r '.env_name' $cd_properties_file)
APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route1' $cd_properties_file)
APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route2' $cd_properties_file)
SWITCH_LATEST_STABLE_ONCE=$(jq -r '.switchLatestStableOnce' $cd_properties_file)
SWITCH_LATEST_STABLE=$(jq -r '.setLatestStable' $cd_properties_file)
SERVICE1_NAME=$(jq -r '.service1_name' $cd_properties_file)
SERVICE2_NAME=$(jq -r '.service2_name' $cd_properties_file)

if [ ! $APP_NAME ] || [ ! $ENV_NAME ] || [ ! $APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT ] || 
   [ ! $APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT ] || [ ! $SWITCH_LATEST_STABLE_ONCE ] || [ ! $SWITCH_LATEST_STABLE ] || 
   [ ! $SERVICE1_NAME ] || [ ! $SERVICE1_NAME ]; then
echo Error: Please check and verify that all the values in the update.app.properties.json are correctly filled, also please ensure that the values are in correct datatype
exit 1
fi

if [ $SWITCH_LATEST_STABLE_ONCE ]; then
   echo 'Updating Service1 with Service2 latest image, Switch Latest Stable Once'
   # Updating the addons create appmesh services file for service1
   UPDATE_SERVICE_MANIFEST_FILE_PATH=copilot/service1-v1/manifest.yml

   AWS_ECR_SERVICE1_NEW_IMAGE=$AWS_ACCESS_KEY_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME/$SERVICE2_NAME:latest

   yq -i 'del(.image.build)' $UPDATE_SERVICE_MANIFEST_FILE_PATH

   yq -i '.image.location = '$AWS_ECR_SERVICE1_NEW_IMAGE'' $UPDATE_SERVICE_MANIFEST_FILE_PATH

   # Updating the addons create appmesh services file for service1
   UPDATE_APP_MESH_SERVICES_FILE_PATH=copilot/service1-v1/addons/3-create-services.yml

   # Virtual Route traffic routing
   yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[0].Weight =    '$APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

   yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[1].Weight = '$APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

   echo Deploying the services
   echo
   echo Deploying Service1 with Service2 image
   copilot deploy --name service1-v1 -e "$ENV_NAME"
   echo
   echo Deployed Service 1
   echo
   echo Deploying Service2 with latest build
   echo
   copilot deploy --name service1-v2 -e "$ENV_NAME"
   echo Deployed Service 2
   echo
   echo App Deployed.
   echo
   echo Updating app properties
   yq -i '.switchLatestStableOnce=false' ./update.app.properties.json -o json
   echo
   echo File updated
   exit 0
elif [[ $USER_INPUT -gt 0 && $USER_INPUT -lt 10 ]]; then
   echo "Valid 1 digit number entered"

echo 'Not here.'
# Updating the addons create appmesh services file for service1
UPDATE_APP_MESH_SERVICES_FILE_PATH=copilot/service1-v1/addons/3-create-services.yml

# Virtual Route traffic routing
yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[0].Weight = '$APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[1].Weight = '$APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

echo Deploying the app
echo
copilot deploy --name service1-v1 -e "$ENV_NAME"
echo App Deployed.