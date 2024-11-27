#!/bin/bash
# 显示帮助信息
helpFunction()
{
   echo ""
   echo "Usage: $0 -d input_directory [-o output_directory] [-p parallel_number] [--suffix N] [--qualified_quality_phred N] [--length_required N] [--low_complexity_filter] [--overlap_len_require N] [--trim_poly_g]"
   echo -e "\t-d qc输入文件夹地址，用户输入文件夹中的文件以fastq.gz结尾，并且为双端测序文件，形如{sample_name}_{reads num}"
   echo -e "\t-o qc输出文件夹地址（可选，默认值为../output/clean）"
   echo -e "\t-p 并行数量（可选，默认值为2）"
   echo -e "\t--suffix qc输出文件后缀（可选，默认值为clean）"
   echo -e "\t--qualified_quality_phred 定义合格质量的最低阈值（默认15）"
   echo -e "\t--length_required 过滤掉长度小于指定值的reads(默认15)"
   echo -e "\t--low_complexity_filter 启用低复杂度reads过滤"
   echo -e "\t--overlap_len_require 指定合并时最小重叠长度（默认30）"
   echo -e "\t--trim_poly_g 去除polyG尾部"
   exit 1 # 退出脚本
}

# 默认参数
suffix="clean"
parallel_num=2
fastp_params=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o d:o:p:h --long input:,output:,parallel:,suffix:,qualified_quality_phred:,length_required:,low_complexity_filter,overlap_len_require:,trim_poly_g,cut_by_quality5,cut_by_quality3,cut_mean_quality:,thread:,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

# 解析成功的选项并设置变量
eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -d|--input) input_dir="$2"; shift 2 ;;
        -o|--output) output_dir="$2"; shift 2 ;;
        -p|--parallel) parallel_num="$2"; shift 2 ;;
        --suffix) suffix="$2"; shift 2 ;;
        --qualified_quality_phred) fastp_params+=" --qualified_quality_phred $2"; shift 2 ;;
        --length_required) fastp_params+=" --length_required $2"; shift 2 ;;
        --low_complexity_filter) fastp_params+=" --low_complexity_filter"; shift ;;
        --overlap_len_require) fastp_params+=" --overlap_len_require $2"; shift 2 ;;
        --trim_poly_g) fastp_params+=" --trim_poly_g"; shift ;;
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

if [ -z "$output_dir" ]
then
   mkdir -p "../output/clean"
   output_dir="../output/clean"
else
   mkdir -p "$output_dir"
fi

# 剩下的脚本逻辑继续使用这些参数
echo "####QC参数####"
echo "Input Directory: $input_dir"
echo "Output Directory: $output_dir"
echo "Suffix: $suffix"
echo "Parallel Number: $parallel_num"
echo "Fastp_params: $fastp_params"

> config
# 自动识别并提取样本名
ls ${input_dir}*_1*.fastq.gz | while read R1_file; do
    R2_file=${R1_file/_1/_2}
    if [ -e "$R2_file" ]; then
        sample_name=$(basename "$R1_file" | sed 's/_1.*//')
        echo "$sample_name" >> config
    fi
done
config="./config"

fastparal(){
   echo "Processing $1"
   fastp=~/software/fastp
   cleandir="${output_dir}"

   $fastp -i ${input_dir}$1_1.fastq.gz -I ${input_dir}/$1_2.fastq.gz -o $cleandir/${1}_${suffix}_1.fastq.gz -O $cleandir/${1}_${suffix}_2.fastq.gz -j $cleandir/$1.json -h $cleandir/$1.html $fastp_params > $cleandir/$1.log.fastp 2>&1
}
export -f fastparal
export input_dir output_dir suffix fastp_params
cat $config | parallel -j$parallel_num fastparal

#demo:bash 01.qc.sh -d ../raw/ -p 2 -o ../output/