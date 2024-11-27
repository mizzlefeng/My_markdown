#!/bin/bash
source /home/multi_omics/software/miniconda3/etc/profile.d/conda.sh
conda activate wes

# 显示帮助信息
helpFunction()
{
   echo ""
   echo "Usage: $0 -d input_directory -o output_directory -p parallel_number --genome VERSION"
   echo -e "\t-i 输入文件夹地址，用户输入文件夹中的文件以fastq.gz结尾，并且为双端测序文件"
   echo -e "\t-o 输出文件夹地址（可选，默认值为../output）"
   echo -e "\t-p 并行数量（可选，默认值为2）"
   echo -e "\t--genome 基因组版本（hg19 或 hg38，默认值为hg19）"
   
   # fastp 参数
   echo -e "\t--suffix qc输出文件后缀（可选，默认值为clean）"
   echo -e "\t--qualified_quality_phred 定义合格质量的最低阈值（默认15）"
   echo -e "\t--length_required 过滤掉长度小于指定值的reads(默认15)"
   echo -e "\t--low_complexity_filter 启用低复杂度reads过滤"
   echo -e "\t--overlap_len_require 指定合并时最小重叠长度（默认30）"
   echo -e "\t--trim_poly_g 去除polyG尾部"
   
   # BWA 参数
   echo -e "\t--threads bwa和samtools使用的线程数（可选，默认值为10）"
   echo -e "\t--rg_lb Read Group的文库名（可选，默认值为WGS）"
   echo -e "\t--rg_pl Read Group的平台（可选，默认值为Illumina）"
   
   # GATK 参数
   echo -e "\t--markdup_options 传递给GATK MarkDuplicates的其他选项（可选）"
   echo -e "\t--bqsr_options 传递给GATK BaseRecalibrator的其他选项（可选）"
   
   # ANNOVAR 参数
   echo -e "\t--annovar_options 传递给ANNOVAR的其他选项（可选）"

   # 检测一致性 参数
   echo -e "\t--detect_paper_data 一致性检测对照的论文结果路径(可选)"

   # 突变克隆 参数
   echo -e "\t--clone_flag 是否突变克隆分析(可选，默认FALSE)"
   
   exit 1 # 退出脚本
}

# 默认参数
input_dir=""
output_dir="../output"
parallel_num=2
genome_version="hg19"
suffix="clean"
threads=10
rg_lb="WGS"
rg_pl="Illumina"
markdup_options=""
bqsr_options=""
annovar_options=""
detect_paper_data=""
clone_flag=False

# fastp
qualified_quality_phred=15
length_required=15
overlap_len_require=30
fastp_params=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o i:o:p:h --long input:,output:,parallel:,genome:,suffix:,qualified_quality_phred:,length_required:,low_complexity_filter,overlap_len_require:,trim_poly_g,threads:,rg_lb:,rg_pl:,markdup_options:,bqsr_options:,annovar_options:,detect_paper_data:,clone_flag,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -i|--input) input_dir="$2"; shift 2 ;;
        -o|--output) output_dir="$2"; shift 2 ;;
        -p|--parallel) parallel_num="$2"; shift 2 ;;
        --genome) genome_version="$2"; shift 2 ;;
        --suffix) suffix="$2"; shift 2 ;;
        --qualified_quality_phred) qualified_quality_phred="$2"; shift 2 ;;
        --length_required) length_required="$2"; shift 2 ;;
        --overlap_len_require) overlap_len_require="$2"; shift 2 ;;
        --low_complexity_filter) fastp_params+=" --low_complexity_filter"; shift ;;
        --trim_poly_g) fastp_params+=" --trim_poly_g"; shift ;;
        --threads) threads="$2"; shift 2 ;;
        --rg_lb) rg_lb="$2"; shift 2 ;;
        --rg_pl) rg_pl="$2"; shift 2 ;;
        --markdup_options) markdup_options="$2"; shift 2 ;;
        --bqsr_options) bqsr_options="$2"; shift 2 ;;
        --annovar_options) annovar_options="$2"; shift 2 ;;
        --detect_paper_data) detect_paper_data="$2"; shift 2;;
        --clone_flag) clone_flag=true; shift ;;
        -h|--help) helpFunction; shift ;;
        --) shift; break ;;
        *) echo "Invalid option"; helpFunction ;;
    esac
