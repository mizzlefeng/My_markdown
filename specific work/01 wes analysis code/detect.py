# -*- coding: utf-8 -*-
import pandas as pd
import os
import glob
import pprint
import argparse

# 使用argparse解析命令行参数
parser = argparse.ArgumentParser(description='Process folder and output paths.')
parser.add_argument('--root_path', type=str, required=True, help='Path to the folder containing .txt files')
parser.add_argument('--paper_data', type=str, required=True, help='Path to the paper data result')

# 解析参数
args = parser.parse_args()
root_path = args.root_path
paper_data = args.paper_data

#root_path = "/home/multi_omics/moas/data/test/genome/102/align/annovar"
#root_path = "../annovar/"
#print(root_path)
file_pattern = "*.hg19_multianno.txt" # 通配形式，可能会修改
file_paths = glob.glob(os.path.join(root_path, file_pattern))
for i in file_paths:
	print(i)

data_dic={
    "SRR7739527":['Organoid',4056],
    "SRR7739529":['Organoid',54],
    "SRR7739530":['Patient',54],
    "SRR7739531":['Patient',274],
    "SRR7739532":['Organoid',426],
    "SRR7739534":['Patient',426],
    "SRR7739535":['Organoid',274],
    "SRR7739538":['Patient',149],
    "SRR7739540":['Organoid',149],
}


pprint.pprint(data_dic)
paper_data_F = pd.read_excel(paper_data)
paper_data_F.rename(columns={'Chromosome': 'Chr', 'Start_Position_hg19': 'Start', 'Reference_Allele': 'Ref', 'Alternative_Allele': 'Alt','Hugo_Symbol': 'Gene.refGene'}, inplace=True)

common_rate_lst = []
for file in file_paths:
    my_data_F = pd.read_table(file,sep="\t")
    f = file.split("/")[-1]
    sample_name = f.split(".")[0] # 根据路径获取样本名，可能会修改
#    print(sample_name)

    attr = data_dic[sample_name]
  
    paper_data = paper_data_F[(paper_data_F['Sample']==attr[1]) & (paper_data_F['Type']==attr[0])]

    my_data = my_data_F[['Chr','Start','Ref','Alt','Gene.refGene']]
    paper_data = paper_data[['Chr','Start','Ref','Alt','Gene.refGene']]

    common_rows=pd.merge(paper_data[['Chr','Start','Ref','Alt','Gene.refGene']], my_data[['Chr','Start', 'Ref','Alt','Gene.refGene']])
    paper_mut = paper_data.shape[0]
    common_mut = common_rows.shape[0]
    common_rate = common_rows.shape[0]/paper_data.shape[0]
    common_rate_lst.append(common_rate* 100)
#    print(f"样本号:{sample_name}"+"\t"+f"样本属性:{attr}"+"\t"+f"原文突变数:{paper_mut}"+"\t"+f"一致突变数:{common_mut}"+"\t"+f"突变一致率:{common_rate:.2%}")
    print("样本号:%s\t样本属性:%s\t原文突变数:%s\t一致突变数:%s" % (sample_name, attr, paper_mut, common_mut))

average_common_rate = sum(common_rate_lst) / len(common_rate_lst)
print("平均突变一致率:%.2f%%" % average_common_rate)