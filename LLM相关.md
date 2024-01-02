# text-generation-webui
```
cd /home/mizzle/llm/text-generation-webui
# 需要使用--listen参数来打开监听窗口
python server.py --listen --api 

# 内网穿透
ngrok http 11.11.11.101:7860
```

# model参数的下载HF镜像
```
git clone https://github.com/LetheSec/HuggingFace-Download-Accelerator.git
cd HuggingFace-Download-Accelerator

python hf_download.py --model lmsys/vicuna-7b-v1.5 --save_dir ./hf_hub
```
```
```
<!--stackedit_data:
eyJoaXN0b3J5IjpbMTY5MjQ1OTIyOCwtOTI0MzEzNTEsLTY0OT
A2NjQyMF19
-->