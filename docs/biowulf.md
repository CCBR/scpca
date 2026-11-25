# Running scpca-nf on NIH Biowulf

This guide covers the standalone `biowulf` profile in this pinned `v0.11.0`
checkout. It is not a general SLURM profile. Keep site-specific paths and
metadata outside the source checkout and do not commit them.

## Validation status and scope

The profile was exercised on Biowulf with Java 17.0.21.1+2, Nextflow 25.10.0
and Apptainer 1.4.5. A scheduler smoke test verified the `norm` queue,
container execution, shared input access, `lscratch` allocation and output
copy-back. The mandatory 10x 3' v3.1 RNA example completed with 17 tasks and
no task failures. This is operational validation for that example, not
scientific equivalence to a separately qualified baseline.

The public example output archive was last modified on 2026-03-26, before the
`v0.11.0` tag dated 2026-11-02, and its provenance has not been matched to this
run. It is not a qualified numerical baseline.

The test did not cover optional modalities, GPU behavior, or general
Nextflow/Singularity remote-image cache lookup. The real workflow used
checksum-verified local SIF files, so do not infer cache behavior from that
run. A first resume after RAD files have been published can recompute
quantification and dependent tasks when the pipeline switches from the
generated RAD work path to the published RAD checkpoint path. That path change
coincided with cache misses in the tested run. Retain the run trace, report,
timeline, checksum manifest, input/reference provenance and scheduler evidence
alongside each run.

## Prerequisites

- Use a checkout based on the intended upstream release and a reviewed
  integration branch. This profile was tested against the pinned `v0.11.0`
  source.
- Start the Nextflow driver from a site-approved SLURM allocation. Do not run
  the driver on a login node or on Helix. Select Java, Nextflow and Apptainer
  modules using current Biowulf guidance, then verify them with
  `java -version`, `nextflow -version` and `apptainer --version`.
- Use approved shared filesystems for the Nextflow work directory, published
  outputs, metadata, input FASTQs, references and local SIFs. Ensure adequate
  quota and free space before a real run; a filesystem-wide free-space value
  is not a project quota.
- Stage each required SIF and reference file through an approved process and
  verify its checksum against the provenance manifest. Do not overwrite
  shared files or rely on a remote pull as a fallback.

The profile is intended to be used alone:

```text
-profile biowulf
```

Do not combine it with `standard` or `stub`, which can override executor or
container settings. It submits processes to `norm`, caps requests at 24 CPUs
and 224 GB, requests `lscratch:200`, runs task work under
`/lscratch/$SLURM_JOB_ID`, and copies task outputs back to the shared work
directory. These are profile limits, not per-task resource requests.

## Images and references

For an offline run, point all enabled container parameters at readable local
SIF files in a private `-params-file` or on the command line. The standard
10x RNA example used Salmon, alevin-fry, scpcatools-slim, scpcatools-reports,
scpcatools-anndata and scvi. Only images used by enabled workflow steps are
required.

`BIOWULF_SIF_CACHE` configures Nextflow's Singularity cache directory. Use an
approved writable directory if the chosen image configuration requires
Nextflow to cache remote references. The example run supplied direct local SIF
paths and did not test remote cache naming, lookup, pulls or writes; prefer
verified local SIF paths until those behaviors have been separately tested.

The default reference configuration points to S3. For an offline run, create a
private parameter file containing the local reference root and any other
required path overrides. Pass it with `-params-file`; do not rely on the S3
defaults. Ensure derived paths resolve to the staged index, annotations and
barcode whitelist. Check the effective configuration and run the local-reference
test before submitting production work. Do not use a dry-run inventory command
against a shared destination: upstream reference inventory can access network
metadata and create directories.

The optional `params/biowulf-v0.11.0-local-images.config` reads `PIPELINES_HOME`
and expects the staged `scpca/v0.11.0` references and images under it. Export
the directory before launching and supply the config with `-c` before `run`:

```bash
export PIPELINES_HOME=/path/to/pipelines
nextflow -c params/biowulf-v0.11.0-local-images.config run main.nf -profile biowulf ...
```

Nextflow does not expand environment variables directly in a JSON parameter
file. If an additional config sets `ref_rootdir`, it must also set the
reference paths derived from it: those paths may already have been evaluated
using the default root. Verify the effective configuration before running.

## Metadata

Prepare tab-separated run and sample metadata following the upstream
[`examples/README.md`](../examples/README.md) and
[`external-instructions.md`](../external-instructions.md). The standard
single-run example uses:

