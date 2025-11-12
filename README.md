# Veeam Scenario Builder Nushell Modules

This repository contains Nushell modules for extracting, transforming, and summarizing data from Veeam Scenario Builder `.vscn` files and related JSON exports. These modules provide a set of functions to help analyze backup, compute, storage, and workload information for Veeam sizing and architecture planning.

## Modules

### vcalc.nu
Provides functions to extract and summarize capacity and compute requirements from Veeam scenario exports.

- **backup-capacity**: Returns a table of backup storage disks by location, platform, and purpose.
- **management-compute**: Returns a table of management server compute resources (cores, RAM).
- **management-storage**: Returns a table of management server storage disks.
- **copy-capacity**: Returns a table of copy storage disks for target repositories.
- **backup-compute**: Returns a table of backup compute resources by location and platform.
- **combined-capacity-rollup**: Returns a summarized table of total capacity requirements across all storage types.
- **backup-compute-rollup**: Returns a summarized table of total backup compute resources by platform.

### vcalc_inputs.nu
Provides functions to extract detailed workload, retention, protection, and site information from Veeam `.vscn` files.

- **vm/agent/cloud/unstructured/plugins/replica/cdp**: Extracts base inputs for each workload type.
- **[workload] inputs/dataproperties/retention/protection/infra/site/repository/results**: Extracts specific properties for each workload type (VM, agent, cloud, etc.).
- **all results**: Returns a summary table of all workload types and their data.
- **locations**: Lists all sites/locations in the scenario file.

## Usage with vscn files

1. Import the modules in your Nushell session:

```nu
use vcalc_inputs.nu
```

2. Call the desired function, passing the path to your `.vscn` or JSON file:

```nu
vcalc_inputs vm my_scenario.vscn
vcalc_inputs vm inputs my_scenario.vscn --totals
vcalc_inputs vm dataproperties my_scenario.vscn
vcalc_inputs vm retention my_scenario.vscn
vcalc_inputs vm protection my_scenario.vscn
vcalc_inputs vm infra my_scenario.vscn
vcalc_inputs vm site my_scenario.vscn
vcalc_inputs vm repository my_scenario.vscn
vcalc_inputs vm results my_scenario.vscn
```
You can replace `vm` with other workload types like `agent`, `cloud`, `unstructured`, `plugins`, `replica`, or `cdp`.

## Usage with JSON files (if you know, you know)

1. Import the modules in your Nushell session:

```nu
use vcalc.nu
```

2. Call the desired function, passing the path to your JSON export file:

```nu
vcalc backup-compute my_scenario.json
vcalc backup-capacity my_scenario.json
vcalc management-compute my_scenario.json
vcalc management-storage my_scenario.json
```

## Requirements
- Nushell (https://www.nushell.sh/)
- Veeam Scenario Builder `.vscn` files or compatible JSON exports

## Notes
- Functions are designed to be composable and return tables for easy further processing in Nushell pipelines.
- See function comments in each module for details on parameters and output.

## License
MIT License
