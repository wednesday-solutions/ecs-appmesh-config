# App Mesh and ECS
## Architecture.
![Architecure.png](AppMesh.png)
#
## Table of contents
* [Prerequisites](#prerequisites)
* [App properties (important to check)](#app-properties)
* [Setting up the repo](#setting-up-the-repo)
* [Starting locally](#starting-locally)
* [Deploy the app on ECS and AppMesh](#deploy-the-app-on-ecs-and-appmesh)
* [Continuous deployment](#continuous-deployment)
* [AWS AppMesh Pricing](#aws-appmesh-pricing)
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


**AWS tools**: If you do not have aws-cli and aws copilot already installed, or you don't know about these tools, don't worry, we've got you covered. \
Please follow this tutorial: [How to Use AWS Copilot](https://www.wednesday.is/writing-tutorials/aws-copilot). This tutorial will give you an understanding of how to setup AWS Copilot, and configure aws-cli and also will help you deploy services on ECS, after which it would be quite easy for you to set up and deploy services on AWS ECS in minutes. It will also help you follow along with this guide. 


**Other tools**:  To install the other mentioned tools, I am adding their documentation where you can download and install the tools:\
a) [docker](https://docs.docker.com/engine/install/)\
b) [nodejs](https://nodejs.org/en/download/)\
c) [yarn](https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable)\
d) [lerna](https://lerna.js.org/)


**Note**: **Please check your copilot version is atleast 1.25.0 or greater.** \
Assuming you have all the tools mentioned above installed and configured,\
So let's move forward and see what all properties are needed for app to work and what do they mean.
#

## App properties:
- **app_name (string)**:\
App Name is used to initialise an app with AWS Copilot.
- **env_name (string)**:\
The environment name is used by AWS Copilot to initialise and deploy an environment on AWS.
- **aws_region (string)**:\
AWS Region is used to specify in what region you want to deploy the application; this key is useful to select the Envoy Proxy image region.
- **service1_name (string)**:\
Service1 Name is used as the service name for the first service in the cluster deployed by AWS Copilot.
- **service1_port (number)**:\
Specify at which port the service1 is running; make sure you have exposed the same port from the Dockerfile.
- **service1_docker_image_path (string)**:\
Specify the path to the Dockerfile for service1.
- **service2_name (string)**:\
Service2 Name is used as the service name for the second service in the cluster deployed by AWS Copilot.
- **app_mesh_name (string)**:\
The app_mesh_name is used to create a mesh with the app_mesh_name.
- **traffic_weight_route1 (number)**:\
Defines what percentage of traffic we want service1 to handle in the canary deployment rollout. The default is 50.
- **traffic_weight_route2 (number)**:\
Defines what percentage of traffic we want service2 to handle in the canary deployment rollout. The default is 50.
- **setLatestStableOnce (string)**:\
This key is utilised in CD workflow; it is responsible for switching images; when enabled, the image from service2 will be used in service1, and service2 will be rebuilt with the latest updated features. As the name suggests, `once` will set the value for the key back to **false if enabled** as this was supposed to run only once.
- **setLatestStable (string)**:\
This key is utilised in CD workflow; it is responsible for switching images; when enabled, the image from service 2 will be used in service 1, and service 2 will be rebuilt with the latest updated features. This will be progressive, as this will not stop after one deployment; this will continue until you set this key to `false` in `the app.properties.json` file.


## Setting up the repo:
- Run the following command to setup the repo: `./scripts/init.sh`
#
## Starting locally:
- Use `lerna run start:local` to run the server locally in the packages directory.
#
## Deploy the app on ECS and AppMesh:
Please follow these steps to deploy the services on AWS ECS and AWS AppMesh.
- Please take a look at [Prerequisites](#prerequisites) and make sure that you have the tools installed and configured.
- If you want, please update the variables in the app.properties.json file with your custom properties; otherwise, it will use default properties.
- To get Envoy Image for your particular region, check here: [Envoy Image](https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html).
- Please provide a relative path for the Docker file and make sure you have the port exposed from the Docker file.
- Value of the service name must start with a letter, contain only lower-case letters, numbers, and hyphens, and have no consecutive or trailing hyphen.
- run the `./scripts/deploy.sh` script and let the magic happen.
#
## Continuous deployment
For Continuous deployment, we are using GitHub actions. For making the CD work with the repository, please follow the following steps:
- Go through the steps in the tutorial, [Guide to Deploying Your App to ECS with Github Actions](https://www.wednesday.is/writing-tutorials/deploy-to-ecs-github-actions). Going through the tutorial will help you understand what generally happens under the hood when we use CD on ECS.
- Add secrets to the GitHub repo [Add Secrets](https://www.wednesday.is/writing-tutorials/deploy-to-ecs-github-actions#toc-2), we need to add the following secret variables to the GitHub repo to make our CD pipeline work.
    - AWS_ACCESS_KEY_ID
    - AWS_REGION
    - AWS_SECRET_ACCESS_KEY
    - PAT
- To get the values for above mention keys check the following docs:
    - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
        - Login to your AWS console.
        - On top right corner, you should get something like `"username @ AccountId"`, click on it.
        - Click on Security credentials
        - In AWS IAM Credentials, go to the Access Keys section, and click on Create access key.
        - Click on `Command Line Interface (CLI)`.
        - Click on `I understand the above recommendation and want to proceed to create an access key.` checkbox, and click Next.
        - On the next page, you will get a page saying, "Set description tag". Add some description if you want to (It's good to add a description of why you are creating a key), and click Create access key.
        - Save the **Access key** and the **Secret access key**.
        - Please make sure you read the **`Access Key Best Practices.
    - AWS_REGION:
        - Provide the name of the region where the app is deployed.
    - PAT (Personal Access Token):
        - Go to GitHub [settings](https://github.com/settings/profile).
        - Go to developer settings.
        - Click on the Personal Access Token.
        - Click on tokens (classic)
        - Click on Generate new token, then Generate new token (classic).
        - Give all the access to the Personal Access Token.
        - Once you have set up the secrets, you are good to go.
- **Things to remember when working with the CD**:
    - Please make sure you check the `app.properties.json` file to verify properties before every deployment.
    - Make sure you only change values like `traffic_weight_route1`, `traffic_weight_route2`, `setLatestStableOnce`, and `setLatestStable`. If you change other values when running CD, the deployment will fail.
    - When `setLatestStableOnce` is enabled, please make sure that you take the latest pull after the deployment is done as this key will be set to false.
    - When `setLatestStable` is enabled, it will switch images from service 2 to service 1, and the latest features will be deployed in service 2. **Make sure to disable this key if you do not want to switch the images**.
    - If both the `setLatestStable` and `setLatestStableOnce` keys are disabled, the only thing that will change is the traffic between the services according to the values in the keys `traffic_weight_route1` and `traffic_weight_route2`.
#

## AWS AppMesh Pricing:
App Mesh is a free managed service, meaning there are no costs associated with managing App Mesh resources. However, as we are utilizing AWS ECS to deploy our applications on Fargate, Fargate resources will incur costs.

When introducing AppMesh, we need to run the Envoy proxy sidecar container in addition to our application container. This is similar to running any sidecars such as xray, cloudwatch, etc. containers. In our task, you will have to allocate +0.25 vCPU & +0.5 GB memory to account for the Envoy container. Therefore, there will be an additional cost of running your application in the App Mesh service mesh.

For Virtual Gateway, we will not be running an application but a dedicated Envoy container as a whole. If we allocate 2 vCPU & 1 GB memory for Virtual Gateway Envoy, we will have to bear the Fargate cost of running those tasks.

Therefore, I will provide you with an estimate of running the above architecture on AWS. Let's breakdown the services and the cost of running them.

We will consider the following architecture in the **Asia Pacific (Mumbai)** region, using the following specifications:
- Operating system (Linux)
- CPU Architecture (x86)
- Average duration (24 hours) **(duration is calculated from the time you start to download your container image until the Task or Pod terminates, rounded up to the nearest second)**
- Number of tasks or pods (3 per day)
- Amount of memory allocated for each task or pod (1 GB)
- Amount of ephemeral storage allocated for Amazon ECS (20 GB) **(the first 20 GB are at no additional charge, you only pay for any additional storage that you configure for the Task)**

Since we are running 3 services and 1 task in each service, the number of tasks is 3. Out of 3 services, 2 services contain an application, i.e service1v1 (stable version) and service1v2 (latest build), and 1 service is responsible for running the AWS App Mesh Virtual Gateway Envoy proxy. Therefore, the cost of running these services is around **56.79 USD/month** and **681.48 USD/year**, which includes upfront costs.

Note: **The cost of running these services may vary from region to region.**