| Field | Example |
|---|---|
| `scpca_run_id` | `run01` |
| `scpca_library_id` | `library01` |
| `scpca_sample_id` | `sample01` |
| `scpca_project_id` | `project01` |
| `technology` | `10Xv3.1` |
| `assay_ontology_term_id` | `EFO:0009922` |
| `seq_unit` | `cell` |
| `sample_reference` | `Homo_sapiens.GRCh38.104` |
| `files_directory` | absolute path to the FASTQ directory |

The sample metadata must include `scpca_sample_id=sample01`. Include all
sample IDs in the run table. Keep the upstream scientific defaults unless the
analysis explicitly requires another setting.

## Run and resume

From the allocated driver shell, use persistent, approved locations. Keep the
parameter file, metadata files, work directory and output directory stable
between the initial run and resume. Store trace/report/timeline files alongside
the run evidence. Set `format_check_filename` explicitly in the private
parameter file so its value is stable across resumes; the upstream default
embeds the launch time and can produce a new output filename on each run.

```bash
nextflow run main.nf \
  -profile biowulf \
  -params-file /path/to/private-biowulf-params.json \
  --run_metafile /path/to/run_metadata.tsv \
  --sample_metafile /path/to/sample_metadata.tsv \
  --run_ids run01 \
  --format_check_filename run01-format-check.txt \
  --outdir /path/to/persistent-output \
  -work-dir /path/to/persistent-work \
  -with-trace /path/to/evidence/trace.tsv \
  -with-report /path/to/evidence/report.html \
  -with-timeline /path/to/evidence/timeline.html
```

The private parameter file should specify the local reference paths and local
SIF paths required for the selected workflow. The six images used by the RNA
example can be set as `salmon_container`, `alevinfry_container`,
`scpcatools_slim_container`, `scpcatools_reports_container`,
`scpcatools_anndata_container`, and `scvi_container` in that file. Other
enabled workflow steps may require additional images and references. Use
unique, dated output and evidence directories; do not put site-private paths
in public logs or this guide.

Resume with the same checkout, allocation context, work/output paths,
parameter file, metadata and container/reference inputs:

```bash
nextflow run main.nf \
  -profile biowulf \
  -params-file /path/to/private-biowulf-params.json \
  --run_metafile /path/to/run_metadata.tsv \
  --sample_metafile /path/to/sample_metadata.tsv \
  --run_ids run01 \
  --format_check_filename run01-format-check.txt \
  --outdir /path/to/persistent-output \
  -work-dir /path/to/persistent-work \
  -resume \
  -with-trace /path/to/evidence/trace-resume.tsv \
  -with-report /path/to/evidence/report-resume.html \
  -with-timeline /path/to/evidence/timeline-resume.html
```

Inspect the trace and workflow summary for cached, completed and failed tasks.
The first resume after mapping can take a different input branch: the original
run feeds the downstream quantification from the RAD task work directory,
whereas a resume can read the published RAD checkpoint. This path change was
observed to coincide with recomputed alevin-fry quantification and dependent
SCE steps. The
quantification output also differed for two cell barcodes on recomputation;
therefore do not claim byte-identical resume results. Compare identifiers,
counts and task status, and record any result checksum changes.

A subsequent resume on the same published-RAD branch, with the
`format_check_filename` pinned to the prior value, cached all 16 downstream
tasks and left the post-recompute output checksums unchanged. This confirms
stable cache reuse after the initial branch transition, but does not make the
first resumed results byte-identical to the original run.

## Preflight and troubleshooting

- Run `tests/biowulf/test_profile_config.sh` to check the effective profile.
- Run `tests/biowulf/test_reference_paths.sh /path/to/private-biowulf-params.json`
  to check local reference resolution and an isolated missing-reference
  negative control.
- Use `tests/biowulf/scheduler_smoke.nf` only with a small shared input, an
  approved output directory and a verified local SIF. Confirm the job ran on a
  compute node and inspect its evidence and trace.
- For a direct missing-image control, run
  `apptainer exec /path/to/nonexistent.sif true` and require a nonzero status
  with a missing-file error. This checks local image resolution without a
  registry pull.
- If a task cannot find an image, verify the local SIF path, read permission
  and checksum before changing cache settings. Avoid silently falling back to
  remote pulls.
- If a task cannot find a reference, inspect the effective local reference
  parameters and ensure all derived paths point to staged files, not S3.
- If a task fails on scratch or at stage-out, inspect its SLURM job, trace and
  work directory before retrying. Do not remove work files needed for resume.

## Updating to another upstream release

Start a reviewed branch from the new upstream release tag. Reapply the
Biowulf profile, focused tests and this documentation as isolated changes;
review the complete diff against the tag to preserve upstream licensing,
attribution and scientific defaults. Re-run the profile and reference tests,
SLURM/container/scratch smoke test, stub workflow and real example with
provenance. Qualify an independent matching baseline before claiming numerical
validation. Do not merge to a default branch or publish a release without
review.
