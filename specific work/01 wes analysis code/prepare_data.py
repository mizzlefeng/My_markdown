# -*- coding: utf-8 -*-
"""
Created on Wed Oct 16 13:12:16 2024

@author: mizzle
"""
import pandas as pd
import os
import argparse

# 使用argparse解析命令行参数
parser = argparse.ArgumentParser(description='Process folder and output paths.')
parser.add_argument('--folder_path', type=str, required=True, help='Path to the folder containing .txt files')
parser.add_argument('--output_path', type=str, required=True, help='Path to the output folder')

# 解析参数
args = parser.parse_args()
folder_path = args.folder_path
output_path = args.output_path

## 获取文件夹中所有以 .txt 结尾的文件名
txt_files = [f for f in os.listdir(folder_path) if f.endswith('.txt') and os.path.isfile(os.path.join(folder_path, f))]
#label = pd.read_excel("./患者订单编号.xlsx")
#
#sup_data = pd.read_excel("./ReleaseRawData.info注.xlsx")
#sup_data = sup_data[['PatientID','SampleID']]
#sup_data.rename(columns={"PatientID":"订单编号"},inplace=True)
#merge_df = pd.merge(label, sup_data,on="订单编号")
#
#merge_df['样本类型'] = merge_df['样本类型'].replace('Tumor', 'T')
#merge_df['样本类型'] = merge_df['样本类型'].replace('Organoids', 'O')

# 打印所有文件名
for file_name in txt_files:
    data = pd.read_csv(os.path.join(folder_path, file_name),sep='\t')

    data = data[data['Otherinfo10']=="PASS"]
    
    # 查找匹配并生成new_name
#    matching_row = merge_df[merge_df['SampleID'].apply(lambda x: x in file_name)]
    
#    if not matching_row.empty:
#        new_name = "{}_{}".format(matching_row.iloc[0]['序号'], matching_row.iloc[0]['样本类型'])
#        print("New name: {}".format(new_name))
#    else:
#        raise ValueError("no match name")
    
    # 新增一列，将'chr'、'Start'、'Gene.refGene'拼接为字符串，中间用":"
    data['mutation_id'] = data['Chr'].astype(str) + ':' + data['Start'].astype(str) + ':' + data['Gene.refGene'].astype(str)
    
    def cal_ref(x):
        AD=x.split(':')[1]
        return AD.split(",")[0]
    
    def cal_alt(x):
        AD=x.split(':')[1]
        DP=int(x.split(':')[3])
        return DP - int(AD.split(",")[0])
    
    
    def get_genotype(x):
        AD=x.split(':')[1]
        DP=int(x.split(':')[3])
        return DP - int(AD.split(",")[0])
    
    data['ref_counts']=data['Otherinfo13'].apply(lambda x: cal_ref(x))
    data['var_counts']=data['Otherinfo13'].apply(lambda x: cal_alt(x))
    data['normal_cn']=2
    data['minor_cn']=0
    data['major_cn']=2
    data['Genotype']=data['Otherinfo13'].apply(lambda x: x.split(':')[0])
    
    # 根据字符串类型的Genotype列判断并更新minor_cn和major_cn
    data.loc[data['Genotype'].str.contains('0'), ['minor_cn', 'major_cn']] = [1, 1]
    data.loc[~data['Genotype'].str.contains('0'), ['minor_cn', 'major_cn']] = [0, 2]
    
    data = data[['Chr','Start','End','mutation_id','ref_counts','var_counts','normal_cn','minor_cn','major_cn']]
    
    data.rename(columns={"Chr":"Chromosome","Start":"Start_Position","End":"End_Position"},inplace=True)
#    data.to_csv(os.path.join(output_path, new_name+".csv"),index=False,sep="\t")
    data.to_csv(os.path.join(output_path, file_name+".csv"),index=False,sep="\t")











