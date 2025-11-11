# A collection of helpful functions to get data from Veeam Scenario Builder vscn files.

# Gets all the base inputs for VM workloads from a sizer scope vscn file.
def open_file [file_name: string] {
    open $file_name | from json
}

# Private - get VM or Agent base inputs
def vm_agent [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | reject Retention
}

# Private - get VM or Agent base inputs with optional totals
def inputs [
    file_name: string
    scope: string
    --totals
    ] {
        let data = open_file $file_name


        let vm_data = $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name InstanceCount SourceTB

        if ($totals) {
            $vm_data | math sum
        } else {
            $vm_data
        }
    }

# Private - get VM or Agent Data Properties
def dataproperties [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name ChangeRate GrowthRatePercent GrowthRateScopeYears BackupWindowHours
}

# Private - get VM or Agent Retention
def retention [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name Days Weeklies Monthlies Yearlies
}

# Private - get VM or Agent Immutability & Protection
def protection [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name immutablePerf ImmutablePerfDays immutableCap ImmutableCapDays EnableEntropyScanning
}

# Private - get VM or Agent Infrastructure & Platform
def infra [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name PreferPhysicalProxySizing largeBlock IsManaged MachineType HyperVisor CalculatorMode ProductVersion
}

# Private - get VM or Agent Site & Identification
def site [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name SiteId SiteName Id
}

# Private - get VM or Agent Repository & Tiers
def repository [file_name scope] {
    let data = open_file $file_name
    $data | get WorkloadMap | get $scope | get TypedWorkloads | get BaseInputs | select Name ObjectStorage Blockcloning moveCapacityTierEnabled capacityTierDays copyCapacityTierEnabled archiveTierEnabled archiveTierStandalone ArchiveTierDays IsCapTierVDCV
}

# Gets the in-scope status for all workloads
export def in_scope [file_name] {
    let data = open_file $file_name
    $data | get WorkloadMap | values | skip 1 | each { |$item| { Name: $item.Name InScope: $item.IsInScope } }
}

# All VM Inputs
export def vm [file_name] {
    vm_agent $file_name "VMScope"
}

# VM Inputs with optional totals
export def "vm inputs" [
    file_name: string
    --totals
    ] {
        inputs $file_name "VMScope" --totals=$totals
    }

# VM Data Properties
export def "vm dataproperties" [file_name] {
    dataproperties $file_name "VMScope"
}

# VM Retention
export def "vm retention" [file_name] {
    let data = open_file $file_name
    retention $file_name "VMScope"
}

# VM Immutability & Protection
export def "vm protection" [file_name] {
    let data = open_file $file_name
    protection $file_name "VMScope"
}

# VM Infrastructure & Platform
export def "vm infra" [file_name] {
    let data = open_file $file_name
    infra $file_name "VMScope"
}

# VM Site & Identification
export def "vm site" [file_name] {
    let data = open_file $file_name
    # $data | get WorkloadMap | get VMScope | get TypedWorkloads | get BaseInputs | select Name SiteId SiteName Id
    site $file_name "VMScope"
}

# VM Repository & Tiers
export def "vm repository" [file_name] {
    let data = open_file $file_name
    # $data | get WorkloadMap | get VMScope | get TypedWorkloads | get BaseInputs | select Name ObjectStorage Blockcloning moveCapacityTierEnabled capacityTierDays copyCapacityTierEnabled archiveTierEnabled archiveTierStandalone ArchiveTierDays IsCapTierVDCV
    repository $file_name "VMScope"
}

# VM Target Resources - Disks
export def "vm results" [file_name] {
    let data = open_file $file_name
    $data |  get WorkloadMap
    | get VMScope
    | get TypedWorkloads
    | get TargetResources
    | each { |resource|
        $resource.Disks | each { |disks|
        $disks | each { |disk| { Name: $disk.Name, CapacityTB: ($disk.Capacity / 1024) }
        }
    }
    } | flatten | flatten
}

export def agent [file_name] {
    vm_agent $file_name "AgentScope"
}

# Agent Inputs with optional totals
export def "agent inputs" [
    file_name: string
    --totals
    ] {
        inputs $file_name "AgentScope" --totals=$totals
    }

