

$myResgroupName = "myResourceGroupName";
$myVMName = "myVMName";
$myVMAdminUserName = "HeeLoco";
$myVMAdminPassword = "Hello123!321!";


#Login-AzAccount
az login 
az account set --subscription 00000000-0000-0000-0000-000000000000

#create a group 
az group create --name $myRessgroupName --location centralus

#australiaeast
#centralus
#northeurope

#create a VM
az vm create -g $myResgroupName --name $myVMName --image win2019datacenter --admin-username $myVMAdminUserName --admin-password $myVMAdminPassword --license-type Windows_Server --size Standard_DS3_v2

#win2016datacenter
#win2019datacenter
#MicrosoftWindowsDesktop:Windows-10:rs5-enterprise:17763.914.1912042330

#https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
<#
Get-AzVMImagePublisher -Location northeurope | Select PublisherName

Get-AzVMImageOffer -Location northeurope -PublisherName MicrosoftWindowsDesktop | Select Offer


Get-AzVMImageSku -Location northeurope -PublisherName MicrosoftWindowsDesktop -Offer Windows-10 | Select Skus


Get-AzVMImage -Location northeurope -PublisherName MicrosoftWindowsDesktop -Offer Windows-10 -Sku rs5-enterprise| Select Version


"Publisher:Offer:Sku:Version"
MicrosoftWindowsDesktop:Windows-10:rs5-enterprise:17763.914.1912042330
#>
