if [ ! -f "app.properties.json" ]; 
then
echo Error: app.properties.json File does not exist
exit 1
fi

file_name='app.properties.json'

# ECS Config
APP_NAME=$(jq -r '.app_name' $file_name)
ENV_NAME=$(jq -r '.env_name' $file_name)
AWS_REGION=$(jq -r '.aws_region' $file_name)
ENVOY_IMAGE=840364872350.dkr.ecr.$AWS_REGION.amazonaws.com/aws-appmesh-envoy:v1.25.1.0-prod
CLOUDMAP_NAMESPACE=$ENV_NAME.$APP_NAME.local # dev.app-mesh-final.local

# Service 1
SERVICE1_NAME=$(jq -r '.service1_name' $file_name)
SERVICE1_PORT=$(jq -r '.service1_port' $file_name)
SERVICE1_DOCKER_IMAGE_PATH=$(jq -r '.service1_docker_image_path' $file_name)
SERVICE1_DNS_DISCOVERY_ENDPOINT=$SERVICE1_NAME.$ENV_NAME.$APP_NAME.local

# Service 2
SERVICE2_NAME=$(jq -r '.service2_name' $file_name)
SERVICE2_DNS_DISCOVERY_ENDPOINT=$SERVICE2_NAME.$ENV_NAME.$APP_NAME.local

# AppMesh config
MESH_NAME=$(jq -r '.app_mesh_name' $file_name)
TRAFFIC_VIRTUAL_NODE1=$(jq -r '.traffic_weight_route1' $file_name)
TRAFFIC_VIRTUAL_NODE2=$(jq -r '.traffic_weight_route2' $file_name)

if [ ! $APP_NAME ] || [ ! $ENV_NAME ] || [ ! $ENVOY_IMAGE ] || [ ! $CLOUDMAP_NAMESPACE ] || [ ! $SERVICE1_NAME ] || [ ! $SERVICE1_PORT ] || 
   [ ! $SERVICE1_DOCKER_IMAGE_PATH ] || [ ! $SERVICE1_DNS_DISCOVERY_ENDPOINT ] || [ ! $SERVICE2_NAME ] ||  
   [ ! $SERVICE2_DNS_DISCOVERY_ENDPOINT ] || [ ! $MESH_NAME ] || [ ! $TRAFFIC_VIRTUAL_NODE2 ] ||  
   [ ! $TRAFFIC_VIRTUAL_NODE1 ]; then
echo Error: Please check and verify that all the values in the app.properties.json are correctly filled, also please ensure that the values are in correct datatype
exit 1
fi

# Virtual Gateway
APPMESH_VIRTUAL_GATEWAY_NAME=$MESH_NAME-virtual-gateway
APPMESH_VIRTUAL_GATEWAY_PORT=9080
APPMESH_VIRTUAL_GATEWAY_ROUTE_NAME=$APPMESH_VIRTUAL_GATEWAY_NAME-route
APPMESH_VIRTUAL_GATEWAY_ROUTE_PREFIX='/'
APPMESH_VIRTUAL_NODE_NAME_ENV_GATEWAY_SERVICE=mesh/$MESH_NAME/virtualGateway/$APPMESH_VIRTUAL_GATEWAY_NAME

# Service1v1 (NODE1 represents service1 version 1)
APPMESH_SERVICE_VIRTUAL_NODE1_NAME=$MESH_NAME-$SERVICE1_NAME-vn-1
APPMESH_SERVICE_VIRTUAL_NODE1_PORT=$SERVICE1_PORT
APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT=$TRAFFIC_VIRTUAL_NODE1
APPMESH_SERVICE_NODE1_ENV_NODE_NAME=mesh/$MESH_NAME/virtualNode/$APPMESH_SERVICE_VIRTUAL_NODE1_NAME

# Service1v2 (NODE2 represents service1 version 2)
APPMESH_SERVICE_VIRTUAL_NODE2_NAME=$MESH_NAME-$SERVICE2_NAME-vn-2
APPMESH_SERVICE_VIRTUAL_NODE2_PORT=$SERVICE1_PORT
APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT=$TRAFFIC_VIRTUAL_NODE2
APPMESH_SERVICE_NODE2_ENV_NODE_NAME=mesh/$MESH_NAME/virtualNode/$APPMESH_SERVICE_VIRTUAL_NODE2_NAME