# Agent Data Properties
export def "agent dataproperties" [file_name] {
    dataproperties $file_name "AgentScope"
}

# Agent Retention
export def "agent retention" [file_name] {
    retention $file_name "AgentScope"
}

# Agent Immutability & Protection
export def "agent protection" [file_name] {
    protection $file_name "AgentScope"
}

# Agent Infrastructure & Platform
export def "agent infra" [file_name] {
    infra $file_name "AgentScope"
}

# Agent Site & Identification
export def "agent site" [file_name] {
    site $file_name "AgentScope"
}

# Agent Repository & Tiers
export def "agent repository" [file_name] {
    repository $file_name "AgentScope"
}

# Get All Cloud Workloads
export def cloud [file_name] {
    let data = open_file $file_name
    $data | get WorkloadMap | values | skip 1 | where {|wl| $wl.Name in ["AWS", "Azure", "Google"] } 
}

# Get Base Inputs - takes result of WorkloadMap values
export def get_baseinputs [table: table] {
    $table
    | each --flatten { |wl| $wl.TypedWorkloads |
    | each --flatten { |tw| $tw.BaseInputs
    }
}}

# Cloud Inputs
export def "cloud inputs" [
    file_name: string
    ] {
        let cloud_data = cloud $file_name
        $cloud_data | 
        each --flatten { |wl| $wl.TypedWorkloads | 
        each { |tw| $tw.BaseInputs | 
        each { |bi| 
        { SiteName: $bi.SiteName,
          InstanceCount: $bi.ExpectedInstanceCount,
          Name: $bi.Name,
          VmSourceTB: $bi.VmSourceTb,
          DbSourceTB: $bi.DbSourceTB,
          FilesSourceTB: $bi.FilesSourceTB,
        } } } }
    }

# Cloud Data Properties
export def "cloud dataproperties" [file_name] {
    let cloud_data = cloud $file_name
    $cloud_data | 
    each --flatten { |wl| $wl.TypedWorkloads | 
    each { |tw| $tw.BaseInputs | 
    each { |bi| 
    { SiteName: $bi.SiteName,
      Name: $bi.Name,
      VmChangeRatePercent: $bi.VmChangeRatePercent,
      CompressionPercent: $bi.CompressionPercent,
      GrowthRatePercent: $bi.GrowthRatePercent,
      GrowthRateScopeYears: $bi.GrowthRateScopeYears,
      DbChangeRatePercent: $bi.DbChangeRatePercent,
      FilesChangeRatePercent: $bi.FilesChangeRatePercent,
    } } } }
}

# Cloud Retention
export def "cloud retention" [file_name] {
    let cloud_data = cloud $file_name
    let baseinputs = get_baseinputs $cloud_data
    # $baseinputs
    let vm_object_retention = $baseinputs | get VmObjectRetention | flatten 
    let db_object_retention = $baseinputs | get DbObjectRetention | flatten 
    let files_object_retention = $baseinputs | get FilesRetention | flatten
    let tables = {
        VM: $vm_object_retention,
        DB: $db_object_retention,
        Files: $files_object_retention
    }
    $tables
}

# Cloud Immutability & Protection
export def "cloud protection" [file_name] {
    let cloud_data = cloud $file_name
    let baseinputs = get_baseinputs $cloud_data
    $baseinputs | each { |bi| 
    { Name: $bi.Name,
      Immutability: $bi.Immutability}}
}

# Cloud Site & Identification
export def "cloud site" [file_name] {
    let cloud_data = cloud $file_name
    let baseinputs = get_baseinputs $cloud_data
    $baseinputs | each { |bi| 
    { Name: $bi.Name,
      SiteId: $bi.SiteId,
      SiteName: $bi.SiteName,
      Id: $bi.Id}}
}

# Unstructured - All Workloads
export def unstructured [file_name] {
    let data = open_file $file_name
    $data | get WorkloadMap | get NASs | get TypedWorkloads | get BaseInputs
}

