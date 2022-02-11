# Enable Tls 1.2 for PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Select Subscription
$Subscriptions = Get-AzSubscription | Select-Object Name, ID
$Subscription = $Subscriptions | Out-GridView -PassThru -Title "Please Select the proper Subscription"
Select-AzSubscription -Subscription $Subscription.Name

# Get All Queues
$Queues = @()
# Get v2 Storage Accounts
$v2StorageAccounts = Get-AzStorageAccount | Where-Object {$_.Kind -eq 'StorageV2'}
$StorageAccounts = $v2StorageAccounts | Where-Object {$_.PrimaryLocation -eq 'usdodeast'}
foreach ($StorageAccount in $StorageAccounts){
$StorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName
$Context = New-AzStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $StorageAccountNameKey.Value[0]
Set-AzCurrentStorageAccount -StorageAccountName $StorageAccount.StorageAccountName -ResourceGroupName $StorageAccount.ResourceGroupName
$Queues += Get-AzStorageQueue -Context $Context -ErrorAction 0 | ft Name,Uri
}

$Queues