# Virtual Service
APPMESH_SERVICE_VIRTUAL_SERVICE_NAME=$SERVICE1_NAME.$ENV_NAME-$APP_NAME.local
APPMESH_SERVICE_VIRTUAL_ROUTER_NAME=$MESH_NAME-virtual-router
APPMESH_SERVICE_VIRTUAL_ROUTE_NAME=$MESH_NAME-virtual-route

echo 
echo "Initializing Copilot app!! Please answer the questions if asked any."
echo "If asked, Would you like to deploy a test environment? Please answer No!"
echo 

copilot init --app $APP_NAME --name $SERVICE1_NAME --type "Backend Service" --dockerfile $SERVICE1_DOCKER_IMAGE_PATH 

rm -rf copilot/$SERVICE1_NAME/manifest.yml

cp -R copilot-addons-ref/service1v1/ copilot/$SERVICE1_NAME/


# Updating the Manifest file for service1
SERVICE1_MANIFEST_FILE_PATH=copilot/$SERVICE1_NAME/manifest.yml

yq -i '.name = "'$SERVICE1_NAME'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.image.build = "'$SERVICE1_DOCKER_IMAGE_PATH'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.image.port = '$SERVICE1_PORT'' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.serviceDiscovery.awsCloudMap.namespace = "'$CLOUDMAP_NAMESPACE'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.serviceDiscovery.awsCloudMap.name = "'$SERVICE1_NAME'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.sidecars.envoy.image = "'$ENVOY_IMAGE'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.sidecars.envoy.variables.APPMESH_VIRTUAL_NODE_NAME = "'$APPMESH_SERVICE_NODE1_ENV_NODE_NAME'"' $SERVICE1_MANIFEST_FILE_PATH

yq -i '.variables.APPMESH_VIRTUAL_NODE_NAME = "'$APPMESH_SERVICE_NODE1_ENV_NODE_NAME'"' $SERVICE1_MANIFEST_FILE_PATH

# Updating the addons AppMesh Gateway route file for service1
VIRTUAL_GATEWAY_FILE_PATH=copilot/$SERVICE1_NAME/addons/4-appmesh-gateway-route.yml

yq -i '.Resources.AppMeshVirtualGateway.Properties.VirtualGatewayName = "'$APPMESH_VIRTUAL_GATEWAY_NAME'"' $VIRTUAL_GATEWAY_FILE_PATH

yq -i '.Resources.Service1GatewayRoute.Properties.MeshName = "'$MESH_NAME'"' $VIRTUAL_GATEWAY_FILE_PATH

yq -i '.Resources.Service1GatewayRoute.Properties.VirtualGatewayName = "'$APPMESH_VIRTUAL_GATEWAY_NAME'"' $VIRTUAL_GATEWAY_FILE_PATH

yq -i '.Resources.Service1GatewayRoute.Properties.GatewayRouteName = "'$APPMESH_VIRTUAL_GATEWAY_ROUTE_NAME'"' $VIRTUAL_GATEWAY_FILE_PATH

yq -i '.Resources.Service1GatewayRoute.Properties.Spec.HttpRoute.Match.Prefix = "'$APPMESH_VIRTUAL_GATEWAY_ROUTE_PREFIX'"' $VIRTUAL_GATEWAY_FILE_PATH

# Updating the addons create AppMesh file for service1
CREATE_APP_MESH_FILE_PATH=copilot/$SERVICE1_NAME/addons/2-create-appmesh.yml

yq -i '.Resources.Mesh.Properties.MeshName = "'$MESH_NAME'"' $CREATE_APP_MESH_FILE_PATH

# Updating the addons create appmesh services file for service1
CREATE_APP_MESH_SERVICES_FILE_PATH=copilot/$SERVICE1_NAME/addons/3-create-services.yml

# Virtual Node 1
yq -i '.Resources.Service1v1VirtualNode.Properties.VirtualNodeName = "'$APPMESH_SERVICE_VIRTUAL_NODE1_NAME'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1v1VirtualNode.Properties.Spec.Listeners[0].PortMapping.Port = '$APPMESH_SERVICE_VIRTUAL_NODE1_PORT'' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1v1VirtualNode.Properties.Spec.ServiceDiscovery.DNS.Hostname = "'$SERVICE1_DNS_DISCOVERY_ENDPOINT'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

#Virtual Node 2
yq -i '.Resources.Service1v2VirtualNode.Properties.VirtualNodeName = "'$APPMESH_SERVICE_VIRTUAL_NODE2_NAME'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1v2VirtualNode.Properties.Spec.Listeners[0].PortMapping.Port = '$APPMESH_SERVICE_VIRTUAL_NODE2_PORT'' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1v2VirtualNode.Properties.Spec.ServiceDiscovery.DNS.Hostname = "'$SERVICE2_DNS_DISCOVERY_ENDPOINT'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

