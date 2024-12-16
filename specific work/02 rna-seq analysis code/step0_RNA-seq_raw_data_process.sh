#!/bin/bash

# Description: The procedure of RNA-seq rawdata processing and obtaining gene expression data matrixes

# 01Start: Quality assessment for raw data
echo "Starting quality assessment for raw data..."
cd Data/RNA-seq/rawdata/
fastqc -o Data/RNA-seq/qc_results/ -t 10 *R1.fq.gz *R2.fq.gz
multiqc Data/RNA-seq/qc_results/ -o Data/RNA-seq/qc_results/multiqc_report/ -n multiqc_report
echo "Quality assessment for raw data completed."

# 02Start: Trimming the sequence reads to get clean data
echo "Starting trimming of sequence reads..."
cd Data/RNA-seq/rawdata/
ls | grep R1.fq.gz > gz1
ls | grep R2.fq.gz > gz2
paste gz1 gz2 > config

dir=Data/RNA-seq/clean_data/
while read fq1 fq2; do
    nohup trim_galore --output_dir $dir --paired --phred33 --illumina --gzip $fq1 $fq2 &
done < config

wait # Wait for all background processes to finish
echo "Trimming of sequence reads completed."

# 03Start: Quality assessment for clean data
echo "Starting quality assessment for clean data..."
cd Data/RNA-seq/clean_data
fastqc -o Data/RNA-seq/qc_results/ -t 10 *R1.fq.gz *R2.fq.gz
multiqc Data/RNA-seq/re_qc_results/ -o Data/RNA-seq/re_qc_results/multiqc_report/ -n multiqc_report
echo "Quality assessment for clean data completed."

# 04Start: Data alignment
echo "Starting data alignment..."
STAR --runMode genomeGenerate --genomeDir Data/RNA-seq/reference_genome/index_dir \
   --genomeFastaFiles Data/RNA-seq/reference_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
   --runThreadN 30 --sjdbGTFfile Data/RNA-seq/reference_genome/Homo_sapiens.GRCh38.107.gtf --sjdbOverhang 149

cd Data/RNA-seq/aligned_data
while read fq1 fq2; do
    nohup STAR --runMode alignReads --genomeDir Data/RNA-seq/reference_genome/index_dir \
        --readFilesCommand zcat --runThreadN 40 --quantMode TranscriptomeSAM GeneCounts \
        --genomeLoad LoadAndRemove --outSAMtype BAM Unsorted --readFilesIn $fq1 $fq2 \
        --outFileNamePrefix Data/RNA-seq/aligned_data/$(basename $fq1 .fq.gz) &
done < Data/RNA-seq/rawdata/config

wait # Wait for all background processes to finish
echo "Data alignment completed."

# 05Start: Gene expression quantification
echo "Starting gene expression quantification..."
cd Data/RNA-seq/reference_genome/
rsem-prepare-reference --gtf Homo_sapiens.GRCh38.107.gtf --star Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    RSEM_index/human_ensembl -p 40

cd Data/RNA-seq/exp_matrix/
while read bam1; do
    arr=(${bam1//_/ })
    nohup rsem-calculate-expression --bam --paired-end -no-bam-output -p 40 \
        Data/RNA-seq/aligned_data/$bam1 Data/RNA-seq/reference_genome/RSEM_index/human_ensembl ${arr[0]} &
done < manifest_rsem.txt

wait # Wait for all background processes to finish
echo "Gene expression quantification completed."

# 06Start: Integration into the expression matrix (in R software)
echo "Starting integration into the expression matrix (R script)..."
Rscript -e "
result_dir <- 'Data/RNA-seq/exp_matrix/'
gene_exp_files <- dir(result_dir)
gene_exp_files <- gene_exp_files[grep('genes.results', gene_exp_files)]

count_data <- c()
TPM_data <- c()
FPKM_data <- c()

for (file_i in gene_exp_files) {
  sample_exp_data <- read.table(paste0(result_dir, file_i), header=T, fill=T)
  count_data <- cbind(count_data, sample_exp_data\$expected_count)
  TPM_data <- cbind(TPM_data, sample_exp_data\$TPM)
  FPKM_data <- cbind(FPKM_data, sample_exp_data\$FPKM)
}

colnames(count_data) <- colnames(TPM_data) <- colnames(FPKM_data) <- unlist(strsplit(gene_exp_files, '.R1.genes.results'))
rownames(count_data) <- rownames(TPM_data) <- rownames(FPKM_data) <- sample_exp_data\$gene_id

write.table(count_data, file='count_data.txt', sep='\t', quote=F)
write.table(TPM_data, file='TPM_data.txt', sep='\t', quote=F)
write.table(FPKM_data, file='FPKM_data.txt', sep='\t', quote=F)
"
echo "Integration into the expression matrix completed."

echo "RNA-seq data processing completed."