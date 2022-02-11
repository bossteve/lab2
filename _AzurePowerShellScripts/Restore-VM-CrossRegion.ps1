# Set Source Variables

# Select Subscription
$Subscriptions = Get-AzSubscription | Select-Object Name, ID
$Subscription = $Subscriptions | Out-GridView -PassThru -Title "Please Select the proper Subscription"
Select-AzSubscription -Subscription $Subscription.Name

# Select Destination Location
$dstLocations = Get-AzLocation | Select-Object DisplayName
$selectdstLocation = $dstLocations | Out-GridView -PassThru -Title "Please Select Destination Location for the VM Restore"
$dstlocationName = $selectdstLocation.DisplayName

# Select VM Destination Resource Group
$dstRGs = Get-AzResourceGroup -Location $dstlocationName | Select-Object ResourceGroupName
$selectdstRG = $dstRGs | Out-GridView -PassThru -Title "Please Select Destination Resource Group"
$dstRGName = $selectdstRG.ResourceGroupName

# Select VM
Write-Host "Example:  khl-srv-01"
$vmName = Read-Host "Please enter VM Name"

# Select Destination Virtual Network
$dstvNets = Get-AzVirtualNetwork | Select-Object Name,ResourceGroupName
$selectdstVNet = $dstvNets | Out-GridView -PassThru -Title "Please Select Destination Virtual Network"
$dstvNetName = $selectdstVNet.Name

# Select Recovery Services Vault
$RSVaults = Get-AzRecoveryServicesVault | Select-Object Name
$selectRSVault = $RSVaults | Out-GridView -PassThru -Title "Please Select the Recovery Service Vault where the Backup was Performed"
$RSVaultName = $selectRSVault.Name

# Select Restore Storage Account
$rstStorageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName,ResourceGroupName,Id
$selectrstStorageAccount = $rstStorageAccounts | Out-GridView -PassThru -Title "Please Select the Storage Account to send Restores"
$rstStorageAccountName = $selectrstStorageAccount.StorageAccountName

# Select Destination Storage Account
$dstStorageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName,ResourceGroupName,Id
$selectdstStorageAccount = $dstStorageAccounts | Out-GridView -PassThru -Title "Please Select the Destination Storage Account"
$dstStorageAccountName = $selectdstStorageAccount.StorageAccountName

Write-Host "Example: C:\JSONs"
$jsonfileroot = Read-Host "Please enter the root location of the JSONFile used for VM Configuration"

$checkjsonfileroot = Get-Item -Path $jsonfileroot -ErrorAction 0
IF ($null -eq $checkjsonfileroot) {New-Item -ItemType Directory -Path $jsonfileroot -Force}
$jsonfile = $jsonfileroot+'\'+$vmName+'-Config.json'

$Date = (Get-Date)
$DateStr = $Date.ToString("yyyyMMddmmss")
$storageType = "Standard_LRS"

# Set Source Storage Context
$rstStorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $selectrstStorageAccount.ResourceGroupName -StorageAccountName $rstStorageAccountName
$rstContext = New-AzStorageContext -StorageAccountName $rstStorageACcountName -StorageAccountKey $rstStorageAccountNameKey.Value[0]
Set-AzCurrentStorageAccount -StorageAccountName $rstStorageAccountName -ResourceGroupName $selectrstStorageAccount.ResourceGroupName

# Azure Restore
Get-AzRecoveryServicesVault -Name $RSVaultName | Set-AzRecoveryServicesVaultContext
$namedContainer = Get-AzRecoveryServicesBackupContainer  -ContainerType "AzureVM" -Status "Registered" | Where-Object {$_.FriendlyName -like $vmName+'*'}
$backupitem = Get-AzRecoveryServicesBackupItem -Container $namedContainer -WorkloadType "AzureVM"
$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date
$recoverypoints = Get-AzRecoveryServicesBackupRecoveryPoint -Item $backupitem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime()
$selectrecoverypoint = $RecoveryPoints | Out-GridView -PassThru -Title "Please Select Recovery Point"
$restorejob = Restore-AzRecoveryServicesBackupItem -RecoveryPoint $selectrecoverypoint -StorageAccountName $rstStorageAccountName -StorageAccountResourceGroupName $selectrstStorageAccount.ResourceGroupName  -RestoreAsUnmanagedDisks

while (($RestoreJob.Status -eq 'InProgress')){
$RestoreJob = Get-AzRecoveryServicesBackupJob -Job $RestoreJob
Start-Sleep 60}

# Gather Restore Job Details
$restorejob = Get-AzRecoveryServicesBackupJob -Job $restorejob
$details = Get-AzRecoveryServicesBackupJobDetail -Job $restorejob
$properties = $details.properties
$srcCN = $properties["Config Blob Container Name"]
$blobName = $properties["Config Blob Name"]

# Create JSON
$destination_path = $jsonfile
Get-AzStorageBlobContent -Container $srcCN -Blob $blobName -Destination $destination_path -Force
$obj = ((Get-Content -Path $destination_path -Raw -Encoding Unicode)).TrimEnd([char]0x00) | ConvertFrom-Json
$Blob0 = $obj.'properties.StorageProfile'.osDisk.vhd.uri.Split("/")[4]

