        $FileCount = 1024000
        $FileSize =  1024000 # 1024000 Creates 1MB, 1024000000 Creates 1GB, 1024000000000 Creates 1TB
        $Number = 0
        foreach($Item in 1..$FileCount)
        {
            $Number += 1
            $FileName = "File$Number"
            fsutil file createnew "C:\_TEST\$FileName" $FileSize
        }