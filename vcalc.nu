def normalize-disk-capacity [disk] {
    if ($disk.CapacityString =~ "TB") {
        $disk.Capacity / 1024
    } else if ($disk.CapacityString =~ "MB") {
        $disk.Capacity / 1024 / 1024
    } else if ($disk.CapacityString =~ "PB") {
        $disk.Capacity * 1024
    } else {
        $disk.Capacity
    }
}

 export def backup-capacity [
    file_name
 ] {
    open $file_name |
        get Summaries |
        each --flatten {|summary| $summary.LocationSummaries } |
        each --flatten {|locsum|
            $locsum.BackupResources |
                where Name == "Repository" |
                each --flatten {|br|
                    $br.Disks |
                    where ($it.PurposeDescriptor != "OS" and
                           $it.Capacity > 0) |
                        each {|disk|
                            {
                                LocationName: $locsum.Location.Name,
                                ResourceName: $br.Name,
                                DiskName: $disk.Name, 
                                Platform: $br.PlatformDescriptor,
                                DiskCapacity: (normalize-disk-capacity $disk),
                                Purpose: $disk.PurposeDescriptor
                            }
                        }
                }
        } |
        group-by LocationName Platform Purpose --to-table |
        update items {|g| $g.items.DiskCapacity | math sum } |
        rename --column { items: CapacityTB } 
 }


 export def management-compute [
    file_name
 ] {
    open test.json |
    get Summaries |
    each --flatten {|summary| $summary.ManagementServer } |
    each --flatten {|locsum|
        each --flatten { |ms|
            { 
                Name: $ms.Name,
                Description: $ms.Description,
                Platform: $ms.PlatformDescriptor,
                Cores: (if $ms.Cores < 1 { 1 } else { $ms.Cores }),
                RAM: (if $ms.RamGB < 1 { 1 } else { $ms.RamGB })
            }
        }
    } 
}

 export def management-storage [
    file_name
 ] {
    open test.json |
    get Summaries |
    each --flatten {|summary| $summary.ManagementServer } |
    each --flatten {|locsum|
        each --flatten {|br|
            $br.Disks |
                each {|disk| 
                    {
                        DiskName: $disk.Name, 
                        Description: $disk.Description,
                        Type: $disk.TypeDescriptor,
                        DiskCapacity: (normalize-disk-capacity $disk),
                        Purpose: $disk.PurposeDescriptor
                    }
                }
    }
}
}

export def copy-capacity [
    file_name
] {
    open $file_name |
        get Summaries |
        each --flatten {|summary| $summary.LocationSummaries } |
        each --flatten {|locsum|
            $locsum.CopyResources |
                each --flatten {|br|
                    $br.Disks |
                    where ($it.PurposeDescriptor not-in ["OS" "System storage" "Other"] and $it.Capacity > 0) |
                        each {|disk| 
                            {
                                LocationName: $locsum.Location.Name,
                                Name: $br.Name,
                                DiskName: $disk.Name, 
                                Platform: ($br.PlatformDescriptor | parse "{_}({value})" | first | get value ),
                                DiskCapacity: (normalize-disk-capacity $disk),
                                Purpose: $disk.PurposeDescriptor
                            }
                        }
                }
        } |
        where Name == "Target repository" |
        group-by LocationName Name Platform Purpose --to-table |
        update items {|g| $g.items.DiskCapacity | math sum } |
        rename --column { items: CapacityTB } 
}

 export def backup-compute [
    file_name
 ] {
    open test.json |
    get Summaries |
    each --flatten {|summary| $summary.LocationSummaries } |
    each --flatten {|locsum|
        $locsum.BackupResources |
        each --flatten { |br|
            { 
                LocationName: $locsum.Location.Name,
                Name: $br.Name,
                Description: $br.Description,
                Platform: $br.PlatformDescriptor,
                Cores: (if $br.Cores < 1 { 1 } else { $br.Cores }),
                RAM: (if $br.RamGB < 1 { 1 } else { $br.RamGB })
            }
        }
    }  | sort-by LocationName Name
}
