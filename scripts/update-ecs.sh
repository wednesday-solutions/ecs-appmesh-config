if [ ! -f "app.properties.json" ]; then
echo Error: app.properties.json, or app.properties.json File does not exist
exit 1
fi

AWS_REGION=$1

if [ ! $AWS_REGION ]; then
echo Error: No AWS region set in the workflow, please verify the actions.
exit 1
fi

export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo Starting the update script.
echo
cd_properties_file='app.properties.json'

APP_NAME=$(jq -r '.app_name' $cd_properties_file)
ENV_NAME=$(jq -r '.env_name' $cd_properties_file)
APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route1' $cd_properties_file)
APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT=$(jq -r '.traffic_weight_route2' $cd_properties_file)
SWITCH_LATEST_STABLE_ONCE=$(jq -r '.setLatestStableOnce' $cd_properties_file)
SWITCH_LATEST_STABLE=$(jq -r '.setLatestStable' $cd_properties_file)
SERVICE1_NAME=$(jq -r '.service1_name' $cd_properties_file)
SERVICE2_NAME=$(jq -r '.service2_name' $cd_properties_file)

if [ ! $APP_NAME ] || [ ! $ENV_NAME ] || [ ! $APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT ] || 
   [ ! $APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT ] || [ ! $SWITCH_LATEST_STABLE_ONCE ] || [ ! $SWITCH_LATEST_STABLE ] || 
   [ ! $SERVICE1_NAME ] || [ ! $SERVICE1_NAME ]; then
echo Error: Please check and verify that all the values in the app.properties.json are correctly filled, also please ensure that the values are in correct datatype
exit 1
fi

if $SWITCH_LATEST_STABLE_ONCE || $SWITCH_LATEST_STABLE; then
   echo 'Updating Service1 with Service2 latest image, Switch Latest Stable Once'
   # Updating the addons create appmesh services file for service1
   UPDATE_SERVICE_MANIFEST_FILE_PATH=copilot/service1-v1/manifest.yml

   AWS_ECR_SERVICE1_NEW_IMAGE=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME/$SERVICE2_NAME:latest

   yq -i 'del(.image.build)' $UPDATE_SERVICE_MANIFEST_FILE_PATH

   yq -i '.image.location = "'$AWS_ECR_SERVICE1_NEW_IMAGE'"' $UPDATE_SERVICE_MANIFEST_FILE_PATH

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
   if $SWITCH_LATEST_STABLE_ONCE; then
      echo Updating app properties
      yq -i '.setLatestStableOnce=false' ./app.properties.json -o json
      echo
      echo File updated
   fi
else
   # Virtual Route traffic routing
   UPDATE_APP_MESH_SERVICES_FILE_PATH=copilot/service1-v1/addons/3-create-services.yml
   
   yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[0].Weight =    '$APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

   yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[1].Weight = '$APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT'' $UPDATE_APP_MESH_SERVICES_FILE_PATH

   echo Routing traffic between services
   echo
   copilot deploy --name service1-v1 -e "$ENV_NAME"
   echo App Deployed.
   echo
fi
