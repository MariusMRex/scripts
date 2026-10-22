#!/bin/bash

export LLAMA_CACHE="/home/marius/AI/cache"
cd ~/AI
# Using model and settings from https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF
#/home/marius/git/llama.cpp/build/bin/llama-server -hf unsloth/gemma-4-26B-A4B-it-GGUF:MXFP4_MOE \
/home/marius/git/llama.cpp/build/bin/llama-server -m models/unsloth/gemma-4-26B-A4B-it-MXFP4_MOE.gguf \
--jinja \
--host 172.18.93.12 \
--temperature 1.0 \
--top-p 0.95 \
--top-k 64 \
--port 8001
