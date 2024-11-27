#!/bin/bash
source activate wes

# 显示帮助信息
helpFunction()
{
   echo ""
   echo "Usage: $0 -d input_directory [-o output_directory] [--genome VERSION] [--annovar_options 'OPTIONS']"
   echo -e "\t-d 体细胞突变过滤后的vcf文件的根地址"
   echo -e "\t-o 注释文件根地址（可选，../output/align/annovar）"
   echo -e "\t--genome 基因组版本（hg19 或 hg38，默认值为hg19）"
   echo -e "\t--annovar_options 传递给ANNOVAR的其他选项（可选）"
   exit 1 # 退出脚本
}

# 默认参数
input_dir=""
genome_version="hg19"
annovar_options=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o d:o:h --long input:,genome:,annovar_options:,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -d|--input) input_dir="$2"; shift 2 ;;
        -o|--output) output_dir="$2"; shift 2 ;;
        --genome) genome_version="$2"; shift 2 ;;
        --annovar_options) annovar_options="$2"; shift 2 ;;
        -h|--help) helpFunction; shift ;;
        --) shift; break ;;
        *) echo "Invalid option"; helpFunction ;;
    esac
done

# 检查是否输入文件夹地址
if [ -z "$input_dir" ]; then
   echo "体细胞突变过滤后的vcf文件的根地址是必须的参数";
   helpFunction
fi

# 检查是否输入处理矫正文件夹地址
if [ -z "$output_dir" ]
then
   mkdir -p "../output/align/annovar"
   output_dir="../output/align/annovar"
else
   mkdir -p "$output_dir"
fi

# 创建输出目录
annovar_script_file=~/software/annovar
config=./config

echo "####ANNOVAR参数####"
echo "Input Directory: $input_dir"
echo "Output Directory: $output_dir"
echo "使用基因组版本：$genome_version"

# 设置基因组版本相关的数据库路径
if [ "$genome_version" == "hg19" ]; then
    humandb=~/software/annovar/humandb
    # 处理每个样本
    cat ${config} | while read id
    do
        ${annovar_script_file}/table_annovar.pl ${input_dir}/${id}_somatic_filter.vcf $humandb \
            -buildver hg19 --thread 12 \
            -out ${output_dir}/${id} \
            -remove \
            -protocol refGene,knownGene,clinvar_20220320 \
            -operation g,g,f \
            -nastring . \
            -vcfinput \
            $annovar_options
        echo -e "\n样本：${id} finished!"
    done
elif [ "$genome_version" == "hg38" ]; then
    humandb=~/software/annovar/humandb/hg38_humandb
    cat ${config} | while read id
    do
        ${annovar_script_file}/table_annovar.pl ${input_dir}/${id}_somatic_filter.vcf $humandb \
            -buildver hg38 --thread 12 \
            -out ${output_dir}/${id} \
            -remove \
            -protocol refGene,knownGene,clinvar_20240502 \
            -operation g,g,f \
            -nastring . \
            -vcfinput
        echo -e "\n样本："${id}"  finished!"
    done
else
    echo "不支持的基因组版本：$genome_version"
    exit 1
fi

#-protocol refGene,knownGene,clinvar_20240502,1000g2015aug_eas,exac03,gnomad40_exome,esp6500siv2_all,avsnp151,dbnsfp47a,dbscsnv11,cosmic99 \



