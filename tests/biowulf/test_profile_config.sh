#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

output="$(
  BIOWULF_SIF_CACHE=/site/test/sif-cache \
    nextflow config -profile biowulf -flat
)"

assert_config() {
  local expected="$1"
  if ! grep -Fq "$expected" <<<"$output"; then
    printf 'Expected Biowulf config to contain: %s\n' "$expected" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
}

assert_config "process.executor = 'slurm'"
assert_config "process.resourceLimits = [cpus:24, memory:'224 GB']"
assert_config "process.queue = 'norm'"
assert_config "process.clusterOptions = '--gres=lscratch:200'"
assert_config "process.scratch = '/lscratch/\$SLURM_JOB_ID'"
assert_config "process.stageInMode = 'symlink'"
assert_config "process.stageOutMode = 'rsync'"
assert_config "process.cache = 'deep'"
assert_config 'executor.$slurm.queueSize = 200'
assert_config "executor.\$slurm.pollInterval = '2 min'"
assert_config "executor.\$slurm.queueStatInterval = '5 min'"
assert_config "executor.\$slurm.submitRateLimit = '6/1min'"
assert_config 'singularity.enabled = true'
assert_config 'singularity.autoMounts = true'
assert_config "singularity.cacheDir = '/site/test/sif-cache'"
assert_config "singularity.envWhitelist = 'SLURM_JOB_ID,SINGULARITY_BINDPATH'"
assert_config 'docker.enabled = false'
assert_config 'params.perform_celltyping = false'
assert_config 'params.perform_cnv_inference = false'
assert_config "params.af_resolution = 'cr-like-em'"

unconfigured_output="$(env -u BIOWULF_SIF_CACHE nextflow config -profile biowulf -flat)"
if ! grep -Fq 'singularity.cacheDir = null' <<<"$unconfigured_output"; then
  printf 'Expected Biowulf config to leave the Singularity cache unset without BIOWULF_SIF_CACHE\n' >&2
  exit 1
fi
