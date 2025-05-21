trigger:
  branches:
    include:
      - main

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  displayName: Build stage
  jobs:
  - job: BuildJob
    displayName: Build
    pool:
      vmImage: 'ubuntu-latest'
    steps:
      - task: UseDotNet@2
        inputs:
          packageType: sdk
          version: '9.x'
      - script: |
          dotnet restore
          dotnet build --configuration $(buildConfiguration)
        displayName: 'Restore & build'
      - script: dotnet publish -c $(buildConfiguration) -o $(Build.ArtifactStagingDirectory)/publish
        displayName: 'Publish artifact'
      - publish: $(Build.ArtifactStagingDirectory)/publish
        artifact: drop

- stage: Deploy
  displayName: Deploy stage
  dependsOn: Build
  jobs:
  - deployment: DeployWeb
    displayName: Deploy to Azure Web App
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
            - download: current
              artifact: drop
            - task: AzureWebApp@1
              inputs:
                azureSubscription: '<Your-Service-Connection-Name>'
                appName: '<Your-App-Service-Name>'
                package: '$(Pipeline.Workspace)/drop/publish'
