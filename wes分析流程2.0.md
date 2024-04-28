# 安装软件及数据库

## 安装fastp

```shell
# 下载fastp
wget http://opengene.org/fastp/fastp
chmod 755 fastp #给可执行权限

# 将常用软件都写入环境变量
echo 'export PATH="~/software:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 安装conda

```shell
# 下载最新版
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# 直接安装
bash Miniconda3-py37_4.12.0-Linux-x86_64.sh

#安装全程要选yes，中间某一步(conda 初始化)默认是 no，一定要选yes，如下图：
```

![1677218526816](assets/1677218526816.png)

```shell
# 创建新环境
conda create -n wes python=3.7
# 查看当前系统所有的conda环境
conda info -e
conda env list
```

## 安装bwa、samtools

```shell
conda install -c bioconda samtools
conda install -c bioconda bwa
```

## 安装数据库

### hg38

主要从https://console.cloud.google.com/storage/browser/gcp-public-data--broad-references/hg38/v0下载

```shell
# 在linux查看目录  与https://console.cloud.google.com/storage/browser/gcp-public-data--broad-references/hg38/v0  2019年最新  内容一致，但是gcp-public-data--broad-references的内容更多，推荐直接多选，然后使用gsutil下载
lftp ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/

# 下载所有的内容
nohup wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/* &

# somatic calling时，无正常对照可能需要特殊的文件，PON使用1000g_pon.hg38.vcf.gz
# 下面两个文件的下载地址：https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38
af-only-gnomad.hg38.vcf.gz
1000g_pon.hg38.vcf.gz

# https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/  2016年
```

### hg19

主要从ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/下载

```shell
# 在linux查看目录
lftp ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/

下载所有的内容
nohup wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/* &

# 制作total md5文件并核查md5码
less *md5 | awk -F '  ' '{split($2,a,"/"); $2=a[length(a)]}1' OFS='\t' > total.md5
md5sum -c total.md5

# 下载VQSR的特殊文件：Axiom_Exome_Plus.genotypes.all_populations.poly.vcf.gz
# 谷歌存储桶网站：
https://console.cloud.google.com/storage/browser/gcp-public-data--broad-references/hg19/v0  # 2019年最新  主要是b37的文件

# 如果用hg19，在https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-b37中存在af-only-gnomad文件。
# af-only-gnomad.hg19.vcf.gz由LiftoverVcf从b37版本提升得来
```

### 安装gsutil

使用gsutil工具批量下载谷歌云存储桶中的文件

```shell
cd /安装目录
 
#下载压缩包
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-367.0.0-linux-x86_64.tar.gz
 
#解压
tar zxvf google-cloud-sdk-367.0.0-linux-x86_64.tar.gz
 
cd /安装目录/google-cloud-sdk
install.sh 或者 bash install.sh
```





## 制作bed文件

三种方法：1.官网直接下载；2.shell语言整理ccds；3.python整理ccds。推荐3。

### 官网直接下载

NCCL室间质评推荐使用的外显子bed是UCSC的hg19外显子bed，而推荐使用的TMB计算区间则是CCDS的交集。下面介绍怎么获得这两个bed。

使用[UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables)，assembly选择GRCh37/hg19，track选择NCBI RefSeq，output format选择BED，然后选择get output，再在下一个页面中选择Exons plus 0。点击get Bed即是外显子bed。需注意的是，这个bed包含同一基因的多个转录本。

对于CDS区域（即外显子区域去除UTR3），可以在上一步选择Coding Exons，然后获得bed。

### shell

```shell
#CCDS官网
https://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=SHOW_STATISTICS

#下载最新的CCDS文件
wget https://ftp.ncbi.nlm.nih.gov/pub/CCDS/current_human/CCDS.20221027.txt  
conda install bedtools

# 非常重要  http://www.360doc.com/content/21/0714/12/76149697_986499857.shtml
cat CCDS.20221027.txt |grep -w -v Withdrawn|perl -alne '{/\[(.*?)\]/;next unless $1;$gene=$F[2];$exons=$1;$exons=~s/\s//g;$exons=~s/-/\t/g;print "$F[0]\t$_\t$gene" foreach split/,/,$exons;}'|sort -u |bedtools sort -i |awk '{print "chr"$0"\t0\t+"}' >hg38.exon.bed

# 输出hg38.exon.bed最好加上这一行，这是因为GATK在识别bed文件时会出现染色体起始位置小于终止位置的情况。即使这两个地方是相等的。 参考：https://github.com/broadinstitute/gatk/issues/4504
awk '{if ($2==$3) {print $1"\t"$2"\t"$3+1"\t"$4} else {print $1"\t"$2"\t"$3"\t"$4}}' hg38.exon.bed > exon.bed  


# hg19的bed文件制作
wget https://ftp.ncbi.nlm.nih.gov/pub/CCDS/archive/15/CCDS.20131129.txt
cat CCDS.20131129.txt |grep -w -v Withdrawn|perl -alne '{/\[(.*?)\]/;next unless $1;$gene=$F[2];$exons=$1;$exons=~s/\s//g;$exons=~s/-/\t/g;print "$F[0]\t$_\t$gene" foreach split/,/,$exons;}'|sort -u |bedtools sort -i |awk '{print "chr"$0"\t0\t+"}' >hg19.exon.bed
awk '{if ($2!=$3) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6} }' hg19.exon.bed > hg19_exon.bed  
```

### python

```python
# https://pzweuj.github.io/2022/05/17/NCCL-bed.html

# 另外可以从NCBI获取CCDS的bed。对于GRCh37，最新的版本是Hs105。网址为：https://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=SHOW_STATISTICS
wget https://ftp.ncbi.nlm.nih.gov/pub/CCDS/archive/Hs105/CCDS.current.txt

# 使用下面的python脚本转换为bed格式，需要注意的是，CCDS中的坐标需要加1。
ccds = open("CCDS.current.txt", "r", encoding="utf-8")
ccdsBed = open("CCDS.bed", "w", encoding="utf-8")
for line in ccds:
    if not line.startswith("#"):
        lines = line.split("\t")
        chrom = lines[0]
        gene = lines[2]
        ccds_id = lines[4]
        ccds_status = lines[5]
        cds_strand = lines[6]
        cds_locations = lines[9]

        chrom = "chr" + chrom

        if ccds_status != "Public":
            continue

        n = 0
        cdsList = cds_locations.replace("[", "").replace("]", "").split(", ")
        if cds_strand == "-":
            cdsList = cdsList[::-1]
        for c in cdsList:
            n += 1
            exonNum = str(n)
            cLoc = c.split("-")
            start = str(int(cLoc[0])) # gatk对于bed文件的start会自加1
            end = str(int(cLoc[1]) + 1)
            # name = gene + "_" + ccds_id + "_exon" + exonNum

            ccdsBed.write("\t".join([chrom, start, end, gene, cds_strand]) + "\n")

ccdsBed.close()
ccds.close()

```



## 安装qualimap

```
wget https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.2.1.zip
unzip qualimap_v2.2.1.zip
```



## 下载GATK

```shell
# 加--no-check-certificate和--user-agent是防止Unable to establish SSL connection的问题
wget https://github.com/broadinstitute/gatk/releases/download/4.3.0.0/gatk-4.3.0.0.zip --no-check-certificate --user-agent="Mozilla/5.0 (X11;U;Linux i686;en-US;rv:1.9.0.3) Geco/2008092416 Firefox/3.0.3"
unzip gatk-4.3.0.0.zip

# 将GATK添加到环境变量（可选）
vim ~/.bahsrc
# 在最后一行添加
export PATH="/home/fsd/software/gatk-4.3.0.0:$PATH"
#激活环境
source ~/.bashrc
```

## 安装ANNOVAR及下载hg38数据库

```SHELL
# 安装annovar 不用单独建立一个文件夹
wget http://www.openbioinformatics.org/annovar/download/0wgxR2rIVP/annovar.latest.tar.gz
tar -zxvf annovar.latest.tar.gz # 解压
# 写入环境变量
vim ~/.bashrc
export PATH="/home/fsd/software/annovar:$PATH"
source ~/.bashrc # 不要忘了，要激活一下！

#下载hg38可下载的数据库的list：hg38_avdblist.txt
annotate_variation.pl -downdb -webfrom annovar avdblist ./ -buildver hg38
# 或者
wget http://www.openbioinformatics.org/annovar/download/hg38_avdblist.txt.gz ./ 

#下面是所需数据库
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGene.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneVersion.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneWithVerMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneWithVer.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_knownGene.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_knownGeneMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_kgXref.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_clinvar_20220320.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_clinvar_20220320.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_exac03.txt.gz  & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_exac03.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_esp6500siv2_all.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_esp6500siv2_all.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_1000g2014oct.zip & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_1000g2015aug.zip &

nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_dbnsfp42a.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_dbnsfp42a.txt.idx.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.idx.gz &


nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_gnomad_exome.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_gnomad_exome.txt.idx.gz &



# 下载hg19
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGene.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneVersion.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneWithVerMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_refGeneWithVer.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_knownGene.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_knownGeneMrna.fa.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_clinvar_20220320.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_clinvar_20220320.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg19_kgXref.txt.gz &
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_avsnp150.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_exac03.txt.gz  & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_exac03.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_esp6500siv2_all.txt.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_esp6500siv2_all.txt.idx.gz & 
nohup wget -c http://www.openbioinformatics.org/annovar/download/hg38_1000g2015aug.zip &
```

## 安装cnvkit

```shell
conda create -n cnvkit python=3.9
conda activate cnvkit
conda search cnvkit # conda安装报错，用pip安装吧
pip install cnvkit==0.9.9 -i https://mirrors.aliyun.com/pypi/simple/

# 后来出现问题configure: error: libbzip2 development files not found，解决方案如下：
yum -y install bzip2-devel
yum -y install xz-devel

# 出现报错 cannot import name 'Int64Index' from 'pandas'解决方案如下：
pip install pandas==1.3.5

# 需要安装依赖的R包
conda search R
conda install -c conda-forge r-base=4.0
.libPaths()
which R
cd /home/mizzle/miniconda3/envs/cnvkit/lib/R
cd etc
vim Rprofile.site
options("repos" = c(CRAN="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
options(BioC_mirror="https://mirrors.tuna.tsinghua.edu.cn/bioconductor")

# 参考网站：https://blog.csdn.net/x_yAOTU/article/details/126141223

# 参考网站 装一些必备的R包，cnvkit的依赖DNAcopy
install.packages("BiocManager")
BiocManager::install("DNAcopy")
```

## 安装bedtools

```shell
conda activate your_env
conda search bedtools
conda install -y bedtools
```

## LiftoverVcf

```shell
# 下载picard
wget https://github.com/broadinstitute/picard/releases/download/2.23.0/picard.jar

# http://broadinstitute.github.io/picard/command-line-overview.html#LiftoverVcf
picard=/home/mizzle/software/picard.jar
chain=/home/mizzle/database/liftover/b37tohg19.chain
ref=/home/mizzle/database/ref/hg19/hg19.fasta

java -jar $picard LiftoverVcf \
     I=af-only-gnomad.raw.sites.vcf \
     O=af-only-gnomad.hg19.raw.sites.vcf \
     CHAIN=$chain \
     REJECT=rejected_variants.vcf \
     R=$ref
```

### chainfile

[gatk/public/chainFiles/b37tohg19.chain at master · broadgsa/gatk (github.com)](https://github.com/broadgsa/gatk/blob/master/public/chainFiles/b37tohg19.chain) 

## 小Tips

### 批量复制

```shell
find . -name "*jpeg" | parallel -I% --max-args 1 convert % %.png

ls *.gz > a && cat a|cut -d "_" -f 1 |uniq > ../script/config && rm a  # 构造config文件，内容为样本名\n
```

## 安装GUN parallel

```bash
# ubuntu
sudo apt-get update
sudo apt-get install parallel

# centos
sudo yum install parallel

# 源码安装
wget https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2 --no-check-certificate
tar xjf parallel-latest.tar.bz2
cd parallel-*
./configure --prefix=/path/to/bin
su
make -j 4
make install
export PATH=/path/to/bin:$PATH
```





# 正式开始

## 数据预处理

```bash
# 提取所有文件夹文件
for folder in */;do (mv "$folder"/* ./ ;rmdir "$folder") ;done

# 生成config文件
ls *.gz > a && cat a|cut -d "_" -f 1,2 |uniq > ../script/config && rm a
```

### 质控

```shell
# qc并行命令
#! /bin/bash
num=$1

echo "$num个任务并行执行..."
config=./config
fastparal(){
echo $1
fastp=~/software/fastp
cleandir=../clean
rawdir=../raw

$fastp -i $rawdir/$1_R1_001.fastq.gz -I $rawdir/$1_R2_001.fastq.gz -o $cleandir/$1_clean_R1_001.fastq.gz -O $cleandir/$1_clean_R2_001.fastq.gz -j $cleandir/$1.json -h $cleandir/$1.html > $cleandir/$1.log.fastp 2>&1
# $fastp -h > a 2>&1
}
export -f fastparal
cat $config | parallel -j$num fastparal
```

#### 执行

```bash
# 自己集群
nohup bash qc_parallel.sh 4 &
# 大数据中心LSF作业系统
例：CPU作业脚本
#BSUB -J case
#BSUB -q normal_test
#BSUB -n 24
#BSUB -o %J.out
#BSUB -e %J.err
sleep 100s

例：GPU作业脚本
#BSUB -J case
#BSUB -q normal_test
#BSUB -n 24
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -gpu "num=1:mode=exclusive_process:aff=yes"
module load anaconda3
source activate XXX
python3 XXX


# qc质控
#BSUB -J qc_wes_xiansheng
#BSUB -q normal
#BSUB -n 28
#BSUB -o %J.out
#BSUB -e %J.err
bash qc.sh 4
```



### 构建索引

```shell
# 解压
gunzip Homo_sapiens_assembly38.fasta.gz
# -a bwtsw 对于短的参考序列式不工作的,必须要大于等于10MB, 但能用于较大的基因组数据,比如人的全基因组
nohup bwa index -a bwtsw -p hg19 hg19.fasta & # -p表示重新定义建立索引的名字

samtools faidx Homo_sapiens_assembly38.fasta

gatk CreateSequenceDictionary -R GRCh37.fasta -O GRCh37.dict
```

### 批量比对

```shell
#! /bin/bash
source activate wes
config=./config
num=$1
echo "$num个任务并行执行..."

bwa_parallel() {
    id=$1
    INDEX=~/database/ref/hg19/hg19
    raw_bam=../align/1.raw_bam
    cleandir=../clean
    fq1="$cleandir/${id}_clean_R1_001.fastq.gz"
    fq2="$cleandir/${id}_clean_R2_001.fastq.gz"

    echo "${id} start~" $(date)
    bwa mem -t 10 -M -R "@RG\tID:$id\tSM:$id\tLB:WES\tPL:Illumina" $INDEX $fq1 $fq2 | samtools sort -@ 10 -o $raw_bam/${id}.bam -
    echo "${id} completed~" $(date)

}
export -f bwa_parallel
cat $config | parallel -j$num -k --load 80% bwa_parallel
```

### qualimap

```shell
# qualimap需要bed文件存在6行，所以我单独做一个加一列0的文件
# bamqc模块用于单个NGS样本bam文件的统计。
#! /bin/bash
config=./config
map_plot() {
qualimap=~/software/qualimap_v2.2.1/qualimap
bed=~/database/ref/hg38/bed/hg38_qualimap.bed
aligndir=../align/1.raw_bam
qualimap_dir=../align/bak1_qualimap
$qualimap bamqc --java-mem-size=10G -gff $bed -bam ${aligndir}/${1}.bam -outdir $qualimap_dir/${1} 1>${qualimap_dir}/${1}_qualimap.log 2>&1
}
export -f map_plot
cat $config | parallel -j$num -k --load 80% map_plot


# mutiqc合并结果

# 安装mutiqc  注意 conda 安装不上  使用pip安装
# conda search multiqc
# conda install -c bioconda -c conda-forge multiqc
pip install multiqc

multiqc /home/fsd/liver_wes/align/qualimap
```



## GATK最佳预处理流程

### Data Pre-processing

```shell
#! /bin/bash
num=$1
echo "$num个任务并行执行..."
source activate wes_program
config=./config
gatkpreparal(){

ref=~/database/ref/hg38/Homo_sapiens_assembly38.fasta
snp=~/database/gatk_resource/hg38/dbsnp_138.hg38.vcf.gz
indel=~/database/gatk_resource/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
knownIndels=~/database/gatk_resource/hg38/Homo_sapiens_assembly38.known_indels.vcf.gz
bed=~/database/ref/hg38/bed/hg38.bed

aligndir=../align/1.raw_bam
markdupdir=../align/2.MarkDuplicates
bqsrdir=../align/3.BQSR
hcdir=../align/4.HC

startTime=`date +"%Y-%m-%d %H:%M:%S"`
if [ ! -f ${aligndir}/${1}_marked.bam ]
then
	echo -e "\nstart MarkDuplicates for ${1}" `date`
	gatk --java-options "-Xmx20G -Djava.io.tmpdir=${markdupdir}" MarkDuplicates \
		-I ${aligndir}/${1}.bam \
		--REMOVE_DUPLICATES true \
		-O ${markdupdir}/${1}_marked.bam \
		-M ${markdupdir}/${1}.metrics \
		1>${markdupdir}/${1}_log.mark 2>&1 
	echo "end MarkDuplicates for ${1}" `date`
	samtools index ${markdupdir}/${1}_marked.bam # 下一步需要索引文件
fi
	
if [ ! -f ${bqsrdir}/${1}_recal.table ]
then
	echo -e "\nstart BaseRecalibrator for ${1}" `date`
    	 gatk --java-options "-Xmx20G -Djava.io.tmpdir=${bqsrdir}"  BaseRecalibrator \
      	-R $ref \
      	-I ${markdupdir}/${1}_marked.bam \
      	--known-sites $snp \
      	--known-sites $indel \
      	--known-sites $knownIndels \
      	-L $bed \
      	-O ${bqsrdir}/${1}_recal.table \
      	1>${bqsrdir}/${1}_log.recal 2>&1
    	echo "end BaseRecalibrator for ${1}" `date`
fi
	
if [ ! -f ${bqsrdir}/${1}_bqsr.bam ]
then
	echo -e "\nstart BQSR for ${1}" `date`
    	gatk --java-options "-Xmx20G -Djava.io.tmpdir=${bqsrdir}"   ApplyBQSR \
     	-R $ref \
     	-I ${markdupdir}/${1}_marked.bam \
     	-bqsr ${bqsrdir}/${1}_recal.table \
     	-L $bed \
     	-O ${bqsrdir}/${1}_bqsr.bam \
     	1>${bqsrdir}/${1}_log.ApplyBQSR  2>&1
    	echo "end BQSR for ${1}" `date`
fi
	
endTime=`date +"%Y-%m-%d %H:%M:%S"`
st=`date -d  "$startTime" +%s`
et=`date -d  "$endTime" +%s`
sumTime=$(($et-$st))
echo -e "\n样本："${1}"  耗时："$sumTime"秒！"
}
export -f gatkpreparal
cat $config | parallel -k -j$num gatkpreparal

```

### Germline mutation

1. Call variants per-sample [HaplotypeCaller(in GVCF mode) ]
2. Consolidate GVCFs [GenomicsDBImport/CombineGVCFs ]
3. Joint-Call Cohort [GenotypeGVCFs ]
4. Filter Variants by Variant (Quality Score) Recalibration [VariantRecalibrator, ApplyVQSR ]

```shell
#! /bin/bash
num=$1
echo "$num个任务并行执行..."
source activate wes_program
config=./config

ref=~/database/ref/hg38/Homo_sapiens_assembly38.fasta
hcdir=../align/4.HC
bed=~/database/ref/hg38/bed/hg38.bed
snp=~/database/gatk_resource/hg38/dbsnp_138.hg38.vcf.gz
echo '-----------------1.HaplotypeCaller----------------------'
gatkHC(){
ref=~/database/ref/hg38/Homo_sapiens_assembly38.fasta
bed=~/database/ref/hg38/bed/hg38.bed
hcdir=../align/4.HC
bqsrdir=../align/3.BQSR
snp=~/database/gatk_resource/hg38/dbsnp_138.hg38.vcf.gz

startTime=`date +"%Y-%m-%d %H:%M:%S"`
if [ ! -f ${hcdir}/${1}.g.vcf.gz ]
then
	echo -e "\nstart HaplotypeCaller for ${1}" `date`
	gatk --java-options "-Xmx20G -Djava.io.tmpdir=${hcdir}" HaplotypeCaller \
		-R $ref \
		-I ${bqsrdir}/${1}_bqsr.bam \
		-D $snp \
		-O ${hcdir}/${1}.g.vcf.gz \
		-L $bed \
		-ERC GVCF \
		1>${hcdir}/${1}_log.HC 2>&1 
	echo "end HaplotypeCaller for ${1}" `date`
fi

endTime=`date +"%Y-%m-%d %H:%M:%S"`
st=`date -d  "$startTime" +%s`
et=`date -d  "$endTime" +%s`
sumTime=$(($et-$st))
echo -e "\n样本："${1}"  耗时："$sumTime"秒！"
}
export -f gatkHC
cat $config | parallel -k -j$num gatkHC

echo '-----------------2.CombineGVCFs----------------------'
# CombineGVCFs适用于小于1000个样本的数据
echo -e "\nstart CombineGVCFs" `date`
realpath ${hcdir}/*.g.vcf.gz > ${hcdir}/gvcf.list
gatk --java-options "-Xmx24g" CombineGVCFs \
	-R ${ref} \
	-V ${hcdir}/gvcf.list \
	-L ${bed} \
	--tmp-dir ${hcdir} \
	-O ${hcdir}/cohort.vcf.gz \
	1>${hcdir}/cgvcf.log 2>&1
echo "end CombineGVCFs" `date`

echo '-----------------3.GenotypeGVCFs----------------------'
# joint genotyping
echo -e "\nstart GenotypeGVCFs" `date`
gatk --java-options "-Xmx24g -Djava.io.tmpdir=${hcdir}" GenotypeGVCFs \
	-R ${ref} \
	-V ${hcdir}/cohort.vcf.gz \
	-D ${snp} \
	-L $bed \
	-O ${hcdir}/WES_variants.vcf.gz
	1>${hcdir}/GenotypeGVCF.log 2>&1
echo "end GenotypeGVCFs" `date`

#-------------------------VariantRecalibrator-------------------------
# GATK-exom  排除DP的注释，会影响到模型的准确性  MQ有时候可以不要
ref=~/database/ref/hg19/hg19.fasta
genotypedir=../test_align/3.GenotypeGVCFs
gatk --java-options "-Djava.io.tmpdir=/share/home/sunLab/liyi/ovarian/WGS/tmp -Xmx8g -Xms8g -XX:ParallelGCThreads=2" VariantRecalibrator \
	-R ${ref} \
	-V ${genotypedir}/raw_variants.vcf.gz \
	-tranche 100.0 -tranche 99.95 -tranche 99.9 \
	-tranche 99.5 -tranche 99.0 -tranche 97.0 -tranche 96.0 \
	-tranche 95.0 -tranche 94.0 -tranche 93.5 -tranche 93.0 \
	-tranche 92.0 -tranche 91.0 -tranche 90.0 \
	--resource:hapmap,known=false,training=true,truth=true,prior=15.0 hapmap_3.3.hg38.sites.vcf.gz \
	--resource:omni,known=false,training=true,truth=false,prior=12.0 1000G_omni2.5.hg38.sites.vcf.gz \
	--resource:1000G,known=false,training=true,truth=false,prior=10.0 1000G_phase1.snps.high_confidence.hg38.vcf.gz \
	--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 Homo_sapiens_assembly38.dbsnp138.vcf.gz \
	-an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
	-mode SNP \
	-O output.recal \
	--tranches-file output.tranches \
	--rscript-file output.plots.R
# tranches用于表达变异检测结果的不同置信度层级。这些层级通常基于变异质量分数（VQSLOD）的阈值，VQSLOD是一个表示变异可能是真实的对数概率比。选择较高的tranches（例如99%）将包含更多的变异，但这可能会增加假阳性率。相反，选择较低的tranches将减少假阳性，但也可能遗漏一些真实变异。


# --max-gaussians 4  # 全基因组这个参数indel是6，snp是默认的8
# 全外显子为了方差不够，indel设置成4，snp设置成6？

gatk --java-options "-Xmx24g -Xms24g" VariantRecalibrator \
	-V cohort_sitesonly.vcf.gz \
	-an FS -an ReadPosRankSum -an MQRankSum -an QD -an SOR -an DP \
	-mode INDEL \
	-resource:mills,known=false,training=true,truth=true,prior=12:Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \ # ？
	-resource:axiomPoly,known=false,training=true,truth=false,prior=10:Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz \ # ？
	-resource:dbsnp,known=true,training=false,truth=false,prior=2:Homo_sapiens_assembly38.dbsnp138.vcf \
	-O cohort_indels.recal \


cd data/; \
gatk --java-options "-Djava.io.tmpdir=/lscratch/$SLURM_JOBID -Xms4G -Xmx4G -XX:ParallelGCThreads=2" VariantRecalibrator \
  -tranche 100.0 -tranche 99.95 -tranche 99.9 \
  -tranche 99.5 -tranche 99.0 -tranche 97.0 -tranche 96.0 \
  -tranche 95.0 -tranche 94.0 -tranche 93.5 -tranche 93.0 \
  -tranche 92.0 -tranche 91.0 -tranche 90.0 \
  -R /fdb/igenomes/Homo_sapiens/UCSC/hg38/Sequence/WholeGenomeFasta/genome.fa \
  -V merged.vcf.gz \
  --resource:mills,known=false,training=true,truth=true,prior=12.0 \
  /fdb/GATK_resource_bundle/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
  --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 \
  /fdb/GATK_resource_bundle/hg38/dbsnp_146.hg38.vcf.gz \
  -an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an DP \
  -mode INDEL -O merged_indel1.recal --tranches-file output_indel1.tranches \
  --rscript-file output_indel1.plots.R

#-------------------------ApplyVQSR-------------------------
gatk ApplyVQSR -R /path/hg38.fa -V *.HC.vcf \
--ts-filter-level 99.0 --tranches-file *.snp.tranches \
--recal-file *.snp.recal \
-mode SNP
-O *.snps.VQSR.vcf.gz


gatk ApplyVQSR \
    -R ${REF_FA} \
    -V ./data/sample.g.vcf.gz \
    -O ./data/sample.recalibrated.g.vcf.gz \
    -OVI \
    --truth-sensitivity-filter-level 99.0 \
    --tranches-file ./data/sample.tranches \
    --recal-file ./data/sample.recal \
    -mode SNP


# 在GATK的VQSR（变异质量分数校正）中，tranches确实代表了特异性和灵敏度之间的权衡。通常，如果提高特异性（减少假阳性），可能会牺牲一些灵敏度（可能会错过一些真阳性）。Ti/Tv（转换/颠换比率）是用于评估变异检测方法性能的一个指标，一个高的Ti/Tv比率通常意味着高质量的变异检测。

#Ti/Tv的值是物种在与自然相互作用和演化过程中在基因组上留下来的一个统计标记，在物种中这个值具有一定的稳定性。因此，一般来说，在完成了以上的质控之后，还会看一下这些变异位点Ti/Tv的值是多少，以此来进一步确定结果的可靠程度。

#Ti/Tv的比值应该是多少才是正常的呢？如果没有选择压力的存在，Ti/Tv将等于0.5，因为从概率上讲Tv将是Ti的两倍。但现实当然不是这样的，比如对于人来说，全基因组正常的Ti/Tv在2.1左右，而外显子区域是3.0左右，新发的变异（Novel variants）则在1.5左右。


# 提取PASS
cat WES_filter_vqsr.vcf|grep "#CHROM" > header
cat WES_filter_vqsr.vcf|grep "PASS"|grep -v "#"> output
cat header output > wes.vcf
```

#### hg19

```shell
#gatkbx.sh
#! /bin/bash
ref=/home/fsd/liver_wes/hg19/hg19.fasta
snp=/home/fsd/liver_wes/hg19/database/dbsnp_138.hg19.vcf
indel=/home/fsd/liver_wes/hg19/database/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
bed=/home/fsd/liver_wes/hg19/bed/hg19_exon.bed

config=$1
cat $config  | while read id
do
	echo "start $config"
	startTime=`date +"%Y-%m-%d %H:%M:%S"`
	if [ ! -f ${id}_marked.bam ]
	then
		echo -e "\nstart MarkDuplicates for ${id}" `date`
		gatk --java-options "-Xmx20G -Djava.io.tmpdir=./" MarkDuplicates \
			-I ${id}.bam \
			--REMOVE_DUPLICATES true \
			-O ${id}_marked.bam \
			-M ${id}.metrics \
			1>${id}_log.mark 2>&1 
		echo "end MarkDuplicates for ${id}" `date`
		samtools index ${id}_marked.bam # 下一步需要索引文件
	fi
	
	if [ ! -f ${id}_recal.table ]
	then
		echo -e "\nstart BaseRecalibrator for ${id}" `date`
    	  gatk --java-options "-Xmx20G -Djava.io.tmpdir=./"  BaseRecalibrator \
      		-R $ref \
      		-I ${id}_marked.bam \
      		--known-sites $snp \
      		--known-sites $indel \
      		-L $bed \
      		-O ${id}_recal.table \
      		1>${id}_log.recal 2>&1
    	echo "end BaseRecalibrator for ${id}" `date`
	fi
	
	if [ ! -f ${id}_bqsr.bam ]
	then
		echo -e "\nstart BQSR for ${id}" `date`
    	 gatk --java-options "-Xmx20G -Djava.io.tmpdir=./"   ApplyBQSR \
     		-R $ref \
     		-I ${id}_marked.bam \
     		-bqsr ${id}_recal.table \
     		-L $bed \
     		-O ${id}_bqsr.bam \
     		1>${id}_log.ApplyBQSR  2>&1
    	echo "end BQSR for ${id}" `date`
	fi
	
	endTime=`date +"%Y-%m-%d %H:%M:%S"`
	st=`date -d  "$startTime" +%s`
	et=`date -d  "$endTime" +%s`
	sumTime=$(($et-$st))
	echo -e "\n样本："${id}"  耗时："$sumTime"秒！"  
done

split -l 7 -d /home/fsd/liver_wes/align/config config_

# gatkmain.sh  
# 放到cpu跑，计算量小，这一批
#! /bin/bash
for config in config_00 config_01 config_02 config_03 config_04
do
	nohup bash gatkbx.sh $config &
done

# 放到gpu跑，计算量大，这一批
for config in config_05 config_06 config_07 config_08 config_09
do
	nohup bash gatkbx.sh $config &
done
```

### mutect2找突变

```shell
# 单样本测试

T=FOR25031705F2D1L1_S48_bqsr.bam
N=EDT14082131B1D1L1_S85_bqsr.bam
sample=FOR25031705F2D1L1_S48
gatk --java-options "-Xmx30G -Djava.io.tmpdir=./" Mutect2 -R ${ref} \
	-I ${T} -tumor  $(basename "$T" _bqsr.bam) \
	-I ${N} -normal $(basename "$N" _bqsr.bam) \
	-L ${bed}  \
	-O ./mutect/${sample}_mutect2.vcf

gatk --java-options "-Xmx20G -Djava.io.tmpdir=./" Mutect2 -R ${ref} \
     -I ${T} -tumor  $(basename "$T" _bqsr.bam) \
     -I ${N} -normal $(basename "$N" _bqsr.bam) \
     -L ${bed}  \
     -O ./mutect/${sample}_mutect2.vcf


## mutect.sh
#! /bin/bash
ref=/home/fsd/liver_wes/hg38/Homo_sapiens_assembly38.fasta
bed=/home/fsd/liver_wes/hg38/bed/exon.bed

cat config2 | while read id
do
	startTime=`date +"%Y-%m-%d %H:%M:%S"`
	arr=(${id})
	sample=${arr[1]}
	T=${arr[1]}_bqsr.bam
	N=${arr[0]}_bqsr.bam
	echo "start Mutect2 for ${id}" `date`
	gatk  --java-options "-Xmx20G -Djava.io.tmpdir=./"  Mutect2 -R ${ref} \
	-I ${T} -tumor  $(basename "$T" _bqsr.bam) \
	-I ${N} -normal $(basename "$N" _bqsr.bam) \
	-L ${bed}  \
	-O ./mutect/${sample}_mutect2.vcf

	gatk  FilterMutectCalls \
  -R ${ref} \
	-V ./mutect/${sample}_mutect2.vcf \
	-O ./mutect/${sample}_somatic.vcf
	echo "end Mutect2 for ${id}" `date`

	cat ./mutect/${sample}_somatic.vcf | perl -alne '{if(/^#/){print}else{next unless $F[6] eq "PASS";next if $F[0] =~/_/;print } }' > ./mutect/${sample}_filter.vcf
done

# 为了防止跑程序被杀死，我分成两份跑 -l 表示最多十行 -d 表示文件后缀是数字而不是字母
# 其实消耗很小，感觉一批跑6个样本没问题
split -l 3 -d /home/fsd/liver_wes/align/config2 config2_

# gatkmutectbx.sh
#! /bin/bash
ref=/home/fsd/liver_wes/hg38/Homo_sapiens_assembly38.fasta
bed=/home/fsd/liver_wes/hg38/bed/exon.bed

config2=$1
cat $config2 | while read id
do
	arr=(${id})
	sample=${arr[1]}
	T=${arr[1]}_bqsr.bam
	N=${arr[0]}_bqsr.bam
	startTime=`date +"%Y-%m-%d %H:%M:%S"`
	echo "start Mutect2 for ${sample}" `date`
	gatk --java-options "-Xmx20G -Djava.io.tmpdir=./" Mutect2 -R ${ref} \
	-I ${T} -tumor  $(basename "$T" _bqsr.bam) \
	-I ${N} -normal $(basename "$N" _bqsr.bam) \
	-L ${bed}  \
	-O ./mutect/${sample}_mutect2.vcf
	
	gatk  FilterMutectCalls \
	-R ${ref} \
	-V ./mutect/${sample}_mutect2.vcf \
	-O ./mutect/${sample}_somatic.vcf
	echo "end Mutect2 for ${id}" `date`

	cat ./mutect/${sample}_somatic.vcf | perl -alne '{if(/^#/){print}else{next unless $F[6] eq "PASS";next if $F[0] =~/_/;print } }' > ./mutect/${sample}_filter.vcf
	
	endTime=`date +"%Y-%m-%d %H:%M:%S"`
	st=`date -d  "$startTime" +%s`
	et=`date -d  "$endTime" +%s`
	sumTime=$(($et-$st))
	echo -e "\n样本："${sample}"  耗时："$sumTime"秒！"  
done

# gatkmutectmain.sh  
# 放到cpu跑，计算量小，这一批
#! /bin/bash
for config in config2_00 config2_01 config2_02 config2_03
do
	nohup bash gatkmutectbx.sh $config &
done

# 放到gpu跑，计算量大，这一批
#! /bin/bash
for config in config2_04 config2_05 config2_06 config2_07
do
	nohup bash gatkmutectbx.sh $config &
done
```

### 过滤

```shell
# 过滤掉变异等位基因频率（VAF)<0.05且支持数小于3个reads的结果

# 单样本测试
less TIS76106536F1D1L1_S63_filter.vcf|grep -v "#"|wc -l

cat TIS76106536F1D1L1_S63_filter.vcf|grep -v "#"|less -SN


#  读取第一行，按制表符分割，输出第11个字段
head -1 input.vcf |awk -F "\t" '{print $11}'

# 读取第一行，按制表符分割，取第11个字段，按照冒号分割，取出第三个字段
head -1 input.vcf |awk -F "\t" '{split($11,a,":");print a[3]}'

# 读取第一行，按制表符分割，取第11个字段，按照冒号分割，取出第二个字段，再将第二个字段以逗号划分，再取第二个字段。
head -1 input.vcf |awk -F "\t" '{split($11,a,":");split(a[2],b,",");print b[2]}'


ls *_filter.vcf|while read id
do
sample=${id%.*}
echo $sample
cat $sample.vcf|grep "#" > header
cat $sample.vcf|grep -v "#" > input.vcf
awk -F "\t" '{split($11,a,":");split(a[2],b,",");if(b[2]>=3&&a[3]>=0.05) print}' input.vcf > output.vcf
cat header output.vcf > final_vcf/${sample}_vaf.vcf
done
```





#### hg19

```shell
# gatkmutectbx.sh
#! /bin/bash
ref=/home/fsd/liver_wes/hg19/hg19.fasta
bed=/home/fsd/liver_wes/hg19/bed/hg19_exon.bed

config2=$1
cat $config2 | while read id
do
	arr=(${id})
	sample=${arr[1]}
	T=${arr[1]}_bqsr.bam
	N=${arr[0]}_bqsr.bam
	startTime=`date +"%Y-%m-%d %H:%M:%S"`
	echo "start Mutect2 for ${sample}" `date`
	gatk --java-options "-Xmx20G -Djava.io.tmpdir=./" Mutect2 -R ${ref} \
	-I ${T} -tumor  $(basename "$T" _bqsr.bam) \
	-I ${N} -normal $(basename "$N" _bqsr.bam) \
	-L ${bed}  \
	-O ./mutect/${sample}_mutect2.vcf
	
	gatk  FilterMutectCalls \
	-R ${ref} \
	-V ./mutect/${sample}_mutect2.vcf \
	-O ./mutect/${sample}_somatic.vcf
	echo "end Mutect2 for ${id}" `date`

	cat ./mutect/${sample}_somatic.vcf | perl -alne '{if(/^#/){print}else{next unless $F[6] eq "PASS";next if $F[0] =~/_/;print } }' > ./mutect/${sample}_filter.vcf
	
	endTime=`date +"%Y-%m-%d %H:%M:%S"`
	st=`date -d  "$startTime" +%s`
	et=`date -d  "$endTime" +%s`
	sumTime=$(($et-$st))
	echo -e "\n样本："${sample}"  耗时："$sumTime"秒！"  
done

split -l 6 -d config2 config2_
# gatkmutectmain.sh  
# 放到cpu跑，计算量小，这一批
#! /bin/bash
for config in config2_00 config2_01 config2_02 config2_03 config2_04
do
	nohup bash gatkmutectbx.sh $config &
done

# 放到gpu跑，计算量大，这一批
#! /bin/bash
for config in config2_05 config2_06 config2_07 config2_08 config2_09
do
	nohup bash gatkmutectbx.sh $config &
done

for config in config2_19 config2_11 config2_12 config2_13
do
	nohup bash gatkmutectbx.sh $config &
done
```

### ANNOVAR注释

```shell
annovar_script_file=~/software/annovar
humandb=~/software/annovar/humandb/hg38_humandb
vqsr_file=~/wes1106/align/5.VQSR/WES_filter_vqsr.vcf
outfile_dir=~/wes1106/align/6.VCF_File/annovar
${annovar_script_file}/table_annovar.pl $vqsr_file $humandb \
-buildver hg38 --thread 12 \
-out ${outfile_dir}/wes \
-remove \
-protocol refGene,knownGene,clinvar_20220320,exac03,avsnp150,dbnsfp42a \
-operation g,g,f,f,f,f \
-nastring . \
-vcfinput
less ${outfile_dir}/wes.hg38_multianno.vcf | grep "#CHROM" > ${outfile_dir}/vcfhead
less ${outfile_dir}/wes.hg38_multianno.vcf | grep "PASS" > ${outfile_dir}/vcfcontent
head -1 ${outfile_dir}/wes.hg38_multianno.txt > ${outfile_dir}/txthead
less ${outfile_dir}/wes.hg38_multianno.txt | grep "PASS" > ${outfile_dir}/txtcontent
cat ${outfile_dir}/vcfhead ${outfile_dir}/vcfcontent > ${outfile_dir}/wes.vcf
cat ${outfile_dir}/txthead ${outfile_dir}/txtcontent > ${outfile_dir}/wes.txt


# 注释脚本  单样本测试
humandb=/home/fsd/software/annovar/humandb/hg38_humandb
id=FOR66031704F2D1L1_S47_filter.vcf
table_annovar.pl $id $humandb \
-buildver hg38 \
-out case1 \
-remove \
-protocol refGene,knownGene,clinvar_20220320 \
-operation g,g,f \
-nastring . \
-vcfinput

# 简单观测 注意以下三个文件
# case1.avinput
# case1.hg38_multianno.txt
# case1.hg38_multianno.vcf
# case1.hg38_multianno.txt记录了突变注释信息，如突变位点所在的基因、是nonsynonymous或者synonymous等
#统计有多少外显子
cat case1.hg38_multianno.txt|grep exonic|less -S|wc
#观察是否有除了外显子之外的结果
cat case1.hg38_multianno.txt|grep -v exonic

# 批处理 注释
# 制作config
ls *_filter.vcf > tmp
cat tmp | cut -d "_" -f 1,2 >config
# annovar.sh 
#! /bin/bash
# /home/fsd/software/annovar/humandb/hg38_humandb
humandb=/home/fsd/software/annovar/humandb
cat config|while read id
do
table_annovar.pl ${id}_filter.vcf $humandb \
-buildver hg19 \
-out ${id} \
-remove \
-protocol refGene,knownGene,clinvar_20220320 \
-operation g,g,f \
-nastring . \
-vcfinput
done



# 看一下注释后txt的前两行
head -2 TIS63016327F1D1L1_S125.hg38_multianno.txt

# 增加两列 分别是肿瘤/类器官样本 和 正常样本

# 单样本测试
tumor=TIS63016327F1D1L1_S125
normal=EDT24082129B1D1L1_S84
# ^正则表达式，表示以...为开头
grep -v '^Chr' TIS63016327F1D1L1_S125.hg38_multianno.txt | cut -f 1-20 | awk -v T=${tumor} -v N=${normal} '{print $0"\t"T"\t"N}'  >TIS63016327F1D1L1_S125.annovar.vcf 

# 首先构造config2 直接从excel复制对应关系即可
cat config2 | while read id
do
arr=($id)
normal=${arr[0]}
tumor=${arr[1]}
grep -v '^Chr' ${tumor}.hg38_multianno.txt | cut -f 1-20 | awk -v T=${tumor} -v N=${normal} '{print $0"\t"T"\t"N}'  > ${tumor}.annovar.vcf 
done
# 获取列名
head -1 FOR90051323F1D1L1_S148.hg38_multianno.txt | sed 's/Otherinfo/Tumor_Sample_Barcode\tMatched_Norm_Sample_Barcode/'|cut -f 1-22 > header
# 合并列名
cat header *annovar.vcf >annovar_merge.vcf
```

### VEP注释

```shell
# 参考：https://qinqianshan.com/bioinformatics/callvariant/vep/
# https://pzweuj.github.io/2022/05/30/VEP.html
# 官方文档https://grch37.ensembl.org/info/docs/tools/vep/script/index.html

# docker安装vep
# 授予docker用户组权限
sudo chown root:docker /var/run/docker.sock # 修改docker.sock权限为root:docker
sudo groupadd docker          # 添加docker用户组 
sudo gpasswd -a $USER docker  # 将当前用户添加至docker用户组
newgrp docker                 # 更新docker用户组

docker images # 查看拉取的镜像
docker run -t -i -v ~/software/vep_tool/data:/opt/vep/.vep ensemblorg/ensembl-vep vep_install -a cf -s homo_sapiens -y GRCh38

git clone  https://github.com/Ensembl/ensembl-vep.git 
perl INSTALL.pl -n -s homo_sapiens --ASSEMBLY GRCh38 -d ./API -c ./cache


# 使用官网：http://asia.ensembl.org/info/docs/tools/vep/script/vep_options.html
# 插件官网：https://asia.ensembl.org/info/docs/tools/vep/script/vep_plugins.html

# vep安装 直接使用conda来安装vep软件，省去了多余复杂的配置问题，但是由于vep涉及到的软件版本和依赖较多，因此建议新建一个虚拟环境来安装
conda create -n vep # 需要创建一个虚拟环境安装vep
conda activate vep  # 激活环境
conda install -c bioconda ensembl-vep

#删除环境
conda deactivate
conda remove -n vep --all

# 下载数据库
nohup wget ftp://ftp.ensembl.org/pub/release-105/variation/indexed_vep_cache/homo_sapiens_vep_105_GRCh38.tar.gz &
nohup curl -O ftp://ftp.ensembl.org/pub/release-105/variation/indexed_vep_cache/homo_sapiens_refseq_vep_105_GRCh38.tar.gz &

# 用 --fork 参数多线程运行 VEP
./vep -i my_input.vcf --fork 4 --offline

# 下载vep的安装包
git clone https://github.com/Ensembl/ensembl-vep

cache=/home/mizzle/liver_wes/hg38/database/vep_database
result=/home/mizzle/liver_wes/align/mutect/vep_result


# 单样本测试
id=TIS76106536F1D1L1_S63_filter.vcf
cache=/home/mizzle/liver_wes/hg38/database/vep_database
vep --cache --offline --format vcf --vcf --force_overwrite \
--dir $cache \
--input_file $id \
--output_file vep_result/${id}_vep.vcf

id=TIS76106536F1D1L1_S63_filter.vcf
cache=/home/mizzle/liver_wes/hg38/database/vep_database
time vep --cache --offline --format vcf --vcf --force_overwrite \
--dir_cache $cache \
--fork 4 \
--input_file $id \
--output_file vep_result/${id}_vep2.vcf

--refseq \
--fasta /home/mizzle/liver_wes/hg38/Homo_sapiens_assembly38.fasta \

# 批量注释 vep.sh
#! /bin/bash
cache=/home/mizzle/liver_wes/hg38/database/vep_database
cat vep_config | while read id
do
echo "start vep_annotation for ${id} " `date`
vep --cache --offline --format vcf --vcf --force_overwrite \
--dir $cache \
--input_file ${id}_filter.vcf \
--output_file vep_result/${id}_vep.vcf
echo "end vep_annotation for ${id} " `date`
done

nohup bash vep.sh &




# 重要使用vep的插件，使用dbNSFP，这是一个全家桶库，整合了非常多人群频率及有害性预测等数据库。
wget ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFP4.5a.zip
unzip dbNSFP4.5a.zip
zcat dbNSFP4.5a_variant.chr1.gz | head -n1 > h
# 第8列是hg19 第9列是hg19_pos(1-based)
#chr	pos(1-based)	ref	alt	aaref	aaalt	rs_dbSNP	hg19_chr	hg19_pos(1-based)
# 第一列不能为.，对第一列排序，再对第二列进行数值排序得到的是hg38
zgrep -h -v "^#chr" dbNSFP4.5a_variant.chr* | awk '$1 != "." ' | sort -T ./tmp -k1,1 -k2,2n - | cat h - | bgzip -c > dbNSFP4.5a_grch38.gz
tabix -s 1 -b 2 -e 2 dbNSFP4.5a_grch38.gz

# dbscSNV是一个剪接位点有害性预测库。
wget ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbscSNV1.1.zip
unzip dbscSNV1.1.zip
head -n1 dbscSNV1.1.chr1 > h
# 第5列是hg38的染色体 第6列是位置
cat dbscSNV1.1.chr* | grep -v ^chr | awk '$5 != "." '| sort -T ./tmp -k5,5 -k6,6n - |cat h - | bgzip -c > dbscSNV1.1_GRCh38.txt.gz
# 建立索引就知道该怎么查找了
tabix -s 5 -b 6 -e 6 -c c dbscSNV1.1_GRCh38.txt.gz


VEP参数解释：
--vcf --tab：两个不能连用，--tab是以制表符分割的格式写入输出，--vcf是以vcf写入输出，所有注释的信息都在INFO列，得自己提取，以“|”进行分隔。
--assembly：帮忙选择cache下的assembly版本号，但是如果下面只有一个版本，那么就不用使用。
--check_existing：检查是否存在与输入位于同一位置的已知变体。增加三列：Existing_variation, CLIN_SIG, SOMATIC, PHENO。
--everything：Shortcut flag to switch on all of the following:--sift b,--polyphen b...b表示不仅显示是不是有害的，还显示分数，both的意思（预测项和分数）






```

#### vep转换成maf

```shell
# VEP的注释结果拿到了vcf文件，也可以转成maf文件，不过要用到一个软件，叫vcf2maf，安装和使用的方法如下

# 安装
export VCF2MAF_URL=`curl -sL https://api.github.com/repos/mskcc/vcf2maf/releases | grep -m1 tarball_url | cut -d\" -f4`
curl -L -o mskcc-vcf2maf.tar.gz $VCF2MAF_URL
tar -zxf mskcc-vcf2maf.tar.gz
cd mskcc-vcf2maf-*
# 注意还需要安装samtools
conda install -y -c bioconda samtools


# 使用
#! /bin/bash
cache=/home/mizzle/liver_wes/hg38/database/vep_database
cat config | while read id
do
    arr=($id)
    tumor=${arr[1]}
    normal=${arr[0]}
    sample=${tumor}_vep.vcf
    perl /home/mizzle/software/vep/vcf2maf/vcf2maf.pl \
    --input-vcf ${sample}   \
    --output-maf ${tumor}_vep.maf  \
    --vep-path ~/miniconda3/envs/vep/bin/ \
    --vep-data $cache  \
    --ref-fasta /home/mizzle/liver_wes/hg38/Homo_sapiens_assembly38.fasta \
    --tumor-id  ${tumor}  \
    --normal-id ${normal}  \
    --ncbi-build GRCh38
done


cat *maf | grep -v '^#'| grep -v '^Hugo_Symbol' > tmp 
grep 'Hugo_Symbol' FOR10052765F1D1L1_S241_vep.maf > header
cat header tmp > VEP_merge.maf


# 列注释
https://github.com/mskcc/vcf2maf/blob/d13e404033ebf89f208c9010d9dc8f008356c0f7/docs/vep_maf_readme.txt
```

# CNV calling 

## CNVkit检测拷贝数变异

```shell
# cnvkit.py为主脚本；batch可以调用脚本命令；Tumor.bam 和Normal.bam为对应样本的bam文件，建议用bwa-mem模式；--targets分析区域；--annotaterefFlat格式的基因注释信息，可以从UCSC上下载；--fasta 参考基因组；--output-reference 输出的reference.cnn可以作为下一批tumor数据分析的输入文件，reference.cnn和输入的normal.bam有关；--output-dir输出目录名；--diagram –scatter绘图参数。

# 需不需要将bed划分为更小bin，但是好像说使用--annotate就会自动划分。
cnvkit.py target my_baits.bed --annotate refFlat.txt --split -o my_targets.bed

# 整理成两个文件夹
awk '{print $0"_bqsr.bai"}' 1 > t
cat t|

while read id;do mv $id ./tumor_bam & done

# 生成这个必须的文件access-5k-mappable.hg38.bed  -s 5000是默认值
cnvkit.py access $fasta -o access-5k-mappable.hg38.bed

#! /bin/bash
targets=/home/mizzle/liver_wes/hg38/bed/hg38.exon.bed
fasta=/home/mizzle/liver_wes/hg38/Homo_sapiens_assembly38.fasta
annotate=/home/mizzle/liver_wes/hg38/refFlat.txt
access=/home/mizzle/liver_wes/hg38/access-5k-mappable.hg38.bed
cnvkit.py batch tumor_bam/*.bam --normal normal_bam/*.bam \
    --targets $targets --annotate $annotate \
    --fasta $fasta --access $access \
    --output-reference wes_reference.cnn --output-dir result \
    --drop-low-coverage \
    --diagram --scatter -p 10 1>kit.log 2>&1
    
ps aux | grep -ai "cnvkit.py" | grep -v grep | awk '{print $2}' | xargs kill -9


# 绘制diagram图
cnvkit.py diagram 700_bwa.sam.cnr

# 注意这一步必须要有R的DNAcopy包
# 百度搜索conda安装R包和R环境
conda search r -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
conda install r-base=4.0 -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
R
install.packages("BiocManager")
library(BiocManager)
BiocManager::install("DNAcopy")
q()

#！ bin/bash/
cat sample|while read id
do 
cnvkit.py segment $id.cnr --output $id.cns
cnvkit.py call $id.cns -o $id.call.cns
done

cat sample_name.txt|while read id
do
arr=($id)
old=${arr[0]}
new=${arr[1]}
cp ${old}_bqsr.call.cns trans_name_result/${new}.cns
done

cnvkit.py heatmap *.cns -o heatmap.svg

# https://blog.csdn.net/m0_52425873/article/details/124899793
# linux将上一条命令的结果作为下一条命令的参数
cnvkit.py heatmap `ls *.cns|grep -v "bqsr"` -o heatmap.svg

# 合并所有cns文件
ls *.cns|grep -v "bqsr" > 1
less 1|cut -d "." -f 1,2 > 2
cat 2|while read id
do
less $id.cns|grep -v "chromosome"|awk '{print $0"\t""'$id'"}'>$id.new.cns
done

head -1 NO.8_T.cns|awk '{print $0"\t""sample"}'>header
cat header *.new.cns > wes_cnv.cns

cat sample|while read id
do 
nohup cnvkit.py genemetrics $id.cnr -o $id.cns &
done

cat sample|while read id
do 
nohup cnvkit.py call $id.cns -o $id.call.cns &
done

cnvkit.py export seg *.cns -o gistic.segments
```

![img](assets/bb6e31dd18ef4191bfbea4b572d187c6.png) 

# 肿瘤异质性分析

## absolute

```shell
# 整理maf文件 使其符合格式 1d表示删除第一行
cat vep_config | while read id;do sed -e '1d' -e 's/Start_Position/Start_position/' -e 's/chr//' ${id}_vep.maf > ./absolute_maf/${id}_absolute.maf;done

cat sample_name.txt|while read id
do
arr=($id)
old=${arr[0]}
new=${arr[1]}
cp ${old}_absolute.maf trans_name/${new}_absolute.maf
done

# 整理cns文件
ls *cns > 1
sed "s/.cns//" 1 > 2
cat 2 | while read id;do cnvkit.py export seg ${id}.cns -o absolute_seg/${id}.seg;done

ls *seg > 1
# %.*的作用是删除变量最后一个.及其后的内容
# %%.*的作用是删除变量第一个.及其后的内容
# ${a%%.*}


cat 1 | while read id;do sed -e '1d' ${id} > ${id%.*}_change.seg;done
header=Sample	Chromosome	Start	End	Num_Probes	Segment_Mean # 用vim
cat 1| while read id;do cat header ${id%.*}_change.seg > ${id%.*}_final.seg;done


while read id;do sed -e 's/chrom/Chromosome/'-e 's/loc.start/Start/' -e 's/loc.end/End/' -e 's/num.mark/Num_Probes/' -e 's/seg.mean/Segment_Mean' ${id} > ${id%.*}_change.seg;done
```

## pyclone

```shell
conda create --name pyclone python=2
conda activate pyclone

# 出现报错raise RuntimeError('Invalid DISPLAY variable')

# 解决方案
# 当你看到上面的问题，说明你的配置文件（matplotlibrc）有问题
# 通过命令找到你的matplotlibrc文件：
>>> import matplotlib
>>> matplotlib.matplotlib_fname()
'/home/foo/.config/matplotlib/matplotlibrc'

# 编辑你的 matplotlibrc（文件的第 44 行）：
vim /home/foo/.config/matplotlib/matplotlibrc :
# backend      : qt5agg
backend      : Agg

# 测试数据+测试代码
PyClone run_analysis_pipeline --in_files SRR385938.tsv SRR385939.tsv SRR385940.tsv SRR385941.tsv --working_dir pyclone_analysis  --num_iters 1000 

# 转换vep注释后maf文件的名称
cat sample_name.txt|while read id
do
arr=($id)
old=${arr[0]}
new=${arr[1]}
cp ${old}_vep.maf convert_name/${new}.maf
done

ls * | while read id
do
sample=${id%.*}
echo $sample >> config
done

# 生成pyclone所需的tsv文件
cat config | while read id
do 
cat ${id}.maf | sed '1,2d' | awk -F '\t' '{print $5"\t"$6"\t"$7"\t"$5":"$6":"$1"\t"$41"\t"$42"\t"2"\t"0"\t"2"\t"}' > pyclone/${id}.tmp.tsv
done

# 对于过滤后的maf生成pyclone所需的tsv文件
cat config | while read id
do 
cat filter/${id}.maf | sed '1d' | awk -F '\t' '{print $5"\t"$6"\t"$7"\t"$5":"$6":"$1"\t"$41"\t"$42"\t"2"\t"0"\t"2"\t"}' > pyclone/${id}.tmp.tsv
done

# 下面这段不需要，使用bedtools不能加第一行，不然会报错
cat config | while read id
do
cat ${id}.maf | sed '1,2d' | awk -F '\t' 'BEGIN{print "Chromosome\tStart_Position\tEnd_Position\tmutation_id\tref_counts\tvar_counts\tnormal_cn\tminor_cn\tmajor_cn"}{print $5"\t"$6"\t"$7"\t"$5":"$6":"$1"\t"$41"\t"$42"\t"2"\t"0"\t"2"\t"}' > pyclone/${id}.tmp.tsv
done


cat 1|while read id
do
sample=${id%.*}
echo $sample >> config
done

# 处理segment数据
cat config | while read id
do 
cat ${id}_final.seg | sed '1d' | awk 'BEGIN{OFS="\t"}{print $0"\t"int((2^$6)*2+0.5)}'| awk 'BEGIN{OFS="\t"}{if ($7!=0)print $0}' | cut -f 2-7  > pyclone_seg/${id}.bed
done

# bedtools 工具，把两个文件的坐标进行overlap，取出必要的列
cat config | while read id;
do 
bedtools window -a tsv_filter/${id}.tmp.tsv  -b bed/${id}.bed | cut -f 4-8,15 | awk 'BEGIN{OFS="\t";print "mutation_id\tref_counts\tvar_counts\tnormal_cn\tminor_cn\tmajor_cn"}{print $0}' >ini_data/${id}.tsv
done

# pyclone分析
# 单样本
PyClone run_analysis_pipeline --prior total_copy_number --in_files ini_data/NO.48_O*.tsv --working_dir result/NO.48_O_pyclone_analysis --num_iters 1000 1> result/log_dir/NO.48_O.log 2>&1

PyClone run_analysis_pipeline --prior total_copy_number --in_files ini_data/NO.35-1*.tsv --working_dir result/NO.35-1_pyclone_analysis 1> result/log_dir/NO.35-1.log 2>&1

# 取出所有样本名 这样取出的样本名将NO35-1和NO.35-2也合并了。但是事实是这一个人的样本两次测量出来的突变除了TP53,TTN外竟然没有共同突变。所以我需要分开做亚克隆分析。
cat config|awk -F "_" '{print $1}'|awk -F "-" '{print $1}'|uniq > run_config

# 批量运行，类器官和肿瘤样本认为是一个人的两个样本
# bin/bash/
cat run_config | while read id
do
PyClone run_analysis_pipeline --prior total_copy_number --in_files ini_data/${id}*tsv --working_dir result/${i}_pyclone_analysis --num_iters 1000 1> result/log_dir/${i}.log 2>&1
done

#! /bin/bash
cat run_config | xargs -I {} -P 5 bash -c '
id=$1
PyClone run_analysis_pipeline --prior total_copy_number --in_files ini_data/${id}*tsv --working_dir result/${id}_pyclone_analysis 1> result/log_dir/${id}.log 2>&1
' - {}

# NO.42、NO.48、NO.60三个样本报错，比如没有共同的突变等。所以需要排除在外。
```

### CITUP(利用系统发育进行肿瘤的同源性推断)

```shell
# 安装在pyclone的环境下
conda config --add channels http://conda.anaconda.org/dranew
conda config --add channels https://conda.anaconda.org/IBMDecisionOptimization/linux-64

conda install -y citup h5py

# 安装完成后可以调用软件的帮助文档
# 安装后面这些包，不然5.1.0版本的decorator使用帮助文档会报错
conda install decorator=4.4.0
conda install scikit-learn=0.20.3

run_citup_iter.py -h
run_citup_qip.py  -h

# 运行需要两个文件：1.突变位点在不同样本的突变频率，行是突变位点，列是样本。2.突变的 cluster，只有单列，记录每个突变位点所在的 cluster。
for case in case{1..6}
do
cat ./9.pyclone/${case}_pyclone_analysis/tables/loci.tsv | cut -f 3 | sed '1d' | paste - - - - |cut -f 1 >./9.pyclone/${case}_pyclone_analysis/cluster.txt
## 获取 sample_id 信息，后面画图要用到
cat ./9.pyclone/${case}_pyclone_analysis/tables/loci.tsv | cut -f 2 | sed '1d' | head -4 >./9.pyclone/${case}_pyclone_analysis/sample_id
done

# 单个样本测试
cd /home/mizzle/liver_wes/heterogeneity/citup/result/NO.11_pyclone_analysis/tables
cat loci.tsv | cut -f 6 | sed '1d' | paste - - - - > freq.txt # paste - - - -: 每4行拼接成一行，其中-表示从标准输入流中读取数据。
cat loci.tsv | cut -f 3 | sed '1d' | paste - - - - |cut -f 1 > cluster.txt
cat loci.tsv | cut -f 2 | sed '1d' | head -4 > sample_id

# 运行
run_citup_qip.py --submit local freq.txt cluster.txt results.h5

# 批处理
# 生成config文件
cat config |while read id;do echo ${id%.*} >> conf;done

cat config| while read id
do
cat ./pyclone_result/${id}_pyclone_analysis/tables/loci.tsv | cut -f 6 | sed '1d' | paste - - > ./pyclone_result/${id}_pyclone_analysis/freq.txt
cat ./pyclone_result/${id}_pyclone_analysis/tables/loci.tsv | cut -f 3 | sed '1d' | paste - - |cut -f 1 > ./pyclone_result/${id}_pyclone_analysis/cluster.txt
cat ./pyclone_result/${id}_pyclone_analysis/tables/loci.tsv | cut -f 2 | sed '1d' | head -2 > ./pyclone_result/${id}_pyclone_analysis/sample_id
done

cd /home/mizzle/liver_wes/heterogeneity/citup/pyclone_result/NO.11_pyclone_analysis/tmp/log/20230409-223402

#! /bin/bash
cat config | while read id
do
echo "${id} start~" `date`
run_citup_qip.py --submit local --tmpdir ./pyclone_result/${id}_pyclone_analysis/tmp \
./pyclone_result/${id}_pyclone_analysis/freq.txt \
./pyclone_result/${id}_pyclone_analysis/cluster.txt \
./pyclone_result/${id}_pyclone_analysis/${id}_results.h5 
echo "${id} end~" `date`
done

nohup bash citup.sh &

cat config | while read id
do
rm ./pyclone_result/${id}_pyclone_analysis/files_createtimes.shelf.*
rm ./pyclone_result/${id}_pyclone_analysis/jobs.shelf.*
rm -rf ./pyclone_result/${id}_pyclone_analysis/locks
rm -rf ./pyclone_result/${id}_pyclone_analysis/nodes
rm -rf ./pyclone_result/${id}_pyclone_analysis/tmp
rm -rf ./pyclone_result/${id}_pyclone_analysis/log
rm ./pyclone_result/${id}_pyclone_analysis/nohup.out
done
·

# 读取转化result.h5文件
import sys
import h5py
import numpy as np
hf=h5py.File(sys.argv[1],'r')
hf.keys()
opnum=hf["results/optimal/index"][0]
cellfreq=hf["trees/" + str(opnum) + "/clone_freq/block0_values"][:]
tree=hf["trees/" + str(opnum) + "/adjacency_list/block0_values"][:]
np.savetxt(sys.argv[2],cellfreq,fmt='%.6g',delimiter='\t')
np.savetxt(sys.argv[3],tree,fmt='%d',delimiter='\t')


python test.py /home/mizzle/liver_wes/heterogeneity/citup/pyclone_result/NO.11_pyclone_analysis/NO.11_results.h5
# cellfreq.txt行表示样本，列表示克隆clusters，每个值代表克隆频率
# tree.txt表示进化树的克隆分支关系

# 批量运行
cat config | while read id
do
echo "${id} start~" `date`
python pycitup.py ./pyclone_result/${id}_pyclone_analysis/${id}_results.h5 final_result/${id}_cellfreq.txt final_result/${id}_tree.txt
echo "${id} end~" `date`
done

cat config | while read id
do
cp ./pyclone_result/${id}_pyclone_analysis/sample_id final_result/${id}_sampleid.txt
done
```



# 并行运行

```shell
# 需要parallel 这个要使用yum安装
# 安装如下
sudo yum install epel-release
sudo yum install parallel

# 但是gpu和mu节点不共享/usr/bin/文件夹。所以估计还要本地安装，那我就暂时不用这种方法
cat config | parallel --will-cite -j 5 '
    id={};
    arr=($id);
    tumor=${arr[1]};
    normal=${arr[0]};
    echo $tumor;
    sleep 10s '

# 使用xargs 进行并行处理。
# xargs命令会将ls *_filter.vcf的输出作为参数传递给后面的命令。
# -I {}表示用{}替代默认的参数位置，这样后面的命令就可以引用参数了。
# -P 5表示开5个进程并行运行命令。
# bash -c '...'表示要执行的命令。
# 在bash -c '...'的末尾的- {}表示将ls *_filter.vcf的输出作为参数传递给bash -c中的命令。
cat config | xargs -I {} -P 5 bash -c '
    id=${1};
    arr=($id);
    tumor=${arr[1]};
    normal=${arr[0]};
    echo $tumor;
    sleep 3s
' - {}

cat config | xargs -I {} -P 5 bash -c '
    id=$1;
    echo $id;
    sleep 3s
' - {}

/home/mizzle/liver_wes/align/mutect/filter_vcf/final_vcf/vep_result
```

# 胚系突变过滤

## 总体流程

在人群中筛选致病基因时，一般步骤通常包括以下几个方面：

1. **过滤基于质量的变异**：
   - 使用`QUAL`列过滤低质量变异。通常，会选择一个阈值（如`QUAL > 30`或更高）来确保变异的可信度。
   - 使用`FILTER`列（如果存在）来去除未通过质控的变异。

2. **过滤基于频率的变异（common variants）**：
   - 使用`ExAC_ALL`, `ExAC_EAS`, `gnomAD_exome_ALL`, `gnomAD_exome_EAS`等列去除常见变异。例如，你可能想去除所有在一般人群中频率高于0.01（1%）的变异。

3. **过滤基于功能的变异**：
   - 使用`ExonicFunc.refGene`或`ExonicFunc.knownGene`列筛选出特定类型的变异，比如错义变异（nonsynonymous SNVs），无义变异（nonsense），剪切位点变异，或者帧移变异（frameshift insertions/deletions）。
   - 对HLH相关研究，你可能想要专注于这些可能影响蛋白质功能的变异。

4. **预测致病性**：
   - 利用`SIFT4G_pred`, `Polyphen2_HDIV_pred`, `MutationTaster_pred`, `FATHMM_pred`, `PROVEAN_pred`, `MetaSVM_pred`, `MetaLR_pred`, `REVEL_score`, `M-CAP_pred`, `ClinPred_pred`等列来预测变异的致病性。
   - 选择预测结果显示“有害”或“可能有害”的变异。

5. **关注特定基因**：
   - 如果你已经知道一些与HLH相关的候选基因，使用`Gene.refGene`或`Gene.knownGene`列来筛选这些基因的变异。

6. **进化保守性和生物信息学功能预测**：
   - `GERP++_RS`, `phyloP100way_vertebrate`, `phastCons100way_vertebrate`, `SiPhy_29way_logOdds`等列可以提供变异位点的进化保守性信息。高保守性分数可能表明该位点在进化中保持不变，因此变异可能具有生物学意义。

7. **其他预测工具**：
   - `CADD_phred`, `DANN_score`, `fathmm-MKL_coding_pred`, `Eigen-PC-raw_coding`等列也可以用来评估变异的可能影响。

8. **致病变异的临床证据**：
   - `CLNSIG`列提供了变异的临床意义，可以帮助识别已知的致病变异。

在筛选过程中，你可能需要进行多轮筛选，每轮关注不同的特征。例如，第一轮可能专注于功能和频率，而第二轮可能更多地考虑致病性预测和进化保守性。此外，你可能还需要考虑变异的遗传模式（例如显性或隐性）和患者的临床表现。

此外，对于特定的疾病，比如HLH，查阅最新的文献和疾病特定数据库，以了解最新的研究进展和已知相关基因是很重要的。这可以帮助你更新你的筛选标准，以包括最新识别的致病基因或变异。

## ExonicFunc.refGene

`ExonicFunc.refGene`列通常包含了变异在外显子上的功能影响类型。这些类型可能包括但不限于：

1. **synonymous**: 同义突变，即变异不会改变编码的氨基酸。
2. **nonsynonymous**: 错义突变，变异会导致编码的氨基酸发生改变。
3. **stopgain**: 无义突变，变异会导致一个提前的终止密码子的产生，可能导致蛋白质提前截断。
4. **stoploss**: 终止密码子丢失突变，变异会导致正常的终止密码子丢失，可能导致蛋白质延长。
5. **frameshift insertion/deletion**: 帧移突变，由插入或缺失导致的读码框改变。
6. **nonframeshift insertion/deletion**: 非帧移插入或缺失，插入或缺失不改变读码框。
7. **splicing**: 剪接相关突变，可能影响RNA的剪接过程。
8. **unknown**: 未知功能的突变。

在寻找可能致病的变异时，研究者通常会专注于那些可能改变蛋白质结构和功能的变异，如：

- **nonsynonymous (错义突变)**
- **stopgain (无义突变)**
- **stoploss (终止密码子丢失突变)**
- **frameshift insertion/deletion (帧移突变)**

同义突变（synonymous）一般不会改变蛋白质的氨基酸序列，所以它们通常被认为是不致病的，除非它们影响剪接位点或者是在特殊情况下具有功能意义。

非帧移插入/缺失（nonframeshift insertion/deletion）和剪接（splicing）突变可能在某些情况下具有功能意义，因此是否考虑这些突变可能取决于特定的研究背景和致病机理。

为了确定您的研究中应该去除哪些类型的突变，您需要考虑您的研究目的以及哪些类型的突变更有可能与HLH的发病机制相关。通常，您可能会想要去除同义突变和那些已知在ExAC、gnomAD等数据库中频率较高的变异。



噬血细胞综合征（Hemophagocytic lymphohistiocytosis, HLH）是一种罕见的免疫系统疾病，其特征是过度的炎症反应，导致组织损伤。HLH可以是遗传性的，也可以是由感染、恶性肿瘤或自身免疫条件触发的。

在遗传性HLH中，研究已经发现多个基因的突变与疾病的发展有关，这些基因涉及免疫调节和细胞毒性功能。这些突变可能包括：

- **非帧移插入/缺失（nonframeshift insertion/deletion）**：这些突变不改变阅读框架，因此不会导致蛋白质提前终止，但它们可以改变蛋白质的性质，例如通过插入或删除氨基酸来影响功能域或蛋白质稳定性。在某些情况下，非帧移变异可以影响蛋白质功能，与HLH的发病机制相关。

- **剪接（splicing）突变**：剪接突变可能会改变mRNA的剪接方式，导致异常的mRNA和功能不全的蛋白质。这些突变可以位于剪接位点或剪接调节区域，导致剪接模式的改变，可能会影响基因编码的蛋白质的功能，从而与HLH有关。

对于非遗传性HLH，其致病机制可能与遗传易感性以及环境因素（如感染）的相互作用有关。在这种情况下，非帧移插入/缺失和剪接突变也可能对疾病的发展有影响，尤其是如果这些变异影响了免疫系统的关键调节因子。

因此，在您的研究中，应考虑这些类型的突变，并对其进行适当的生物信息学和实验室验证，以确定它们是否在HLH的发病机制中起作用。这可能需要进一步的功能研究，如mRNA和蛋白质表达分析，以及了解变异如何影响细胞功能的实验。

## CLNSIG

在VCF文件中，`CLNSIG`列来自ClinVar数据库，表示一个变异的临床意义。该列可能包含以下类型的值，表示变异对健康影响的可能性：

1. **Uncertain significance**: 不确定的临床意义
2. **Not provided**: 未提供临床意义信息
3. **Benign**: 良性，通常不与疾病相关
4. **Likely benign**: 可能良性，不太可能与疾病相关
5. **Likely pathogenic**: 可能致病，很可能与疾病相关
6. **Pathogenic**: 致病性，已知与疾病相关
7. **Drug response**: 药物反应
8. **Histocompatibility**: 组织相容性，通常涉及移植
9. **Conflicting interpretations of pathogenicity**: 关于致病性的矛盾解释
10. **Risk factor**: 风险因素
11. **Association**: 与疾病有关联
12. **Protective**: 保护性，可能减少疾病风险

在寻找可能致病的变异时，研究者通常会关注标记为“Likely pathogenic”和“Pathogenic”的变异，因为这些变异更可能与疾病状态有关。

您可能想要从您的分析中去除“Benign”、“Likely benign”和“Uncertain significance”（取决于您的研究目标和设计）以及“Not provided”（因为它们没有足够的信息来支持决策）。对于“Conflicting interpretations of pathogenicity”，您可能需要进行更详细的手动审查，因为这些变异的数据可能表明它们在不同的研究或情况下与不同的健康状态相关。

请注意，CLNSIG值可能是以逗号分隔的列表，表示不同提交者可能给出了不同的解释。在这种情况下，您可能需要解析这些值并根据您的具体需求来制定过滤标准。

## MAF

MAF，即Minor Allele Frequency，是指在所有基因型的样本中，次要等位基因（较不常见的等位基因）的频率。在给定的群体中，对于特定的单核苷酸多态性（SNP），可能存在两个或多个等位基因（即基因的不同版本）。在这些等位基因中，频率最高的等位基因称为主要等位基因（major allele），而其他的较少见的等位基因称为次要等位基因（minor alleles）。

举例来说，如果在一个SNP位置，有90%的人群携带碱基"A"，而另外10%的人群携带碱基"G"，那么"A"就是主要等位基因，"G"就是次要等位基因，且该SNP的MAF是10%。

MAF是人口遗传学和疾病关联研究中的一个重要参数，因为它有助于我们了解特定等位基因在群体中的分布情况。在疾病相关性研究中，MAF通常用来筛选候选的致病变异：罕见疾病的致病变异通常具有较低的MAF（例如小于1%或更低），而常见疾病的风险等位基因可能具有较高的MAF。



在遗传病变分析中，去除在一般人群中频率高于特定阈值（如0.01，即1%）的变异，是因为这些变异被认为是人群中的多态性变异，而不太可能直接导致罕见疾病。这个频率确实指的是minor allele frequency（MAF），即次要等位基因在人群中的频率。

HLH（噬血细胞综合征）是一种罕见的免疫系统疾病，通常与特定的遗传变异相关。这些变异在健康人群中的频率通常较低，因为高频率的致病变异会被自然选择淘汰掉。如果一个变异在整个人群中的频率较高（比如超过1%），那么它不太可能是造成HLH这种罕见病症的直接原因。因此，研究者通常会选择去除这些高频变异，以便专注于那些更有可能与疾病相关的低频或稀有变异。

在某些情况下，如果一个已知的病因变异在某个特定群体或种族中的频率较高（可能接近或超过1%），则可能需要根据疾病的流行情况和变异的已知信息来调整这一阈值。此外，还应考虑变异是否与疾病的严重程度、遗传模式或特定临床表型有关。



是的，`ExAC_ALL`, `ExAC_EAS`, `gnomAD_exome_ALL`, `gnomAD_exome_EAS`等列中的频率都代表了minor allele frequency (MAF)。

这些数据来自两个大型人群基因组数据库：

- **ExAC (Exome Aggregation Consortium)**: 这个数据库聚合了多个项目的外显子测序数据，用于发现频繁和罕见的人类编码区变异。

- **gnomAD (Genome Aggregation Database)**: gnomAD数据库包括了外显子（exome）和基因组（genome）的数据，是ExAC的后续扩展和更新。

对于这些列中的频率值：

- `ExAC_ALL` 和 `gnomAD_exome_ALL` 代表在ExAC和gnomAD数据库的所有样本中的MAF。
- `ExAC_EAS` 和 `gnomAD_exome_EAS` 代表在东亚群体（East Asian）中的MAF。

在疾病相关的遗传研究中，MAF用于判断一个变异在一般人群中的常见程度。MAF高于某一阈值（例如1%）的变异通常被认为是多态性的，不太可能是罕见疾病的直接致病因素。相反，MAF较低的变异更可能是罕见疾病的致病或易感变异。因此，在寻找与罕见疾病相关的变异时，研究者通常会排除那些在一般人群中频率较高的变异。

## 预测致病性

在遗传变异分析中，使用多个预测工具（如SIFT4G_pred, Polyphen2_HDIV_pred, MutationTaster_pred, FATHMM_pred, PROVEAN_pred, MetaSVM_pred, MetaLR_pred, REVEL_score等）来评估变异的可能影响是一个很好的做法。这些工具各有其独特的算法和侧重点，通过综合使用它们的结果，可以得到更全面、更可靠的结论。

综合使用的方法通常包括：

1. **多数投票法**：查看这些工具中的大多数给出了什么样的预测（例如，致病或良性）。如果大部分工具都指向同一预测结果，这可能表明该预测更可靠。

2. **权重考虑**：某些工具可能比其他工具更准确或在某些类型的变异上表现更好。如果您知道某些工具在特定情况下更可靠，您可以给这些工具的预测结果更高的权重。

3. **上下文相关分析**：考虑变异发生的基因、已知的疾病关联、以及变异类型（例如错义、无义、剪接等）。某些预测工具在特定情况下可能更准确。

4. **文献和数据库验证**：使用在线数据库（如ClinVar、OMIM）和科学文献来验证这些预测工具的结果。如果一个变异已经在文献中被报道与特定疾病相关，这可能比预测工具的结果更有说服力。

5. **实验验证**：最终，实验验证（如功能实验）是确认变异影响的金标准。如果可能，实验验证可以提供最直接的证据。

在特定情况下，某些工具可能被社群广泛认为更可靠或更适用。例如，REVEL分数是一个综合了多个预测工具的分数，因此它本身就是一种形式的“综合使用”。您可以考虑将REVEL分数与其他单独工具的预测结果相结合，以获得更全面的评估。

总之，综合使用多个预测工具的结果通常会提供更全面和可靠的变异影响评估，但最终的解释和决策应结合特定情况和可用的所有信息。

## 保守性预测

在遗传变异分析中，利用保守性分数（如GERP++_RS, phyloP100way_vertebrate, phastCons100way_vertebrate, SiPhy_29way_logOdds）来过滤SNPs（单核苷酸多态性）和INDELs（插入和缺失）是一种寻找功能上重要的变异的有效方法。高度保守的氨基酸位置更有可能在功能上重要，因为这些位置在进化过程中受到强烈的选择压力，以维持其功能。以下是如何使用这些分数进行过滤的一些指导：

1. **设定阈值**：首先，您需要设定一个阈值来判断什么级别的保守性分数被认为是“高”。这个阈值可能根据不同的保守性分数而有所不同。例如，对于GERP++_RS分数，通常一个较高的正值（如大于2或更高）被认为是保守的。对于phyloP和phastCons分数，接近1的值通常表示高保守性。

2. **过滤低保守性的变异**：在分析时，您可以排除那些保守性分数低于您设定阈值的变异。例如，如果一个SNP或INDEL在所有或大多数保守性度量中得分较低，则可能认为它在功能上不太重要。

3. **结合其他信息**：仅使用保守性分数可能不足以准确判断变异的功能重要性。因此，建议将保守性分数与其他信息（如预测的功能影响、已知的致病性、临床数据等）结合使用。

4. **特别关注高保守性的变异**：高保守性分数的变异应该受到特别关注，尤其是那些位于关键基因或已知与疾病相关的基因区域的变异。这些变异更有可能是致病性的或在疾病的发展中起到关键作用。

5. **实验验证**：最终，实验验证（如功能实验、表型相关性研究）是确认变异功能重要性的最佳方式。

请注意，过滤变异的策略应根据您的研究目的和背景来调整。在某些情况下，即使是保守性分数较低的变异也可能在特定疾病或生物学过程中发挥重要作用。



## vcf文件怎么知道这个突变是indel还是snv 

VCF（Variant Call Format）文件格式被广泛用来存储基因组变异信息。在VCF文件中，可以通过比较参考（REF）和变异（ALT）的碱基来区分SNV（单核苷酸变异）和INDEL（插入或删除）：

- **SNV**：对于单核苷酸变异，REF和ALT字段都会有一个碱基（A、T、C或G），且它们之间不同。例如，如果REF是"A"而ALT是"G"，这表明这是一个SNV。

- **INDEL**：
  - **插入（Insertion）**：REF字段会是一个碱基，而ALT字段会是多个碱基。例如，REF是"A"，而ALT是"ATG"，这表示在参考序列的"A"后面插入了"TG"。
  - **删除（Deletion）**：ALT字段会是一个碱基，而REF字段会是多个碱基。例如，REF是"ATG"，而ALT是"A"，这表示"TG"被删除了。

另外，如果REF和ALT字段中一个是".",这通常表示信息不全或者该位置是非变异的。

在VCF文件中，一行代表一个变异位置，所以你可以按行读取，并根据上述规则来判断每个位置的变异类型。

在使用自动化工具处理VCF文件时，这些工具通常会有内置的逻辑来区分SNV和INDEL。例如，使用生物信息学软件包如`pysam`或`bcftools`时，它们可以解析VCF文件，并根据REF和ALT字段的长度差异来自动识别INDELs和SNVs。

## 常见变异过滤参数

![image-20240428150824258](./assets/image-20240428150824258.png)

### 可选变异过滤参数-MAF

![image-20240428150906751](./assets/image-20240428150906751.png)

# 问题

## 突变与AAChange.refGene不一致

AAChange.refGene列为：PRF1:NM_001083116:exon2:c.C362T:p.A121V,PRF1:NM_005041:exon2:c.C362T:p.A121V 

这一个突变信息为：

PRF1	chr10	70600541	70600541	G	A	exonic 

为什么突变信息是G变成A，而AAChange.refGene显示的是C362T，即C变成T呢？

答案：这种情况通常是由于链特异性造成的。在遗传学中，DNA分子由两条互补的链组成，分别称为正向链（+）和反向链（-）。基因可以位于这两条链的任意一条上。当我们描述DNA变异时，要根据基因所在的链来指定突变。

在您的例子中：

- **基因型变异**: G > A
- **突变注释**: c.C362T

给定的突变信息是G变成A，这表明在+链上，参考（野生型）碱基是G，而突变后的碱基是A。然而，在"AAChange.refGene"中显示的是c.C362T，这说明注释是基于-链进行的，因为在-链上，G的互补碱基是C，A的互补碱基是T。

换句话说，如果基因位于-链上，那么在-链上的参考碱基是C（这与+链上的G互补），并且突变后的碱基是T（这与+链上的A互补）。因此，尽管原始的基因型数据显示的是G > A，由于该基因是在-链上注释的，我们实际上看到的是C > T的变异。

总之，突变描述（G变成A）和氨基酸改变注释（C变成T）之间的差异，是因为这两者是针对不同的DNA链进行描述的。在进行分析和解释时，一定要考虑DNA的双链性质，确保突变是根据基因所在的正确链来注释的。在查看突变数据时，了解基因是位于哪条链上非常重要。

## 样本取样来源不唯一

问：WES外显子测序分析。手上的样本全是患者样本，但是同一个患者有不同的取样来源，有外周血、骨髓、组织、口腔拭子这些。是不是同一个患者的数据应该合并在一起分析，然后再把所有人的结果放一起分析？如果是，应该采用什么分析策略或者流程？

答：所有患者的，用一个样本就好了。优先级看数据量、组织>骨髓>外周血>口腔拭子；如果没有机时计费的限制，都做了。判断逻辑是，数据量是第一优先级，数据量足够，检测的变异准确度高；样本层面，外周血中存在克隆造血突变，口腔拭子中微生物的核酸影响最后的数据产量。所有样本都生成gvcf,然后joint calling生成一个VCF。

如果是单个样本的有多个样本，比如有4个样本，该样本的分型，以多个样本支持的分型为该样本的分型，以GQ高的分型为该样本分型，同样的GQ，以高深度分型为该样本分型；然后在VCF中合并4个来源的样本，每个样本得到一个突变集合。
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTQyNjczNzc5MF19
-->

## 基因型./.

vcf 文件中很多snp在某些样品中是缺失的，也就是基因型为 "./." 。如果缺失率较高，这种snp位点在很多分析中是不能用的，需要去掉。

```bash
vcftools  --vcf snp.vcf  --recode --recode-INFO-all --stdout  --max-missing 1 > snp.new.vcf
```

**--max-missing 后跟的值为 0-1 ，1代表不允许缺失，0代表允许全部缺失**

