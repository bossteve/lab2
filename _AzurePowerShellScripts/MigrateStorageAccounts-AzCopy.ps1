# Set Source Variables
azcopy login --aad-endpoint 'https://login.microsoftonline.us'

# Select Subscription
$Subscriptions = Get-AzSubscription | Select-Object Name, ID
$Subscription = $Subscriptions | Out-GridView -PassThru -Title "Please Select the proper Subscription"
Select-AzSubscription -Subscription $Subscription.Name

# Select Source Location
$srcLocations = Get-AzLocation | Select-Object DisplayName
$selectsrcLocation = $srcLocations | Out-GridView -PassThru -Title "Please Select Destination Location for the VM Restore"
$srclocationName = $selectsrcLocation.DisplayName

# Select Destination Location
$dstLocations = Get-AzLocation | Where-Object {$_.DisplayName -ne $srclocationName} | Select-Object DisplayName
$selectdstLocation = $dstLocations | Out-GridView -PassThru -Title "Please Select Destination Location for the VM Restore"
$dstlocationName = $selectdstLocation.DisplayName

# Select Source Resource Group
$srcRGs = Get-AzResourceGroup -Location $srclocationName | Select-Object ResourceGroupName
$selectsrcRG = $srcRGs | Out-GridView -PassThru -Title "Please Select Source Resource Group"
$srcRGName = $selectsrcRG.ResourceGroupName

# Select Destination Resource Group
$dstRGs = Get-AzResourceGroup -Location $dstlocationName | Select-Object ResourceGroupName
$selectdstRG = $dstRGs | Out-GridView -PassThru -Title "Please Select Destination Resource Group"
$dstRGName = $selectdstRG.ResourceGroupName

# Select Source Storage Account
$srcStorageAccounts = Get-AzStorageAccount -ResourceGroupName $srcRGName | Select-Object StorageAccountName,ResourceGroupName,Id
$selectsrcStorageAccount = $srcStorageAccounts | Out-GridView -PassThru -Title "Please Select the Source Storage Account"
$srcStorageAccountName = $selectsrcStorageAccount.StorageAccountName

# Select Destination Storage Account
$dstStorageAccounts = Get-AzStorageAccount -ResourceGroupName $dstRGName | Select-Object StorageAccountName,ResourceGroupName,Id
$selectdstStorageAccount = $dstStorageAccounts | Out-GridView -PassThru -Title "Please Select the Destination Storage Account"
$dstStorageAccountName = $selectdstStorageAccount.StorageAccountName

# Set Source Storage Context
$srcStorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $srcRGName -Name $srcStorageAccountName
$srcContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageAccountNameKey.Value[0]
$srcSASToken = New-AzStorageAccountSASToken -Context $srcContext -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup

# Set Destination Storage Context
$dstStorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $dstRGName -Name $dstStorageAccountName
$dstContext = New-AzStorageContext -StorageAccountName $dstStorageAccountName -StorageAccountKey $dstStorageAccountNameKey.Value[0]
$dstSASToken = New-AzStorageAccountSASToken -Context $dstContext -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup

azcopy copy "https://$srcStorageAccountName.blob.core.usgovcloudapi.net/$srcSASToken' 'https://$dstStorageAccountName.blob.core.usgovcloudapi.net/$dstSASToken" --recursive