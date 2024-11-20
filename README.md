# Customer Data API CI/CD Guide

NOTE: This repository is set up to work with APK 1.0.0. For later versions, you may need to update the sample values.yaml files and the CRs provided, along with the workflow files.
Sample CRs for APK 1.2.0 have been added under the CustomerAPI/1.2.0 folder. You can generate the new artifacts following the Quick Start Guide [here](https://apk.docs.wso2.com/en/latest/get-started/quick-start-guide-with-cp/#deploy-the-api-in-apk-dataplane).
The command is:
```
curl --location 'https://api.am.wso2.com:9095/api/configurator/1.2.0/apis/generate-k8s-resources?organization=carbon.super' \
--header 'Content-Type: multipart/form-data' \
--header 'Accept: application/zip' \
--form 'apkConfiguration=@"/Users/user/EmployeeService.apk-conf"' \
--form 'definitionFile=@"/Users/user/EmployeeServiceDefinition.json"' \
-k --output ./api-crds.zip
```

This guide details the Continuous Integration and Continuous Deployment (CI/CD) artifacts for managing the Customer Data API with WSO2 API Manager for Kubernetes (WSO2 APK).

## Prerequisites

- A Kubernetes (K8s) Cluster which can be accessed by your GitOps workflow.

## Installation Instructions

### Build and Push the Backend Docker Image (Optional)

1. **Install Ballerina**: Begin by installing Ballerina on your machine.
2. **Check Out the Backend Branch**: Switch to the backend branch in your repository.
3. **Build the Backend Service**: Navigate to the `backendservice` folder and execute the Ballerina build command:
    ```sh
    bal build --cloud=docker
    ```
4. **Push the Docker Image**: Upload the Docker image to your Docker registry.

### Install Backend Service

There are two backends here - one for the dev environment, and the other for the stage environment. The only difference between the two is the responses returned upon being invoked.

1. **Create Namespaces**: Generate `backend-dev` and `backend-stage` namespaces with the following commands:
    ```sh
    kubectl create namespace backend-dev backend-stage
    ```
2. Go to the "backend" folder in the main branch. It will contain two yaml files - dev-backend.yaml and stage-backend.yaml.
3. **Deploy the Backend Service**: Deploy the service to both the `apk-dev` and `apk-stage` namespaces using:
    ```sh
    kubectl apply -f dev-backend.yaml -n backend-dev
    ```
    ```sh
    kubectl apply -f stage-backend.yaml -n backend-stage
    ```

    This will spin up two backends in the different namespaces.

### Install APK Environments

NOTE: You can still do this demo if you have a single installation of APK, by following the steps relevant to one of the dev or stage environments.

1. **Create APK Namespaces**: Establish `apk-dev` and `apk-stage` namespaces respectively:
    ```sh
    kubectl create namespace apk-dev
    ```
    ```sh
    kubectl create namespace apk-stage
    ```
2. **Add Public Helm Repository**: Add the WSO2APK public helm repository:
    ```sh
    helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.0.0
    ```
    ```sh
    helm repo update
    ```
3. **Install WSO2 APK to apk-dev Namespace**:
    - Create a `values.yaml` file with the following configurations:
      ```yaml
      wso2:
        apk:
          dp:
            adapter:
              configs:
                apiNamespaces:
                  - "apk-dev"
            commonController:
              configs:
                apiNamespaces:
                  - "apk-dev"
      ```
    - Execute the installation command:
      ```sh
      helm install apkdev wso2apk/apk-helm --version=1.0.0 -n apk-dev --values values.yaml
      ```
4. **Install WSO2 APK to apk-stage Namespace**:
    - Prepare a `values.yaml` file with the stage configurations:
      ```yaml
      wso2:
        apk:
          webhooks:
            validatingwebhookconfigurations: true
            mutatingwebhookconfigurations: true
          auth:
            enabled: true
            enableServiceAccountCreation: true
            enableClusterRoleCreation: false
            serviceAccountName: wso2apk-platform
            roleName: wso2apk-role
          dp:
            adapter:
              configs:
                apiNamespaces:
                  - "apk-stage"
            commonController:
              configs:
                apiNamespaces:
                  - "apk-stage"
      gatewaySystem:
        enabled: true
        enableServiceAccountCreation: true
        enableClusterRoleCreation: false
        serviceAccountName: gateway-api-admission

      certmanager:
        enableClusterIssuer: false
      ```
    - Apply the installation command:
      ```sh
      helm install apkstage wso2apk/apk-helm --version=1.0.0 -n apk-stage --values values.yaml
      ```

### Configure GitHub Actions to Deploy API to Dev and Stage Environments

1. **Fork the Repository**: Fork this repository to your GitHub account.
2. **Configure KUBE_CONFIG**: Set up **KUBE_CONFIG** in GitHub secrets to work with your Kubernetes cluster.
    - In your forked repository, under Settings, create a repository secret named "KUBE_CONFIG"
    - The secret should contain the kubeconfig file in YAML format, which includes all necessary information for accessing the cluster.
    - You can follow the documentation here: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_view/
3. Edit your workflow file and update the namespaces as needed.
    - In the dev branch, the workflow file has the namespace as "apk" - you can see this in line 38.
    - Update the namespace required in the workflow file of your forked repository.

## Tryout

### View the workflows

You will be able to see the workflows under the actions tab of your Github repository, as follows.

<img width="381" alt="Screenshot 2024-11-19 at 13 52 49" src="https://github.com/user-attachments/assets/6bfac8e6-fd51-420e-8b31-5974862dc307">

There will be one workflow that runs when a PR is merged to the dev branch, and another that runs when a PR is merged to the stage branch.

### Deploy the API to the Dev Environment

This guide assumes that your namespace is "apk-dev". Update the commands provided below if your namespace is different.
You can now create a Pull Request that has some changes done to the dev branch. The workflow is configured to run whenever a PR is merged to the dev branch.

Once you merge the PR, you will be able to see that the API has been deployed to the apk-dev namespace.

Now, let's do the following.
1. **Test the API**: Send a request to the development environment.
    - Retrieve the dev environment's EXTERNAL-IP address:
      ```console
      kubectl get svc apkdev-wso2-apk-gateway-service -n apk-dev
      ```
    - Create an `/etc/hosts` entry for the dev environment's EXTERNAL-IP address:
      ```console
      sudo echo "EXTERNAL-IP dev.gw.wso2.com" >> /etc/hosts
      ```
    - Generate a token from the IDP as per the [documentation](https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/).
    - Send a request to the API:
      ```console
      curl --location 'https://dev.gw.wso2.com:9095/customers/1.0.0/customers' \
      --header 'Authorization: Bearer <accessToken>'
      ```
      You will receive the following response:
      ```
      {
        "message": "Hello, John! Here are the customers from the dev environment: ",
        "customers": [
            {
                "name": "Test Customer 1",
                "email": "test1@example.com"
            },
            {
                "name": "Test Customer 2",
                "email": "test2@example.com"
            },
            {
                "name": "Test Customer 3",
                "email": "test3@example.com"
            }
        ]
      }
      ```

### Deploy the API to the Stage Environment

You can now create a Pull Request that has some changes done to the stage branch, such as editing a field. The workflow is configured to run whenever a PR is merged to the stage branch.

Once you merge the PR, you will be able to see that the API has been deployed to the apk-stage namespace.

1. **Test the API**: Send a request to the staging environment.
    - Retrieve the staging environment's EXTERNAL-IP address:
      ```console
      kubectl get svc apkstage-wso2-apk-gateway-service -n apk-stage
      ```
    - Create an `/etc/hosts` entry for the stage environment's EXTERNAL-IP address:
      ```console
      sudo echo "EXTERNAL-IP stage.gw.wso2.com" >> /etc/hosts
      ```
    - Generate a token from the IDP as outlined in the [documentation](https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/).
    - Send a request to the API:
      ```console
      curl --location 'https://stage.gw.wso2.com:9095/customers/1.0.0/customers'\
      --header 'Authorization: Bearer <accessToken>'
      ```
      You will receive the following response:
      ```
      {
          "message": "Here are the customers from the staging environment: ",
          "customers": [
              {
                  "name": "Alice Johnson",
                  "email": "alice@mail.com"
              },
              {
                  "name": "Bob Smith",
                  "email": "bob@mail.com"
              },
              {
                  "name": "Charlie Davis",
                  "email": "charlie@mail.com"
              }
          ]
      }
      ```

### Uninstall API from the Dev/Stage Environment

1. Navigate to the Actions section under your forked repository.
2. Select the workflow titled "Uninstall API" to remove the API from the environment.