done

# 检查是否输入了必须的参数
if [ -z "$input_dir" ]; then
    echo "输入文件夹地址是必须的参数";
    helpFunction
fi

# 创建输出目录
mkdir -p "$output_dir"

# GATK
raw_bam_dir="$output_dir/align/1.raw_bam"
markdup_dir="$output_dir/align/2.MarkDuplicates"
bqsr_dir="$output_dir/align/3.BQSR"
mutect_dir="$output_dir/align/mutect"

# Step 1: 质量控制 (fastp)
#bash /home/multi_omics/genomic_pipeline/script/01.qc.sh -d "$input_dir" -o "$output_dir/clean/" -p "$parallel_num" --suffix "$suffix" --qualified_quality_phred $qualified_quality_phred --length_required $length_required --overlap_len_require $overlap_len_require $fastp_params
#echo -e "QC finished!\n`date`"
#printf '\n%.0s' {1..10}


# Step 2: 比对 (BWA)
#bash /home/multi_omics/genomic_pipeline/script/02.bwa.sh -d "$output_dir/clean" -o "$output_dir/align/1.raw_bam" -p "$parallel_num" --threads "$threads" --rg_lb "$rg_lb" --rg_pl "$rg_pl" --genome "$genome_version"
#echo -e "BWA finished!\n`date`"
#printf '\n%.0s' {1..10}


# Step 3: GATK处理 (MarkDuplicates, BQSR)
bash /home/multi_omics/genomic_pipeline/script/03.gatk.sh -d $raw_bam_dir -m $markdup_dir -b $bqsr_dir -c $mutect_dir -p "$parallel_num" --genome "$genome_version" --markdup_options "$markdup_options" --bqsr_options "$bqsr_options"
echo -e "GATK preprocessing finished!\n`date`"
printf '\n%.0s' {1..10}


# Step 4: 突变注释 (ANNOVAR)
#bash /home/multi_omics/genomic_pipeline/script/04.annovar.sh -d $mutect_dir -o "$output_dir/align/annovar" --genome "$genome_version" --annovar_options "$annovar_options"
#echo -e "ANNOVAR annotation finished!\n`date`"
#printf '\n%.0s' {1..10}


# Step 5: 突变克隆分析 (PyClone)
#if [ "$clone_flag" == true ]; then
#    echo "clone_flag is true, running the clone analysis script..."
#    bash /home/multi_omics/genomic_pipeline/script/05.clone.sh -d "$output_dir/align/annovar" -o "$output_dir/align/clone"
#    printf '\n%.0s' {1..10}
#else
#    printf '\n%.0s' {1..10}
#fi


# Step 6: 一致性检测 (python)
#if [ ! -z "$detect_paper_data" ]; then
#    echo "detect_flag is true, running the Python detect script..."
#    python /home/multi_omics/genomic_pipeline/script/detect.py --root_path "$output_dir/align/annovar" --paper_data "$detect_paper_data"
#else
#    echo ""
#fi
#echo -e "All processes finished!\n`date`"


# test: nohup bash genomic_pipeline.sh -i ../input/ -o /home/multi_omics/moas/data/admin/genome/124 -p 2 --genome hg19 --suffix qc --trim_poly_g --threads 10 --rg_lb WGS --detect_paper_data ./paper_s3.xlsx --clone_flag > custom_output.log 2>&1 &
# /home/multi_omics/moas/data/admin/genome/124/align/annovar
# ../output/