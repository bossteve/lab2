$Family = Read-Host "Please Enter the Family Sku Name"
$CombinedView = @()

# Select Subscription
$Subscriptions = Get-AzSubscription | Select-Object Name, ID
$Subscription = $Subscriptions | Out-GridView -PassThru -Title "Please Select the proper Subscription"
Select-AzSubscription -Subscription $Subscription.Name

$Locations = Get-AzLocation -ErrorAction 0
    foreach ($Location in $Locations){
    $TotalCPUCount = @()

    # Get All VM's with specific Family Type
    $LocationName = $Location.Location
    $VMs = Get-azvm -Location $LocationName -ErrorAction 0 | Where-Object {$_.HardwareProfile.VmSize -like '*'+$Family+'*' -and $_.Name -ne $Null}
        foreach ($VM in $VMs ){
        $VMSize = (Get-AzVM -Name $VM.Name).HardwareProfile.VmSize
        $VMCoreCount = (Get-AzVMSize -VMName $VM.Name -ResourceGroupName $vm.ResourceGroupName -ErrorAction 0 | Where-Object {$_.Name -like $VMSize}).NumberOfCores

        $TotalCPUCount += $VMCoreCount

        $CombinedCPUCount = $TotalCPUCount | Measure-Object -Sum

        $obj = new-object psobject -InformationAction SilentlyContinue -Property @{
            "Total $LocationName $Family CPU Count" = $CombinedCPUCount.Sum
                            }
        }
        $CombinedView += $obj | fl "Total $LocationName $Family CPU Count"
}
# Clean Up View
$CombinedView | Out-File C:\CPUCount.txt
$file = "C:\CPUCount.txt"
$file = Get-Content -Path "C:\CPUCount.txt"
$file | ForEach {$_.TrimEnd()} | ? {$_.trim()}