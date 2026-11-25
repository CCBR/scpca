This folder contains additional configuration files for running the `scpca-nf` workflow, as described below.
To use a configuration file, it must be referenced in the main configuration file (i.e., [`nextflow.config`](../nextflow.config)) using `includeConfig`.


- `containers.config`: Docker containers used by `scpca-nf` workflow processes
- `ccdl_inputs.config` and `ccdl_profiles.config`: file locations and settings for Data Lab users only, as described in [`internal-instructions.md`](../internal-instructions.md#running-scpca-nf-as-a-data-lab-staff-member)
- `base.config`: default resource settings for `scpca-nf` workflow processes
- `module.config`: module and process-specific configuration settings
- `profile_awsbatch.config`: AWS Batch configuration for Data Lab users
- `profile_stub.config`: file locations used for testing `scpca-nf` workflow logic, as described in [`internal-instructions.md`](../internal-instructions.md#testing-the-workflow-during-development)
- `profile_example.config`: file locations for re-generating example `scpca-nf` workflow output, as described in [`internal-instructions.md`](../internal-instructions.md#processing-example-data)
- `reference_paths.config`: file locations for reference data
- `profile_biowulf.config`: standalone SLURM and Singularity settings for running on Biowulf
- [`docs/biowulf.md`](../docs/biowulf.md): Biowulf setup, run instructions, validation scope and known limitations

The `biowulf` profile is intended to be used by itself. Do not combine it with `standard` or
`stub`: those profiles can override its executor or container settings. Set `BIOWULF_SIF_CACHE`
to an approved, writable Singularity image-cache directory when using image references that
require Nextflow to cache remote images. Direct local SIF paths do not use that cache.

The Biowulf profile sets `process.resourceLimits` to 24 CPUs and 224 GB of memory. This ceiling is
supported on Biowulf and accommodates the workflow's 24-CPU label and its `mem_max` request of
192 GB on the first attempt, while leaving room below the normal node's available memory.

The profile also configures SLURM scratch (`--gres=lscratch:200` and
`/lscratch/$SLURM_JOB_ID`), symlink stage-in, rsync stage-out, deep task caching, and SLURM queue
throttling. A compute-node smoke test verified GRES allocation, scratch execution, shared input
access and output copy-back. Singularity cache naming/lookup was not validated: the real example
used checksum-verified local SIF paths. See [`docs/biowulf.md`](../docs/biowulf.md) for the
validated scope and resume caveats.
