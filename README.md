# App Mesh and ECS 
## Table of contents
* [Prerequisites](#prerequisites)
* [Install Dependencies](#install-dependencies)
* [Adding .env files](#add-env-to-packages)
* [Starting the projects locally with lerna](#start-both-the-projects-locally-with)
* [Deploying on ECS and AppMesh](#deploy-the-app-on-ecs-and-appmesh)
#
## Prerequisites:
Please make sure you have the following tools installed in your system:
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
So Let's move forward.

#
## Setting up the repo:
- Run the folling command to setup the repo `./scripts/init.sh`
#
## Starting locally:
- Use `lerna run start:local` to run server locally in the packages directory.
#
## Deploy the app on ECS and AppMesh:
Please follow these steps to deploy the services on AWS ECS and AWS AppMesh.
- Please take a look at [Prerequisites](#prerequisites) and make sure that you have the tools installed and configured.
- Make sure you have `.env.production` environment file available in the packages, as this file is used by docker to build the image.
- **Important:** Use the following command to create app.properties.json file\
 `cp app.properties.example.json app.properties.json`
- Update all the variables in app.properties.json file.
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
        - Create a User Group named Administrators. Set the AdministratorAccess permission policy.
        - Navigate to the Users tab and add a new user with username Administrator.
        - Select the AWS Credential Type as Access Key - Programmatic access.
        - Add the user to the Administrators group.
        - Save the **access token ID** and the **secret access key**.
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

#
## Curious about how this magic is happening, what architecure it will setup? Here's what and how.
![Architecure.png](AppMesh.png)
