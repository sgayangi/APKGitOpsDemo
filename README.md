# Customer Data API CI/CD Guide

This guide details the Continuous Integration and Continuous Deployment (CI/CD) artifacts for managing the Customer Data API with WSO2 API Manager Kubernetes Operator (WSO2APK).

## Prerequisites

- A Kubernetes (K8s) Cluster

## Installation Instructions

### Build and Push the Backend Docker Image

1. **Install Ballerina**: Begin by installing Ballerina on your machine.
2. **Check Out the Backend Branch**: Switch to the backend branch in your repository.
3. **Build the Backend Service**: Navigate to the `backendservice` folder and execute the Ballerina build command:
    ```sh
    bal build --cloud=docker
    ```
4. **Push the Docker Image**: Upload the Docker image to your Docker registry.

### Install Backend Service

1. **Create Namespaces**: Generate `backend-dev` and `backend-stage` namespaces with the following commands:
    ```sh
    kubectl create namespace backend-dev
    ```
    ```sh
    kubectl create namespace backend-stage
    ```
2. **Update Docker Image Name**: Modify the docker image name in the `base/backend-deployment.yaml` file to reflect your Docker registry.
3. **Deploy the Backend Service**: Deploy the service to both the `dev` and `stage` namespaces using:
    ```sh
    kubectl apply -k dev/ -n backend-dev
    ```
    ```sh
    kubectl apply -k stage/ -n backend-stage
    ```

### Install APK Environments

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
      helm install wso2apk wso2apk/apk-helm --version=1.0.0 -n apk-dev --values values.yaml
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
      helm install wso2apk wso2apk/apk-helm --version=1.0.0 -n apk-stage --values values.yaml
      ```

### Configure GitHub Actions to Deploy API to Dev and Stage Environments

1. **Fork the Repository**: Fork the repository to your GitHub account.
2. **Configure KUBE_CONFIG**: Set up **KUBE_CONFIG** in GitHub secrets to work with your Kubernetes cluster.

## Tryout

### Deploy the API to the Dev Environment

1. **Test the API**: Send a request to the development environment.
    - Retrieve the dev environment's EXTERNAL-IP address:
      ```console
      kubectl get svc apk-dev-wso2-apk-gateway-service -n apk-dev
      ```
    - Create an `/etc/hosts` entry for the dev environment's EXTERNAL-IP address:
      ```console
      sudo echo "EXTERNAL-IP dev.gw.wso2.com" >> /etc/hosts
      ```
    - Generate a token from the IDP as per the [documentation](https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/).
    - Send a request to the API:
      ```console
      curl --location 'https://dev.gw.wso2.com:9095/greetingAPI/1.0.0/greeting?name=abce' \
      --header 'Authorization: Bearer <accessToken>'
      ```
      You will receive the following response:
      ```
      Hello, abce from dev environment!
      ```

### Deploy the API to the Stage Environment

1. **Test the API**: Send a request to the staging environment.
    - Retrieve the staging environment's EXTERNAL-IP address:
      ```console
      kubectl get svc apk-stage-wso2-apk-gateway-service -n apk-stage
      ```
    - Create an `/etc/hosts` entry for the stage environment's EXTERNAL-IP address:
      ```console
      sudo echo "EXTERNAL-IP stage.gw.wso2.com" >> /etc/hosts
      ```
    - Generate a token from the IDP as outlined in the [documentation](https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/).
    - Send a request to the API:
      ```console
      curl --location 'https://stage.gw.wso2.com:9095/greetingAPI/1.0.0/greeting?name=abce' \
      --header 'Authorization: Bearer <accessToken>'
      ```
      You will receive the following response:
      ```
      Hello, abce from stage environment!
      ```

### Uninstall API from the Dev/Stage Environment

1. Navigate to the Actions section under your forked repository.
2. Select the workflow titled "Uninstall API" to remove the API from the environment.
