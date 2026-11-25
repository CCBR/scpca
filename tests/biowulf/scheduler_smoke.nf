params.smoke_input = null
params.smoke_output = null
params.smoke_container = null

process schedulerSmoke {
  container params.smoke_container
  cpus 1
  memory 1.GB
  publishDir params.smoke_output, mode: 'copy'

  input:
  path input_file

  output:
  path 'smoke-evidence.txt'

  script:
  """
  set -euo pipefail
  {
    printf 'hostname=%s\\n' \"\$(hostname)\"
    printf 'slurm_job_id=%s\\n' \"\${SLURM_JOB_ID:-unset}\"
    printf 'cwd=%s\\n' \"\$(pwd -P)\"
    printf 'input_realpath=%s\\n' \"\$(readlink -f \"$input_file\")\"
    Rscript --vanilla -e \"cat('r_version=', as.character(getRversion()), '\\n', sep='')\"
    printf 'input_contents='
    cat \"$input_file\"
  } > smoke-evidence.txt
  """
}

workflow {
  assert params.smoke_input: 'Set --smoke_input to a small shared-filesystem input'
  assert params.smoke_output: 'Set --smoke_output to a writable shared-filesystem directory'
  assert params.smoke_container: 'Set --smoke_container to a staged local SIF path'

  def input = Channel.fromPath(params.smoke_input, checkIfExists: true)
  schedulerSmoke(input)
}
