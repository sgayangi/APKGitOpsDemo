# Customer Data API CI-CD
This repository contains the CI-CD Artifacts for [WSO2APK](https://apk.docs.wso2.com/en/latest/)

# Prerequisites
K8s Cluster

Installations
# Build and push the Backend Docker image.
1. Install ballerina.
2. Check out the backend branch.
3. Build the backendservice folder using Ballerina.
    ```
    bal build --cloud=docker
    ```
4. Push the docker image into your docker registry.

# Install Backend Service.
1. Create backend-dev and backend-stage namespaces respectively.
    ```
    kubectl create namespace backend-dev
    kubectl create namespace backend-stage
    ```
2. Change the docker image name in the base/backend-deployment.yaml file.
3. Deploy the backend service to dev and stage namespaces.
    ```
    kubectl apply -k k8s-resources/dev/ -n backend-dev
    kubectl apply -k k8s-resources/stage/ -n backend-stage
    ```
# Install APK Environments.
1. Create apk-dev and apk-stage namespaces respectively.
    ```sh
    kubectl create namespace apk-dev
    kubectl create namespace apk-stage
    ```
2. Add public helm repository for wso2APK.
    ```sh
    helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.0.0
    helm repo update
    ```
3. Install wso2APK to apk-dev namespace.
<br>
3.1 Create a values.yaml file with the following configurations.
<br>
   
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
3.2 Install wso2APK to apk-dev namespace.
```sh
helm install wso2apk wso2apk/apk-helm --version=1.0.0 -n apk-dev --values values.yaml
```
4. Install wso2APK to apk-stage namespace.
<br>
4.1 Create a values.yaml file with the following configurations.
<br>

``` yaml
  wso2:
    apk:
      webhooks:
        validatingwebhookconfigurations : true
        mutatingwebhookconfigurations : true
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
4.2 Install wso2APK to apk-stage namespace.
```sh
helm install wso2apk wso2apk/apk-helm --version=1.0.0 -n apk-stage --values values.yaml
```
Configure GitHub Actions to Deploy API to Dev and Stage Environments
1. Fork the repository to your GitHub account.
2. Configure **KUBE_CONFIG** in GitHub secrets to work with your Kubernetes cluster.

# Tryout.
## Deploy the API to the dev environment.
1. Go to the Actions under your forked repository.
2. Select the workflow called "Release DEV API."
3. Click on the "Run workflow" button and fill in the API name and version as follows.
    ```
    API Name: greetingAPI
    API Version: 1.0.0
    ```
4. Click on the "Run workflow" button.
5. Once completed, you will be able to see the workflow run as shown below.
   
   ![dev](https://github.com/tharindu1st/apk-ci-cd-pipeline/assets/6345931/4b9030c8-010d-403d-bdc2-44de0ce9f212)

6. Test the API by sending a request to the dev environment.
</br>
  6.1 Retrieve the dev environment's EXTERNAL-IP address.
</br>

```console
kubectl get svc apk-dev-wso2-apk-gateway-service -n apk-dev
```
  6.2 Create etc host entry for the dev environment's EXTERNAL-IP address.
  </br>

```console
  sudo echo "EXTERNAL-IP dev.gw.wso2.com" >> /etc/hosts
```

  6.3 Generate a token from IDP as per https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/
    </br>
  6.4 Send a request to the API.
  </br>

```console
  curl --location 'https://dev.gw.wso2.com:9095/greetingAPI/1.0.0/greeting?name=abce' \
  --header 'Authorization: Bearer <accessToken>’'
  ```
  We will receive the following response.
  </br>
  ```
  Hello, abce from dev environment!
  ```
## Deploy the API to the stage environment,
1. Go to the Actions under your forked repository.
2. Select the workflow called "Release Stage API."
3. Click on the "Run workflow" button and fill in the API name and version as follows.
    ```
    API Name: greetingAPI
    API Version: 1.0.0
    ```
4. Click on the "Run workflow" button.
5. Once completed, you will be able to see the workflow run as shown below.
   ![stage](https://github.com/tharindu1st/apk-ci-cd-pipeline/assets/6345931/f42a676b-d2bd-4183-9761-8d77aa41b0c6)

6. Test the API by sending a request to the stage environment.
</br>
6.1 Retrieve the staging environment's EXTERNAL-IP address.
</br>

```console
    kubectl get svc apk-dev-wso2-apk-gateway-service -n apk-stage
```
    6.2 Create etc host entry for the dev environment's EXTERNAL-IP address.
</br>

```console
 sudo echo "EXTERNAL-IP dev.gw.wso2.com" >> /etc/hosts
``` 
    6.3 Generate a token from IDP as per https://apk.docs.wso2.com/en/latest/develop-and-deploy-api/security/generate-access-token/
    6.4 Send a request to the API.
</br>

```console
curl --location 'https://stage.gw.wso2.com:9095/greetingAPI/1.0.0/greeting?name=abce' \
--header 'Authorization: Bearer <accessToken>’'
```
    We will receive the following response.
</br>

```
Hello, abce from stage environment!
```

## Uninstall API from the dev/stage environment.
1. Go to the Actions under your forked repository.
2. Select the workflow called "Uninstall API."
3. Click on the "Run workflow" button and fill in the API name, version, and environment as follows.

    ```
    API Name: greetingAPI
    API Version: 1.0.0
    Environment: dev
    ```
4. Click on the "Run workflow" button.
