workflow {
  def root = params.ref_rootdir.toString()
  def barcodeDir = params.barcode_dir.toString()
  def probesDir = params.probes_dir.toString()

  assert !root.startsWith('s3://'): "ref_rootdir unexpectedly points to S3: ${root}"
  assert barcodeDir == "${root}/barcodes/10X":
    "barcode_dir did not follow ref_rootdir: ${barcodeDir}"
  assert probesDir == "${root}/flex-probe-refs":
    "probes_dir did not follow ref_rootdir: ${probesDir}"

  def requiredPaths = [
    "${root}/homo_sapiens/ensembl-104/salmon_index/Homo_sapiens.GRCh38.104.spliced_intron.txome",
    "${root}/homo_sapiens/ensembl-104/annotation/Homo_sapiens.GRCh38.104.gtf.gz",
    "${root}/homo_sapiens/ensembl-104/annotation/Homo_sapiens.GRCh38.104.mitogenes.txt",
    "${root}/homo_sapiens/ensembl-104/annotation/Homo_sapiens.GRCh38.104.spliced_intron.tx2gene_3col.tsv",
    "${barcodeDir}/3M-february-2018.txt"
  ]
  requiredPaths.each { path ->
    assert file(path).exists(): "Required local reference is missing: ${path}"
  }

  println "REF_ROOT=${root}"
  println "BARCODE_DIR=${barcodeDir}"
  println "PROBES_DIR=${probesDir}"
}
