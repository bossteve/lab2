# Get Group Name
$GroupName = Read-Host "Enter Group Name"
$GroupObjectID = (Get-MsolGroup | Where-Object {$_.DisplayName -like $GroupName}).ObjectID
$Members = Get-MsolUser | Where-Object {$_.UserType -like 'Member'}
foreach ($Member in $Members){
Add-MsolGroupMember -GroupObjectId $GroupObjectID -GroupMemberType User -GroupMemberObjectId $Member.ObjectID
}