# Virtual Service
yq -i '.Resources.Service1VirtualService.Properties.VirtualServiceName = "'$APPMESH_SERVICE_VIRTUAL_SERVICE_NAME'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

# Virtual Router
yq -i '.Resources.Service1VirtualRouter.Properties.VirtualRouterName = "'$APPMESH_SERVICE_VIRTUAL_ROUTER_NAME'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

# Virtual Route
yq -i '.Resources.Service1Route.Properties.RouteName = "'$APPMESH_SERVICE_VIRTUAL_ROUTE_NAME'"' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[0].Weight = '$APPMESH_SERVICE_NODE1_TRAFFIC_WEIGHT'' $CREATE_APP_MESH_SERVICES_FILE_PATH

yq -i '.Resources.Service1Route.Properties.Spec.HttpRoute.Action.WeightedTargets[1].Weight = '$APPMESH_SERVICE_NODE2_TRAFFIC_WEIGHT'' $CREATE_APP_MESH_SERVICES_FILE_PATH

echo "Initializing Environment $ENV_NAME"

sleep 2.0
# Initializing env
copilot env init --name $ENV_NAME --profile default --app $APP_NAME --default-config
echo
echo "Deploying Environment"
echo
sleep 2.0
# Deploying Environment
copilot env deploy --name $ENV_NAME
echo
echo "Environment $ENV_NAME is now deployed."
# Deploying service 1
echo
echo "Deploying Service $SERVICE1_NAME, and architecture."
sleep 2.0
echo
copilot svc deploy --name $SERVICE1_NAME --env $ENV_NAME
echo "Deployed Service"
echo
# Initializing new service
echo "Initializing service $SERVICE2_NAME"
copilot svc init --name $SERVICE2_NAME --svc-type "Backend Service" --dockerfile $SERVICE1_DOCKER_IMAGE_PATH
echo
rm -rf copilot/$SERVICE2_NAME/manifest.yml

cp -R copilot-addons-ref/service1v2/ copilot/$SERVICE2_NAME/


# Updating the Manifest file for service2
SERVICE2_MANIFEST_FILE_PATH=copilot/$SERVICE2_NAME/manifest.yml

yq -i '.name = "'$SERVICE2_NAME'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.image.build = "'$SERVICE1_DOCKER_IMAGE_PATH'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.image.port = '$SERVICE1_PORT'' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.serviceDiscovery.awsCloudMap.namespace = "'$CLOUDMAP_NAMESPACE'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.serviceDiscovery.awsCloudMap.name = "'$SERVICE2_NAME'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.sidecars.envoy.image = "'$ENVOY_IMAGE'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.sidecars.envoy.variables.APPMESH_VIRTUAL_NODE_NAME = "'$APPMESH_SERVICE_NODE2_ENV_NODE_NAME'"' $SERVICE2_MANIFEST_FILE_PATH

yq -i '.variables.APPMESH_VIRTUAL_NODE_NAME = "'$APPMESH_SERVICE_NODE2_ENV_NODE_NAME'"' $SERVICE2_MANIFEST_FILE_PATH

# Deploying new service
echo "Deploying Service $SERVICE2_NAME"

copilot svc deploy --name $SERVICE2_NAME --env $ENV_NAME

echo 
echo Service $SERVICE2_NAME deployed.

echo Deploying Gateway service.

# Service Gateway
SERVICE_GATEWAY_FILE_PATH=copilot/service-gateway/manifest.yml

cp -R copilot-addons-ref/service-gateway/ copilot/service-gateway/

copilot svc init --name service-gateway

yq -i '.variables.APPMESH_VIRTUAL_NODE_NAME = "'$APPMESH_VIRTUAL_NODE_NAME_ENV_GATEWAY_SERVICE'"' $SERVICE_GATEWAY_FILE_PATH

yq -i '.image.location = "'$ENVOY_IMAGE'"' $SERVICE_GATEWAY_FILE_PATH

yq -i '.serviceDiscovery.awsCloudMap.namespace = "'$CLOUDMAP_NAMESPACE'"' $SERVICE_GATEWAY_FILE_PATH
# Deploying Service Gateway
echo
echo Deploying service-gateway
copilot svc deploy --name service-gateway --env $ENV_NAME
echo Service-Gateway Deployed, please use above URL to verify the deployment.