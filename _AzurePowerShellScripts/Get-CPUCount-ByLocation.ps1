$Family = Read-Host "Please Enter the Family Sku Name"

# Select Location
$Locations = Get-AzLocation | Select-Object Location
$Location = $Locations | Out-GridView -PassThru -Title "Please Select a Location"
$LocationName = $Location.Location

$TotalCPUCount = @()

# Get All VM's with specific Family Type in Specified Region
$VMs = Get-azvm -Location $LocationName -ErrorAction 0 | Where-Object {$_.HardwareProfile.VmSize -like '*'+$Family+'*'}

# For each VM get the Size
# Match Size with Location
    foreach ($VM in $VMs){
    $VMSize = (Get-AzVM -Name $VM.Name).HardwareProfile.VmSize
    $VMCoreCount = (Get-AzVMSize -VMName $VM.Name -ResourceGroupName $vm.ResourceGroupName -ErrorAction 0 | Where-Object {$_.Name -like $VMSize}).NumberOfCores

    $TotalCPUCount += $VMCoreCount

    $CombinedCPUCount = $TotalCPUCount | Measure-Object -Sum

    $obj = new-object psobject -Property @{
        "Total $LocationName $Family CPU Count" = $CombinedCPUCount.Sum
                        }
    }
$obj | fl "Total $LocationName $Family CPU Count"