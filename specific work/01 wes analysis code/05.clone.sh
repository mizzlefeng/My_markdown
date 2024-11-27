#!/bin/bash
source /home/multi_omics/software/miniconda3/etc/profile.d/conda.sh
conda activate wes

helpFunction()
{
   echo ""
   echo "Usage: $0 -d input_directory [-o output_directory]"
   echo -e "\t-d 注释过滤后的txt文件的根地址"
   echo -e "\t-o 指定克隆分析的输出文件夹（可选，../output/align/clone）"
   exit 1 # 退出脚本
}

# 默认参数
output_dir=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o d:o:h --long input:,output:,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -d|--input) input_dir="$2"; shift 2 ;;
        -o|--output) output_dir="$2"; shift 2 ;;
        -h|--help) helpFunction; shift ;;
        --) shift; break ;;
        *) echo "Invalid option"; helpFunction ;;
    esac
done

# 检查是否输入文件夹地址
if [ -z "$input_dir" ]; then
   echo "注释过滤后的txt文件的根地址是必须的参数";
   helpFunction
fi

# 检查是否输入处理矫正文件夹地址
if [ -z "$output_dir" ]
then
   mkdir -p "../output/align/clone/data"
   output_dir="../output/align/clone"
else
   mkdir -p "$output_dir/data"
fi

# 检查是否输入文件夹地址
if [ -z "$input_dir" ]; then
   echo "注释过滤后的txt文件的根地址是必须的参数";
   helpFunction
fi

if [ ! -e "./clone_config" ]; then
   echo "克隆分析的config文件缺失！"
fi

# 创建输出目录
mkdir -p "$output_dir/result"

echo "####PyClone参数####"
echo "Input Directory: $input_dir"
echo "Output Directory: $output_dir"

python /home/multi_omics/genomic_pipeline/script/prepare_data.py --folder_path $input_dir --output_path ${output_dir}/data

source /home/multi_omics/software/miniforge3/etc/profile.d/conda.sh
conda activate pyclone

clone_config=./clone_config
#ls ${output_dir}/data/*.csv | xargs -n 1 basename > ${output_dir}/clone_config
#config=${output_dir}/clone_config
#cat $config|awk -F "_" '{print $1}'|awk -F "-" '{print $1}'|uniq > ${output_dir}/config
#clone_config=${output_dir}/config
#rm ${output_dir}/clone_config

#cat $clone_config | while read id
#do
#echo $id
#PyClone run_analysis_pipeline --in_files ${output_dir}/data/${id}*csv --working_dir ${output_dir}/result/${id}_pyclone_analysis --num_iters 500
#done

# 读取clone_config文件
while IFS=$'\t' read -r -a columns
do
    # 获取ID号（最后一列）
    id="${columns[-1]}"

    # 拼接样本文件路径
    in_files=""
    for ((i = 0; i < ${#columns[@]} - 1; i++)); do
        sample="${columns[i]}"
        in_files+="${output_dir}/data/${sample}*.csv "
    done

    # 去掉最后多余的空格
    in_files=$(echo "$in_files" | sed 's/ *$//')

    # 运行PyClone命令
    echo "Processing ID: $id with samples: $in_files"
    PyClone run_analysis_pipeline --in_files $in_files --working_dir ${output_dir}/result/${id}_pyclone_analysis --num_iters 500 --seed 10

done < "$clone_config"


#bash genomic_pipeline.sh -i ../input/ -o /home/multi_omics/moas/data/test/genome/102/ --clone_flag
#PyClone run_analysis_pipeline --in_files ${output_dir}/SRR7739529.*csv ${output_dir}/SRR7739530.*csv --working_dir ${output_dir}/54_pyclone_analysis --num_iters 500

