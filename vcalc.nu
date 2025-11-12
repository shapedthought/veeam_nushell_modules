# A collection of functions for Veeam Scenario Builder output data analysis - if you know, you know.

# Private helper function to normalize disk capacity to TB
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

# Returns key stats from the input file
export def key-stats [
    file_name
] {
    $file_name | get KeyStats
}

# Returns a table of backup storage disks from the input file
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
                                CapacityTB: (normalize-disk-capacity $disk),
                                Purpose: $disk.PurposeDescriptor
                            }
                        }
                }
        } |
        group-by LocationName Platform Purpose --to-table |
        update items {|g| $g.items.CapacityTB | math sum } |
        rename --column { items: CapacityTB } |
        upsert CapacityGB {|row| $row.CapacityTB * 1024 }
 }


# Returns a table of management server compute resources from the input file
export def management-compute [
    file_name
] {
    open $file_name |
    get Summaries |
    each --flatten {|summary| $summary.ManagementServer } |
    each --flatten {|locsum|
        each --flatten { |ms|
            { 
                Name: $ms.Name,
                Description: $ms.Description,
                Platform: $ms.PlatformDescriptor,
                Cores: ([$ms.Cores 1] | math max),
                RAM: ([$ms.RamGB 1] | math max)
            }
        }
    }
}

# Returns a table of management server storage disks from the input file
export def management-storage [
    file_name
] {
    open $file_name |
    get Summaries |
    each --flatten {|summary| $summary.ManagementServer } |
    each --flatten {|ms|
        $ms.Disks |
            each {|disk| 
                {
                    Name: $ms.Name,
                    DiskName: $disk.Name, 
                    Description: $disk.Description,
                    Type: $disk.TypeDescriptor,
                    DiskCapacityGB: (normalize-disk-capacity $disk),
                    Purpose: $disk.PurposeDescriptor
                }
            }
        }

}

# Returns a table of copy storage disks from the input file
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
        rename --column { items: CapacityTB } |
        upsert CapacityGB {|row| $row.CapacityTB * 1024 }
}

# Returns a table of backup compute resources from the input file
export def backup-compute [
    file_name
] {
    open $file_name |
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
                Cores: ([$br.Cores 1] | math max),
                RAM: ([$br.RamGB 1] | math max)
            }
        }
    }  | sort-by LocationName Name
}

# Combines backup-capacity and copy-capacity, then rolls up CapacityTB by LocationName and Purpose
export def combined-capacity-rollup [file_name] {
    let backup = (backup-capacity $file_name | each {|row| $row | insert Type "Backup"})
    let copy = (copy-capacity $file_name | each {|row| $row | insert Type "Copy"})
    let combined = ($backup | append $copy)
    $combined
    | group-by LocationName Purpose --to-table
    | each {|row| 
        { 
            LocationName: $row.LocationName,
            Purpose: $row.Purpose,
            CapacityTB: ($row.items | get CapacityTB | math sum)
        }
    }
}

export def backup-compute-rollup [file_name] {
    backup-compute $file_name 
    | update Name {|row| if $row.Name =~ "Source|Target" { $"($row.Platform) ($row.Name)" } else { $row.Name }}
    | group-by LocationName Name --to-table 
    | each {|row| 
        { 
            LocationName: $row.LocationName, 
            Name: $row.Name, 
            Cores: ($row.items | get Cores | math sum), 
            RAM: ($row.items | get RAM | math sum)
        }
    } 
    | sort-by LocationName Name
}