export def "unstructured inputs" [
    file_name: string
    --totals
    ] {
        let data = open_file $file_name
        let workloads = unstructured $file_name
        let nas_data = $workloads | select Name InstanceCount SourceTB

        if ($totals) {
            $nas_data | math sum
        } else {
            $nas_data
        }
    }

export def "unstructured dataproperties" [file_name] {
    let data = open_file $file_name
    let workloads = unstructured $file_name
    $workloads | each { |bi| 
    { Name: $bi.Name,
      ChangeRate: $bi.ChangeRatePct,
      GrowthRatePercent: $bi.SourceData.YoYGrowthPct,
      GrowthRateScopeYears: $bi.SourceData.ProjectionYears,
      DataReductionPercent: $bi.SourceData.DataReductionPct,
    } }
}

export def "unstructured retention" [file_name] {
    let data = open_file $file_name
    let workloads = unstructured $file_name
    $workloads | each { |bi| 
    { Name: $bi.Name,
      Days: $bi.Days
    } }
}

export def "unstructured protection" [file_name] {
    let data = open_file $file_name
    let workloads = unstructured $file_name
    $workloads | each { |bi| 
    { Name: $bi.Name,
      Immutability: $bi.PrimaryCopy.Repo.Immutability,
      ImmutableDays: $bi.PrimaryCopy.Repo.ImmutabilityDays
    } }
}

export def "unstructured site" [file_name] {
    let data = open_file $file_name
    let workloads = unstructured $file_name
    $workloads | each { |bi| 
    { Name: $bi.Name,
      SiteId: $bi.SiteId,
      SiteName: $bi.SiteName,
      Id: $bi.Id
    } }
}

# Plugins - All Workloads
export def plugins [
    file_name
 ] {
    let data = open_file $file_name
    $data | get WorkloadMap | values | skip 1 | where {|wl| $wl.Name =~ "plug-in"}
} 

# Plugins Inputs
export def "plugins inputs" [
    file_name: string
    ] {
        let plugin_data = plugins $file_name 
        $plugin_data |
        each --flatten { |wl| $wl.TypedWorkloads |
        each --flatten { |tw| $tw.BaseInputs |
        each { |bi|
        { Name: $bi.Name,
          InstanceCount: $bi.InstanceCount,
          DbInstanceCount: $bi.DbInstanceCount,
          SizeOfFullBackupTB: $bi.SizeOfFullBackupTB
          IncSizeGB: $bi.IncSizeGB,
          LogSizeGB: $bi.LogSizeGB,
          NumberOfBackupChannels: $bi.NumberOfBackupChannels
        } } } }
    }

# Plugins Data Properties
export def "plugins dataproperties" [
    file_name: string
    ] {
        let plugin_data = plugins $file_name 
        $plugin_data |
        each --flatten { |wl| $wl.TypedWorkloads |
        each --flatten { |tw| $tw.BaseInputs |
        each { |bi|
        { Name: $bi.Name,
          CompressionPercent: $bi.CompressionPercent,
          GrowthRatePercent: $bi.GrowthRatePercent,
          GrowthRateScopeYears: $bi.GrowthRateScopeYears,
          BackupWindow: $bi.BackupWindow
        } } } }
    }

# Plugins Retention
export def "plugins retention" [file_name] {
    let plugin_data = plugins $file_name 
    let baseinputs = $plugin_data | 
        each --flatten { |wl| $wl.TypedWorkloads |
        each --flatten { |tw| $tw.BaseInputs } }

    $baseinputs | each { |bi| 
    { Name: $bi.Name,
      Days: $bi.Days,
      Weeklies: $bi.WeeksRetention
    } }
}

export def "plugins protection" [file_name] {
    let plugin_data = plugins $file_name 
    let baseinputs = $plugin_data | 
        each --flatten { |wl| $wl.TypedWorkloads |
        each --flatten { |tw| $tw.BaseInputs } }

    $baseinputs | each { |bi| 
    { Name: $bi.Name,
      Immutability: $bi.Immutability,
      ImmutableDays: $bi.ImmutabilityDays
    } }
}

