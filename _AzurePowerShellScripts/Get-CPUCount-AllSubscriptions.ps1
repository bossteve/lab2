$Family = Read-Host "Please Enter the Family Sku Name"
$Exclude = Read-Host "Please Enter Family Exclusion"
$SubscriptionLocationView = @()
$SubscriptionView = @()
$AllView = @()

# Select Subscription
$Subscriptions = Get-AzSubscription -ErrorAction 0
foreach ($Subscription in $Subscriptions){
Select-AzSubscription -Subscription $Subscription.Name
$SubscriptionName = $Subscription.Name
$AllVMsInSub = Get-azvm -ErrorAction 0 | Where-Object {$_.HardwareProfile.VmSize -like '*'+$Family+'*' -and $_.HardwareProfile.VmSize -notlike '*'+$Exclude+'*'}

$Locations = Get-AzLocation -ErrorAction 0
    foreach ($Location in $Locations){

    # Get All VM's with specific Family Type
    $LocationName = $Location.Location
    $VMs = $AllVMsInSub | Where-Object {$_.Location -like $LocationName}
        foreach ($VM in $VMs ){
        $VMSize = (Get-AzVM -Name $VM.Name).HardwareProfile.VmSize

        $VMCoreCount = (Get-AzVMSize -VMName $VM.Name -ResourceGroupName $vm.ResourceGroupName -ErrorAction 0 | Where-Object {$_.Name -like $VMSize}).NumberOfCores
        $TotalVMCoreCount = @()
        $TotalVMCoreCount += $VMCoreCount
        $LocationCoreCount = ($TotalVMCoreCount | Measure-Object -Sum).Sum

        $SubscriptionLocationObject = new-object psobject -InformationAction SilentlyContinue -Property @{
            "Total $SubscriptionName $LocationName $Family CPU Count" = $LocationCoreCount
            }
        }
        $SubscriptionLocationView += $SubscriptionLocationObject | Format-List "Total $SubscriptionName $LocationName $Family CPU Count"

        $SubscriptionCoreCount = @()
        foreach ($Subscription in $Subscriptions){
            $SubscriptionCoreCount += $LocationCoreCount
            $TotalSubscriptionCoreCount = ($SubscriptionCoreCount | Measure-Object -Sum).Sum

        $SubscriptionObject = new-object psobject -InformationAction SilentlyContinue -Property @{
            "Total $SubscriptionName $Family CPU Count" = $TotalSubscriptionCoreCount
            }
        }
        $TotalCoreCount = @()
        foreach ($Subscription in $Subscriptions){
            $TotalCoreCount += $TotalSubscriptionCoreCount
            $FinalCoreCount = ($TotalCoreCount | Measure-Object -Sum).Sum

        $AllObject = new-object psobject -InformationAction SilentlyContinue -Property @{
            "Total $Family CPU Count" = $FinalCoreCount
            }
        }
    }
    $SubscriptionView += $SubscriptionObject | Format-List "Total $SubscriptionName $Family CPU Count"    
}
$AllView += $AllObject | Format-List "Total $Family CPU Count"

# Clean Up View/Remove File
$SubscriptionLocationView | Out-File "C:\Temp\CPUCount.txt"
$file = "C:\Temp\CPUCount.txt"
$file = Get-Content -Path "C:\Temp\CPUCount.txt"
$file | ForEach-Object {$_.TrimEnd()} | Where-Object {$_.trim()}
Remove-Item -Path C:\Temp\CPUCount.txt -Force

$SubscriptionView | Out-File "C:\Temp\CPUCount.txt"
$file = "C:\Temp\CPUCount.txt"
$file = Get-Content -Path "C:\Temp\CPUCount.txt"
$file | ForEach-Object {$_.TrimEnd()} | Where-Object {$_.trim()}
Remove-Item -Path C:\Temp\CPUCount.txt -Force

$AllView | Out-File "C:\Temp\CPUCount.txt"
$file = "C:\Temp\CPUCount.txt"
$file = Get-Content -Path "C:\Temp\CPUCount.txt"
$file | ForEach-Object {$_.TrimEnd()} | Where-Object {$_.trim()}
Remove-Item -Path C:\Temp\CPUCount.txt -Force