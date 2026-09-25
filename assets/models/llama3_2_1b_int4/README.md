# Llama 3.2 1B INT4 Mobile ONNX Bundle

This directory is monitored by `JackLocalLlmEngine` (`lib/services/ai/jack_local_llm_engine.dart`).

## How to download the 100% Free Shrunken Model Files:
1. Visit Hugging Face: [meta-llama/Llama-3.2-1B-Instruct-ONNX](https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct-ONNX)
2. Download the INT4 (4-bit quantized ~600MB) files:
   - `model.onnx`
   - `model.onnx.data`
   - `genai_config.json`
   - `tokenizer.json`
   - `tokenizer_config.json`
   - `special_tokens_map.json`
3. Place them in this folder or in the phone's internal storage (`app_flutter/models/llama3_2_1b_int4/`).

`JackLocalLlmEngine` will automatically extract them on first boot and execute inference on the phone's GPU/NPU in sub-50ms with zero network lag and zero cloud dependencies!
