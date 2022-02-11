# Get Group Name
$GroupName = Read-Host "Enter Group Name"
$GroupObjectID = (Get-MsolGroup | Where-Object {$_.DisplayName -like $GroupName}).ObjectID
$Users = Get-MsolUser
foreach ($User in $Users){
Add-MsolGroupMember -GroupObjectId $GroupObjectID -GroupMemberType User -GroupMemberObjectId $User.ObjectID
}