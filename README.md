# CSA Hybrid Lab Deployment
Based from the KillerHomeLab by Elliot Fields Jr

Adapted and coded by [Steve Bostedor](mailto://steve.bostedor@microsoft.com)

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fbossteve%2flab2%2fmain%2fazuredeploy.json)

This template deploys the following:

* Active Directory Domain Controller
  - Enterprise root CA
* ADFS Server
* Exchange 2016 Server
* Azure Active Directory Connect server
* Jumpbox with Bozteck VENM in c:\install

## Requirements
* URL to a PFX file containing a wildcard certificate (for now)
* URL to Exchange ISO (provided in defaults)

## Overview
The purpose of this demo lab environment is to be a cost effective "on prem" environment hosted in Azure that will be used as a hybrid identity scenario.  

Once deployed, you will have everything that you need in place to configure your AADC for your hybrid exchange deployment.  

Be sure to enter your public IP address in the allowedRDPIP field so that you are allowed to RDP into the jumpbox once deployed.

### Under Construction
This template is currently under construction.  Some pieces may not work properly for you and some may.  Everything is provided as-is.  I am actively building this so things will break from time to time.