# App Mesh and ECS 
## Architecture.
![Architecure.png](AppMesh.png)
#
## Table of contents
* [Prerequisites](#prerequisites)
* [App properties (Important to check)](#app-properties)
* [Install Dependencies](#install-dependencies)
* [Adding .env files](#add-env-to-packages)
* [Starting the projects locally with lerna](#start-both-the-projects-locally-with)
* [Deploying on ECS and AppMesh](#deploy-the-app-on-ecs-and-appmesh)
#
## Prerequisites:
Please make sure you have the following tools installed in your system:
- aws account
- aws cli
- aws copilot **(v1.25.0 and above)**
- docker
- nodejs
- yarn
- lerna

**AWS tools**: If you do not have aws-cli and aws copilot already installed, or you don't know about these tools, don't worry we got you covered. \
Please follow this tutorial [How to Use AWS Copilot](https://www.wednesday.is/writing-tutorials/aws-copilot). This tutorial will give you an understanding of how to setup AWS Copilot, and configure aws-cli and also will help you deploy services on ECS, after which it would be quite easy for you to set up and deploy services on AWS ECS in minutes, and will also help you follow along this guide.\

**Other tools**: To install other mentioned tools I am adding their documentation where you can download and install the tools:\
a) [docker](https://docs.docker.com/engine/install/)\
b) [nodejs](https://nodejs.org/en/download/)\
c) [yarn](https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable)\
d) [lerna](https://lerna.js.org/)

Assuming you have all the tools mentioned above installed and configured.\
**Please check your copilot version is atleast 1.25.0 or greater.** \
So Let's move forward and see what all properties are needed for app to work and what do they mean.
#

## App properties:
- **app_name (string)**:\
App Name is used to initialize an app with aws copilot.
- **env_name (string)**:\
Environment name is used by aws copilot to initailize and deploy an environment on AWS.
- **aws_region (string)**:\
AWS Region is used to specify on what region you want to deploy the application, this key is useful to select the Envoy Proxy image region.
- **service1_name (string)**:\
Service1 Name is used as a service name for first service in the cluster deployed by AWS Copilot.
- **service1_port (number)**:\
Specify at which port the service1 is running, make sure you have exposed the same port from the Dockerfile.
- **service1_docker_image_path (string)**:\
Specify the path to Dockerfile for service1.
- **service2_name (string)**:\
Service2 Name is used as a service name for second service in the cluster deployed by AWS Copilot.
- **app_mesh_name (string)**:\
App Mesh name is used to create a Mesh with the app_mesh_name.
- **traffic_weight_route1 (number)**:\
Defines what percentage of traffic we want to service1 to handle in canary deployments rollout. Default is 50.  
- **traffic_weight_route2 (number)**:\
Defines what percentage of traffic we want to service2 to handle in canary deployments rollout. Default is 50.
- **setLatestStableOnce (string)**:\
This key is utilized in CD workflow, it is responsible for switching images, when enabled the image from service2 will be used in service1 and the service2 will be rebuilt with the latest updated features, as the name suggest `once` this will set the value for the key back to **false if enabled** as this was supposed to run only once. 
- **setLatestStable (string)**:\
This key is utilized in CD workflow, it is responsible for switching images, when enabled the image from service2 will be used in service1 and the service2 will be rebuilt with the latest updated features. This will be progressive as this will not stop after one deployment, this will continue until you set this key to `false` in `the app.properties.json` file.

## Setting up the repo:
- Run the folling command to setup the repo `./scripts/init.sh`
#
## Starting locally:
- Use `lerna run start:local` to run server locally in the packages directory.
#
## Deploy the app on ECS and AppMesh:
Please follow these steps to deploy the services on AWS ECS and AWS AppMesh.
- Please take a look at [Prerequisites](#prerequisites) and make sure that you have the tools installed and configured.
- If you want please update the variables in app.properties.json file with your custom properties or it will use default properties.
    - To get Envoy Image for your particular region check here [Envoy Image](https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html).
    - Please provide a relative path for the docker file and make sure you have the port exposed from the docker file.  
    - Value for service name must start with a letter, contain only lower-case letters, numbers, and hyphens, and have no consecutive or trailing hyphen.
- run the `./scripts/deploy.sh` script and let the magic happen.
#
## Continuous deployment
For Continuous deployment we are using GitHub actions. For making the CD work with the repo please follow the following steps:
- Go through steps in the tutorial [Guide to Deploying Your App to ECS with Github Actions](https://www.wednesday.is/writing-tutorials/deploy-to-ecs-github-actions). Going through the tutorial will help you understand what generally happens under the hood when we use CD on ECS.
- Add secrets in the GitHub repo [Add Secrets](https://www.wednesday.is/writing-tutorials/deploy-to-ecs-github-actions#toc-2), we need to add the following secret variables in the GitHub repo to make our CD pipeline work.
    - AWS_ACCESS_KEY_ID
    - AWS_REGION
    - AWS_SECRET_ACCESS_KEY
    - PAT
- To get the values for above mention keys check the following docs:
    - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
        - Login to your AWS console
        - On top right corner you should get something like : `username @ AccountId`, click on it.
        - Click on Security credentials
        - In AWS IAM Credentials, go to Access keys section, and click on Create access key.
        - Click on `Command Line Interface (CLI)`.
        - Click on `I understand the above recommendation and want to proceed to create an access key.` checkbox, and click Next.
        - On the next page you will get a page saying, Set description tag, it's good to add description for what purpose you are creating a key. Add some description if you want to and click Create access key.
        - Save the **Access key** and the **Secret access key**.
        - Please make sure you read the **`Access key best practices`**.
    - AWS_REGION:
        - Provide the region name where the app is deployed.
    - PAT (Personal Access Token):
        - Go to GitHub [settings](https://github.com/settings/profile).
        - Go to developer settings.
        - Click on Personal Access Token.
        - Click on tokens (classic)
        - Click on Generate new token, then Generate new token (classic).
        - Give all the access to the Personal Access Token.
- Once you have setup the secrets you are good to go.
- **Things to remember when working with the CD**:
    - Please make sure you check the `app.properties.json` file to verify properties before every deploymeny.
    - Make sure you only change values like `traffic_weight_route1`, `traffic_weight_route2`, `setLatestStableOnce`, `setLatestStable`. If you change other values when running CD, the deployment will fail.
    - When `setLatestStableOnce` is enabled, please make sure that you take the latest pull after the deployment is done as this key will be set to false.
    - When `setLatestStable` is enabled it will switch images from service2 to service1 and the latest features will be deployed in version2. **Make sure to disable this key if you do not want to switch the images**.
    - If both the `setLatestStable` and `setLatestStableOnce` keys are disabled the only thing that will change is the traffic between the services according to the values in keys `traffic_weight_route1` and `traffic_weight_route2`.
#

