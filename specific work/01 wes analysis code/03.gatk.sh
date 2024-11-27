#!/bin/bash
source activate wes

# 显示帮助信息
helpFunction()
{
   echo ""
   echo "Usage: $0 [-d input_directory] [-o output_directory] [-p parallel_number] [--genome VERSION] [--markdup_options 'OPTIONS'] [--bqsr_options 'OPTIONS']"
   echo -e "\t-d 比对后的文件的地址（可选，默认值为../output/align/1.raw_bam）"
   echo -e "\t-m 处理重复后的文件的地址（可选，默认值为../output/align/2.MarkDuplicates）"
   echo -e "\t-b 矫正后的文件的地址（可选，默认值为../output/align/3.BQSR）"
   echo -e "\t-c 调用突变的地址（可选，默认值为../output/align/mutect）"
   echo -e "\t-p 并行数量（可选，默认值为2）"
   echo -e "\t--genome 基因组版本（hg19 或 hg38，默认值为hg19）"
   echo -e "\t--markdup_options 传递给GATK MarkDuplicates的其他选项（可选）"
   echo -e "\t--bqsr_options 传递给GATK BaseRecalibrator和ApplyBQSR的其他选项（可选）"
   exit 1 # 退出脚本
}

# 默认参数
input_dir="../output/align/1.raw_bam"
parallel_num=2
genome_version="hg19"
markdup_options=""
bqsr_options=""

# 解析输入参数
PARSED_OPTIONS=$(getopt -o d:m:b:c:p:h --long input:,parallel:,genome:,markdup_options:,bqsr_options:,help -- "$@")
if [ $? -ne 0 ]; then
    helpFunction
fi

eval set -- "$PARSED_OPTIONS"
while true; do
    case "$1" in
        -d|--input) input_dir="$2"; shift 2 ;;
        -m|--markdupdir) markdup_dir="$2"; shift 2 ;;
        -b|--bqsrdir) bqsr_dir="$2"; shift 2 ;;
        -c|--mutect) mutect_dir="$2"; shift 2 ;;
        -p|--parallel) parallel_num="$2"; shift 2 ;;
        --genome) genome_version="$2"; shift 2 ;;
        --markdup_options) markdup_options="$2"; shift 2 ;;
        --bqsr_options) bqsr_options="$2"; shift 2 ;;
        -h|--help) helpFunction; shift ;;
        --) shift; break ;;
        *) echo "Invalid option"; helpFunction ;;
    esac
done

# 检查是否输入处理重复文件夹地址
if [ -z "$markdup_dir" ]
then
   mkdir -p "../output/align/2.MarkDuplicates"
   markdup_dir="../output/align/2.MarkDuplicates"
else
   mkdir -p "$markdup_dir"
fi

# 检查是否输入处理矫正文件夹地址
if [ -z "$bqsr_dir" ]
then
   mkdir -p "../output/align/3.BQSR"
   bqsr_dir="../output/align/3.BQSR"
else
   mkdir -p "$bqsr_dir"
fi

# 检查是否输入call mutation文件夹地址
if [ -z "$mutect_dir" ]
then
   mkdir -p "../output/align/mutect"
   bqsr_dir="../output/align/mutect"
else
   mkdir -p "$mutect_dir"
fi

# 设置基因组版本相关的资源路径
if [ "$genome_version" == "hg19" ]; then
    ref=~/database/ref/hg19/hg19.fasta
    snp=~/database/gatk_resource/hg19/dbsnp_138.hg19.vcf
    indel=~/database/gatk_resource/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
    knownIndels=~/database/gatk_resource/hg19/1000G_phase1.indels.hg19.sites.vcf
    bed=~/database/ref/hg19/bed/hg19.bed
    af_only_gnomad=~/database/gatk_resource/hg19/af-only-gnomad.hg19.raw.sites.vcf
    pon=~/database/gatk_resource/hg19/Mutect2-exome-panel.hg19.vcf
elif [ "$genome_version" == "hg38" ]; then
    ref=~/database/ref/hg38/Homo_sapiens_assembly38.fasta
    snp=~/database/gatk_resource/hg38/dbsnp_138.hg38.vcf.gz
    indel=~/database/gatk_resource/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
    knownIndels=~/database/gatk_resource/hg38/Homo_sapiens_assembly38.known_indels.vcf.gz
    bed=~/database/ref/hg38/bed/hg38.bed
    af_only_gnomad=~/database/gatk_resource/hg38/af-only-gnomad.hg38.vcf.gz
    pon=~/database/gatk_resource/hg38/1000g_pon.hg38.vcf.gz
else
    echo "不支持的基因组版本：$genome_version"
    exit 1
fi