# Set Destination Variables
$dstVNet = Get-AzVirtualNetwork -Name $dstvNetName -ResourceGroupName $selectdstVNet.ResourceGroupName

# Set Destination Storage Context
$dstStorageAccountNameKey = Get-AzStorageAccountKey -ResourceGroupName $selectdstStorageAccount.ResourceGroupName -StorageAccountName $dstStorageAccountName
$dstContext = New-AzStorageContext -StorageAccountName $dstStorageAccountName -StorageAccountKey $dstStorageAccountNameKey.Value[0]
Set-AzCurrentStorageAccount -StorageAccountName $dstStorageAccountName -ResourceGroupName $selectdstStorageAccount.ResourceGroupName
$srcCN | New-AzStorageContainer -Permission Off

# Copy OS Disk
Start-AzStorageBlobCopy -SrcContainer $srcCN -DestContainer $srcCN -SrcBlob $Blob0 -DestBlob $Blob0 -Context $rstContext -DestContext $dstContext

# Copy Data Disks
foreach($dd in $obj.'properties.StorageProfile'.DataDisks)
  {
  Start-AzStorageBlobCopy -SrcContainer $srcCN -DestContainer $srcCN -SrcBlob $dd.vhd.Uri.Split("/")[4] -DestBlob $dd.vhd.Uri.Split("/")[4] -Context $rstContext -DestContext $dstContext
  }

# Wait for OS Disk to Finish Copying
Get-AzStorageBlobCopyState -Blob $Blob0 -Container $srcCN -WaitForComplete

# Wait for Data Disks to Finish Copying
foreach($dd in $obj.'properties.StorageProfile'.DataDisks)
  {
  Get-AzStorageBlobCopyState -Blob $dd.vhd.Uri.Split("/")[4] -Container $srcCN -WaitForComplete
  }

# Set Destination VM Hardware Size
$vm = New-AzVMConfig -VMSize $obj.'properties.hardwareProfile'.vmSize -VMName $vmName

# Create OS Disk Name
$osDiskName = $vm.Name + "_osdisk_"+$DateStr

# Set OS Uri
$osVhdUri = "https://"+$dstStorageAccountName+".blob.core.usgovcloudapi.net/" +$srcCN+"/"+$Blob0

# Create OS Disk Config
$osdiskConfig = New-AzDiskConfig -AccountType $storageType -Location $dstlocationName -CreateOption Import -SourceUri $osVhdUri -StorageAccountId $selectdstStorageAccount.Id

# Create OS Managed Disk
$osDisk = New-AzDisk -DiskName $osDiskName -Disk $osdiskConfig -ResourceGroupName $dstRGName

# Attach OS Managed Disk
Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -CreateOption "Attach" -Windows

# Create Data Managed Disks
foreach($dd in $obj.'properties.StorageProfile'.DataDisks)
  {
  $DataDiskvhdName = $dd.vhd.uri.Split("/")[4]
  $DataDiskName = $DataDiskvhdName.Split(".")[0]
  $DataVhdUri = "https://"+$dstStorageAccountName+".blob.core.usgovcloudapi.net/" +$srcCN+"/"+$dd.vhd.uri.Split("/")[4]
  $datadiskConfig = New-AzDiskConfig -AccountType $storageType -Location $dstlocationName -CreateOption Import -SourceUri $DataVhdUri -StorageAccountId $selectdstStorageAccount.Id
  $DataDisk = New-AzDisk -DiskName $DataDiskName -Disk $datadiskConfig -ResourceGroupName $dstRGName
  Add-AzVMDataDisk -VM $vm -ManagedDiskId $DataDisk.Id -CreateOption "Attach" -Lun $dd.lun -Caching None
  }

# Create NICs
foreach($nic in $obj.'properties.networkProfile'.networkInterfaces)
 {
  $NewNicName = $nic.Id.Split("/")[8]
 $NewNicID = '/'+$nic.Id.Split("/")[1]+'/'+$nic.Id.Split("/")[2]+'/'+$nic.Id.Split("/")[3]+'/'+$dstRGName+'/'+$nic.Id.Split("/")[5]+'/'+$nic.Id.Split("/")[6]+'/'+$nic.Id.Split("/")[7]+'/'+$nic.Id.Split("/")[8]
 $isPrimary = $nic.'properties.primary'
 New-AzNetworkInterface -ResourceGroupName $dstRGName -Location $dstlocationName -Name $NewNicName -SubnetId $dstVNet.Subnets[0].Id
     IF ($isPrimary -eq 'True'){
     $vm = Add-AzVMNetworkInterface -VM $vm -Id $NewNicID -Primary
     }
     ELSE {$vm = Add-AzVMNetworkInterface -VM $vm -Id $NewNicID}
 }

# Create VM
Set-AzVMBootDiagnostic -Disable -VM $vm
New-AzVM -ResourceGroupName $dstRGName -Location $dstlocationName -VM $vm