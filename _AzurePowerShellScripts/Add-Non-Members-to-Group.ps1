# Get Group Name
$GroupName = Read-Host "Enter Group Name"
$GroupObjectID = (Get-MsolGroup | Where-Object {$_.DisplayName -like $GroupName}).ObjectID
$BlogMembers = Get-MsolUser | Where-Object {$_.UserType -notlike 'Member'}
foreach ($BlogMember in $BlogMembers){
Add-MsolGroupMember -GroupObjectId $GroupObjectID -GroupMemberType User -GroupMemberObjectId $BlogMember.ObjectID
}