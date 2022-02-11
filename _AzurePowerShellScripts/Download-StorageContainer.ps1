# Select Subscription
$Subscriptions = Get-AzSubscription | Select-Object Name, ID
$Subscription = $Subscriptions | Out-GridView -PassThru -Title "Please Select the proper Subscription"
Select-AzSubscription -Subscription $Subscription.Name

# Select Storage Account
$StorageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName,ResourceGroupName,Id
$selectStorageAccount = $StorageAccounts | Out-GridView -PassThru -Title "Please Select the Storage Account to send Restores"
$StorageAccountName = $selectStorageAccount.StorageAccountName

# Set Storage Context
$StorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $selectStorageAccount.ResourceGroupName -StorageAccountName $StorageAccountName
$Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountNameKey.Value[0]
Set-AzCurrentStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $selectStorageAccount.ResourceGroupName

# Select Container
$Containers = Get-AzStorageContainer | Select-Object Name
$selectContainer = $Containers | Out-GridView -PassThru -Title "Select the desired Container"
$ContainerName = $selectContainer.Name

$Blobs = Get-AzStorageBlob -Container $ContainerName

foreach ($Blob in $Blobs){
Get-AzStorageBlobContent -Container $ContainerName -Blob $blob.Name -Destination C:\JSONs -Force
}