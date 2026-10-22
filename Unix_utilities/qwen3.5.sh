#!/bin/bash

export LLAMA_CACHE="/home/marius/AI/cache"
cd ~/AI
# Using model and settings from https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF
#/home/marius/git/llama.cpp/build/bin/llama-server -hf unsloth/Qwen3.5-9B-MTP-GGUF:UD-Q4_K_XL \
/home/marius/git/llama.cpp/build/bin/llama-server -m models/unsloth/Qwen3.5-9B-UD-Q4_K_XL.gguf \
-ngl 99 \
-c 8192 \
-fa on \
-np 1 \
--spec-type draft-mtp \
--spec-draft-n-max 6 \
--jinja \
--host 172.18.93.12 \
--port 8002