export def "plugins site" [file_name] {
    let plugin_data = plugins $file_name 
    let baseinputs = $plugin_data | 
        each --flatten { |wl| $wl.TypedWorkloads |
        each --flatten { |tw| $tw.BaseInputs } }

    $baseinputs | each { |bi| 
    { Name: $bi.Name,
      SiteId: $bi.SiteId,
      SiteName: $bi.SiteName,
      Id: $bi.Id
    } }
}

# Replica Workloads
export def replica [
    file_name
 ] {
    let data = open_file $file_name
    $data | get WorkloadMap | get VmReplicas | get TypedWorkloads | get BaseInputs
}

# Replica Inputs with optional totals
export def "replica inputs" [
    file_name: string
    --totals
    ] {
        let replica_data = replica $file_name 
        let vm_data = $replica_data | select Name InstanceCount SourceTB

        if ($totals) {
            $vm_data | math sum
        } else {
            $vm_data
        }
    }

# Replica Data Properties
export def "replica dataproperties" [file_name] {
    let replica_data = replica $file_name 
    $replica_data | each { |bi| 
    { Name: $bi.Name,
      ChangeRate: $bi.ChangeRate,
      CompressionPercentage: $bi.CompressionPercentage,
      GrowthRatePercent: $bi.GrowthRatePercent,
      GrowthRateScopeYears: $bi.GrowthRateScopeYears,
    } }
}

# Replica Retention
export def "replica retention" [file_name] {
    let replica_data = replica $file_name 
    $replica_data | each { |bi| 
    { Name: $bi.Name,
      Retention: $bi.Retention,
      RpoMinutes: $bi.RpoMinutes
    } }
}

# Replica Immutability & Protection
export def "replica site" [file_name] {
    let replica_data = replica $file_name 
    $replica_data | each { |bi| 
    { Name: $bi.Name,
      SiteId: $bi.SiteId,
      SiteName: $bi.SiteName,
      Id: $bi.Id
    } }
}

# All Locations (sites)
export def locations [
    file_name
 ] {
    let data = open_file $file_name
    $data | get Locations
 }

 # CDP Workloads - All Workloads
 export def cdp [
    file_name
 ] {
    let data = open_file $file_name
    $data | get WorkloadMap | get CdpReplicas | get TypedWorkloads | get BaseInputs
 ]
 }

# All Results - combines all workload types into a single output
export def "all results" [file_name] {
    let data = open_file $file_name
    let vm_data = $data |  get WorkloadMap | get VMScope | get TypedWorkloads 
    let agent_data = $data | get WorkloadMap | get AgentScope | get TypedWorkloads 
    let vm_replica_data = $data | get WorkloadMap | get VmReplicas | get TypedWorkloads
    let CdpReplica_data = $data | get WorkloadMap | get CdpReplicas | get TypedWorkloads
    let NAS_data = $data | get WorkloadMap | get NASs | get TypedWorkloads 
    let oracle_data = $data | get WorkloadMap | get OracleInstances | get TypedWorkloads
    let sql_data = $data | get WorkloadMap | get SqlInstances | get TypedWorkloads
    let hana_data = $data | get WorkloadMap | get HanaInstances | get TypedWorkloads
    let sap_data = $data | get WorkloadMap | get SapOracleInstances | get TypedWorkloads
    let db2_data = $data | get WorkloadMap | get Db2Instances | get TypedWorkloads
    let m365_data = $data | get WorkloadMap | get M365s | get TypedWorkloads
    let aws_data = $data | get WorkloadMap | get AWSs | get TypedWorkloads
    let azure_data = $data | get WorkloadMap | get Azures | get TypedWorkloads
    let gcp_data = $data | get WorkloadMap | get GCPs | get TypedWorkloads

    echo {
        VM: $vm_data,
        Agent: $agent_data,
        VM_Replica: $vm_replica_data,
        CDP_Replica: $CdpReplica_data,
        NAS: $NAS_data,
        Oracle: $oracle_data,
        SQL: $sql_data,
        HANA: $hana_data,
        SAP: $sap_data,
        DB2: $db2_data,
        M365: $m365_data,
        AWS: $aws_data,
        Azure: $azure_data,
        GCP: $gcp_data
    }

}