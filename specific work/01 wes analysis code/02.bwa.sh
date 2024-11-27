#!/bin/bash
source activate wes

# 显示帮助信息
helpFunction()
{
   echo ""
   echo "Usage: $0 [-d input_directory] [-o output_directory] [-p parallel_number] [--threads N] [--rg_lb LB] [--rg_pl PL] [--genome N]"
   echo -e "\t-d qc后的文件的地址（可选，默认值为../output/clean）"
   echo -e "\t-o 比对后的文件的地址（可选，默认值为../output/align/1.raw_bam）"
   echo -e "\t-p 并行数量（可选，默认值为2）"
   echo -e "\t--threads bwa和samtools使用的线程数（可选，默认值为10）"
   echo -e "\t--rg_lb Read Group的文库名（可选，默认值为WES）"
   echo -e "\t--rg_pl Read Group的平台（可选，默认值为Illumina）"
   echo -e "\t--genome 基因组版本（hg19 或 hg38，默认值为hg19）"
   exit 1 # 退出脚本
}

# 默认参数
input_dir="../output/clean"
parallel_num=2
threads=10
rg_lb="WES"
rg_pl="Illumina"
genome_version="hg19"
bwa_options=""
samtools_options=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o d:o:p:h --long input:,output:,parallel:,threads:,rg_lb:,rg_pl:,genome:,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -d|--input) input_dir="$2"; shift 2 ;;
        -o|--output) output_dir="$2"; shift 2 ;;
        -p|--parallel) parallel_num="$2"; shift 2 ;;
        --threads) threads="$2"; shift 2 ;;
        --rg_lb) rg_lb="$2"; shift 2 ;;
        --rg_pl) rg_pl="$2"; shift 2 ;;
        --genome) genome_version="$2"; shift 2 ;;
        -h|--help) helpFunction; shift ;;
        --) shift; break ;;
        *) echo "Invalid option"; helpFunction ;;
    esac
done

config=./config
if [ -z "$output_dir" ]
then
   mkdir -p "../output/align/1.raw_bam"
   output_dir="../output/align/1.raw_bam"
else
   mkdir -p "$output_dir"
fi

# 设置基因组版本对应的参考基因组路径
if [ "$genome_version" == "hg19" ]; then
    INDEX=~/database/ref/hg19/hg19
elif [ "$genome_version" == "hg38" ]; then
    INDEX=~/database/ref/hg38/Homo_sapiens_assembly38.fasta
else
    echo "不支持的基因组版本：$genome_version"
    exit 1
fi

echo "####BWA参数####"
echo "Input Directory: $input_dir"
echo "Output Directory: $output_dir"
echo "Parallel Number: $parallel_num"
echo "Rg_lb: $rg_lb"
echo "Rg_pl: $rg_pl"
echo "Genome Version: $genome_version"

bwa_parallel(){
    id=$1
    aligndir=${output_dir}
    cleandir=${input_dir}
    fq1="$cleandir/${id}_*_1.fastq.gz"
    fq2="$cleandir/${id}_*_2.fastq.gz"

    echo "${id} bwa start~" `date`
    bwa mem -t "$threads" -M -R "@RG\tID:$id\tSM:$id\tLB:$rg_lb\tPL:$rg_pl" $INDEX $fq1 $fq2 | \
    samtools sort -@ "$threads" -o $aligndir/${id}.bam -
    echo "${id} bwa completed~" `date`
}

export -f bwa_parallel
export input_dir output_dir threads rg_lb rg_pl INDEX
cat $config | parallel -j$parallel_num -k --load 80% bwa_parallel

# demo bash 02.bwa.sh -d ../qc_test/ -o ../qc_test/bwa/ -p 2 --threads 11 --rg_lb WGS --rg_pl seu --genome hg38