echo "$parallel_num 个任务并行执行..."
config=./config


echo "####GATK参数####"
echo "Input Directory: $input_dir"
echo "Markdup Directory: $markdup_dir"
echo "BQSR Directory: $bqsr_dir"
echo "Mutect Output Directory: $mutect_dir"
echo "Parallel Number: $parallel_num"
echo "Genome Version: $genome_version"

gatkpreparal(){

    aligndir=${input_dir}
    markdupdir=${markdup_dir}
    bqsrdir=$bqsr_dir
    mutectdir=$mutect_dir

    startTime=`date +"%Y-%m-%d %H:%M:%S"`
    if [ ! -f ${markdupdir}/${1}_marked.bam ]; then
        echo -e "\nstart MarkDuplicates for ${1}" `date`
        gatk --java-options "-Xmx20G -Djava.io.tmpdir=${markdupdir}" MarkDuplicates \
            -I ${aligndir}/${1}.bam \
            --REMOVE_DUPLICATES true \
            -O ${markdupdir}/${1}_marked.bam \
            -M ${markdupdir}/${1}.metrics \
            $markdup_options \
            1>${markdupdir}/${1}_log.mark 2>&1 
        echo "end MarkDuplicates for ${1}" `date`
        samtools index ${markdupdir}/${1}_marked.bam
    fi

    if [ ! -f ${bqsrdir}/${1}_recal.table ]; then
        echo -e "\nstart BaseRecalibrator for ${1}" `date`
        gatk --java-options "-Xmx20G -Djava.io.tmpdir=${bqsrdir}"  BaseRecalibrator \
            -R $ref \
            -I ${markdupdir}/${1}_marked.bam \
            --known-sites $snp \
            --known-sites $indel \
            --known-sites $knownIndels \
            -L $bed \
            -O ${bqsrdir}/${1}_recal.table \
            $bqsr_options \
            1>${bqsrdir}/${1}_log.recal 2>&1
        echo "end BaseRecalibrator for ${1}" `date`
    fi

    if [ ! -f ${bqsrdir}/${1}_bqsr.bam ]; then
        echo -e "\nstart ApplyBQSR for ${1}" `date`
        gatk --java-options "-Xmx20G -Djava.io.tmpdir=${bqsrdir}" ApplyBQSR \
            -R $ref \
            -I ${markdupdir}/${1}_marked.bam \
            -bqsr ${bqsrdir}/${1}_recal.table \
            -L $bed \
            -O ${bqsrdir}/${1}_bqsr.bam \
            1>${bqsrdir}/${1}_log.ApplyBQSR 2>&1
        echo "end ApplyBQSR for ${1}" `date`
    fi

    # 删除临时文件
    rm ${bqsrdir}/tmp_read_resource*

    if [ ! -f ${mutectdir}/${1}_somatic.vcf.gz ]; then
        echo -e "\nstart mutect for ${1}" `date`
        gatk --java-options "-Xmx20G" Mutect2 \
            -R ${ref} \
            -I ${bqsrdir}/${1}_bqsr.bam \
            --germline-resource ${af_only_gnomad} \
            --panel-of-normals ${pon} \
            --af-of-alleles-not-in-resource 0.0000025 \
            --disable-read-filter MateOnSameContigOrNoMappedMateReadFilter \
            -L ${bed} \
            -O ${mutectdir}/${1}_somatic.vcf.gz
            1>${mutectdir}/${1}_log.HC 2>&1
        echo -e "\nend mutect for ${1}" `date`
    fi
    
    if [ ! -f ${mutectdir}/${1}_somatic_filter.vcf ]; then
        echo -e "\nstart filter for ${1}" `date`
            gatk FilterMutectCalls \
            -R $ref \
            -V ${mutectdir}/${1}_somatic.vcf.gz \
            -O ${mutectdir}/${1}_somatic_filter.vcf
            echo "end filter for ${1}" `date`
    fi

    endTime=`date +"%Y-%m-%d %H:%M:%S"`
    st=`date -d  "$startTime" +%s`
    et=`date -d  "$endTime" +%s`
    sumTime=$(($et-$st))
    echo -e "\n样本：${1}  耗时：$sumTime 秒！"
}

export -f gatkpreparal
export input_dir markdup_dir bqsr_dir mutect_dir ref snp indel knownIndels bed af_only_gnomad pon markdup_options bqsr_options
cat $config | parallel -k -j$parallel_num gatkpreparal

# demo bash 03.gatk.sh -d /home/multi_omics/genomic_pipeline/qc_test/bwa/ -m ../qc_test/markdup/ -b ../qc_test/bqsr/ -c ../qc_test/mutect/ -p 2 --genome hg38
