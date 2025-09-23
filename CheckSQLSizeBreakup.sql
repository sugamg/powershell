--"Not Deleted" means that objects are still in the system.
--"Deleted" means retention job have marked the objects for deletion. Next step is to wait on the final cleanup job to remove from DB.
SELECT Owner =
CASE
WHEN OwnerId = 0 THEN 'Generic' 
WHEN OwnerId = 1 THEN 'VersionControl'
WHEN OwnerId = 2 THEN 'WorkItemTracking'
WHEN OwnerId = 3 THEN 'TeamBuild'
WHEN OwnerId = 4 THEN 'TeamTest'
WHEN OwnerId = 5 THEN 'Servicing'
WHEN OwnerId = 6 THEN 'UnitTest'
WHEN OwnerId = 7 THEN 'WebAccess'
WHEN OwnerId = 8 THEN 'ProcessTemplate'
WHEN OwnerId = 9 THEN 'StrongBox'
WHEN OwnerId = 10 THEN 'FileContainer'
WHEN OwnerId = 11 THEN 'CodeSense'
WHEN OwnerId = 12 THEN 'Profile'
WHEN OwnerId = 13 THEN 'Aad'
WHEN OwnerId = 14 THEN 'Gallery'
WHEN OwnerId = 15 THEN 'BlobStore'
WHEN OwnerId = 255 THEN 'PendingDeletion'
ELSE CONVERT(VARCHAR, OwnerId)
END,
'Deleted' as CurrentState,
SUM(CompressedLength) / 1024 /1024 as TotalSizeInMB FROM tbl_FileMetadata a
Left Join tbl_FileReference b
on a.PartitionId = b.PartitionId and a.ResourceId = b.ResourceId
where b.DeletedOn is not null
GROUP BY OwnerId
 
UNION ALL
 
SELECT Owner =
CASE
WHEN OwnerId = 0 THEN 'Generic' 
WHEN OwnerId = 1 THEN 'VersionControl'
WHEN OwnerId = 2 THEN 'WorkItemTracking'
WHEN OwnerId = 3 THEN 'TeamBuild'
WHEN OwnerId = 4 THEN 'TeamTest'
WHEN OwnerId = 5 THEN 'Servicing'
WHEN OwnerId = 6 THEN 'UnitTest'
WHEN OwnerId = 7 THEN 'WebAccess'
WHEN OwnerId = 8 THEN 'ProcessTemplate'
WHEN OwnerId = 9 THEN 'StrongBox'
WHEN OwnerId = 10 THEN 'FileContainer'
WHEN OwnerId = 11 THEN 'CodeSense'
WHEN OwnerId = 12 THEN 'Profile'
WHEN OwnerId = 13 THEN 'Aad'
WHEN OwnerId = 14 THEN 'Gallery'
WHEN OwnerId = 15 THEN 'BlobStore'
WHEN OwnerId = 255 THEN 'PendingDeletion'
ELSE CONVERT(VARCHAR, OwnerId)
END,
'Not Deleted'as CurrentState,
SUM(CompressedLength) / 1024 /1024 as TotalSizeInMB FROM tbl_FileMetadata a
left Join tbl_FileReference b
on a.PartitionId = b.PartitionId and a.ResourceId = b.ResourceId
where b.DeletedOn is null
GROUP BY OwnerId
 
ORDER BY 1, 2 DESC
