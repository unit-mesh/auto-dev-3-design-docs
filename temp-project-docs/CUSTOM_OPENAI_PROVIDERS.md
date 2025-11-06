# Custom OpenAI-Compatible Providers

This document explains how to use custom OpenAI-compatible LLM providers with AutoDev, such as ChatGLM, custom endpoints, and other OpenAI API-compatible services.

## Overview

AutoDev supports any LLM provider that implements the OpenAI Chat Completions API. This includes:

- **ChatGLM** (智谱清言) - Chinese LLM by Zhipu AI
- **Custom OpenAI deployments** - Self-hosted or enterprise OpenAI instances
- **OpenAI-compatible APIs** - Any service implementing the OpenAI API spec

## Configuration

### Via Config File

Add a configuration to your `~/.autodev/config.yaml`:

```yaml
active: my-glm

configs:
  - name: my-glm
    provider: custom-openai-base
    apiKey: your-api-key-here
    model: glm-4-plus
    baseUrl: https://open.bigmodel.cn/api/paas/v4
    temperature: 0.7
    maxTokens: 8192
```

### Via CLI

Run `autodev` and follow the interactive setup:

1. Select **Custom OpenAI-compatible** provider
2. Enter your model name (e.g., `glm-4-plus`)
3. Enter your API key
4. Enter the base URL (without `/chat/completions`)
5. Name your configuration

## Supported Providers

### ChatGLM (智谱清言)

**URL:** https://open.bigmodel.cn/

**Configuration:**
```yaml
- name: glm-chat
  provider: custom-openai-base
  apiKey: your-glm-api-key
  model: glm-4-plus
  baseUrl: https://open.bigmodel.cn/api/paas/v4
```

**Available Models:**
- `glm-4-plus` - Latest flagship model
- `glm-4` - Standard model
- `glm-3-turbo` - Fast model

**Getting an API Key:**
1. Visit https://open.bigmodel.cn/
2. Sign up or log in
3. Go to API Keys section
4. Create a new API key

### Other OpenAI-Compatible Providers

For any other OpenAI-compatible provider:

1. Find the base URL (usually ending in `/v1` or similar)
2. Remove the `/chat/completions` part if present
3. Get your API key from the provider
4. Use the model name specified by your provider

Example for a custom deployment:

```yaml
- name: my-custom-openai
  provider: custom-openai-base
  apiKey: sk-custom-key-here
  model: gpt-4-custom
  baseUrl: https://api.mycustom.com/v1
```

## API Endpoint Structure

The custom OpenAI client expects:

- **Base URL:** The root API endpoint (e.g., `https://api.example.com/v1`)
- **Chat Completions Path:** Automatically appended as `chat/completions`
- **Full Endpoint:** `{baseUrl}/chat/completions`

### Example

If your provider's chat completions endpoint is:
```
https://open.bigmodel.cn/api/paas/v4/chat/completions
```

Then your configuration should be:
```yaml
baseUrl: https://open.bigmodel.cn/api/paas/v4
```

The `/chat/completions` part is added automatically.

## Implementation Details

### Architecture

The custom OpenAI support is implemented through:

1. **CustomOpenAILLMClient** (`mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/clients/CustomOpenAILLMClient.kt`)
   - Extends `AbstractOpenAILLMClient`
   - Handles request/response serialization
   - Supports streaming responses

2. **ExecutorFactory** (`mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/ExecutorFactory.kt`)
   - Creates appropriate executor for `CUSTOM_OPENAI_BASE` provider
   - Validates required configuration (baseUrl, apiKey, modelName)

3. **ModelRegistry** (`mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/ModelRegistry.kt`)
   - Creates generic OpenAI-compatible models
   - Uses OpenAI provider settings for compatibility

### Validation

The system validates:
- ✅ API key is provided
- ✅ Model name is provided
- ✅ Base URL is provided
- ✅ Base URL is valid and accessible

### Supported Features

The custom OpenAI client supports:

- ✅ **Streaming responses** - Real-time text generation
- ✅ **Temperature control** - Adjust randomness
- ✅ **Max tokens** - Limit response length
- ✅ **Tool calls** - Function calling (if supported by provider)
- ✅ **Structured output** - JSON schema response format
- ❌ **Moderation** - Not supported (provider-specific)

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to custom endpoint

**Solutions:**
1. Verify the base URL is correct
2. Ensure the URL does NOT include `/chat/completions`
3. Check if the API key is valid
4. Test the endpoint with curl:

```bash
curl -X POST https://your-api-endpoint/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Authentication Errors

**Problem:** 401 Unauthorized or 403 Forbidden

**Solutions:**
1. Verify your API key is correct
2. Check if the API key has expired
3. Ensure your account has sufficient credits/quota
4. Verify the API key format matches the provider's requirements

### Model Not Found

**Problem:** Model name not recognized

**Solutions:**
1. Check the exact model name from your provider's documentation
2. Model names are case-sensitive
3. Some providers use different naming conventions

### Streaming Issues

**Problem:** Responses not streaming correctly

**Solutions:**
1. Ensure the provider supports streaming
2. Check network stability
3. Verify the response format matches OpenAI spec

## Examples

### Minimal Configuration

```yaml
- name: glm
  provider: custom-openai-base
  apiKey: your-key
  model: glm-4-plus
  baseUrl: https://open.bigmodel.cn/api/paas/v4
```

### Full Configuration

```yaml
- name: glm-pro
  provider: custom-openai-base
  apiKey: 7145ac1bf6474f2783e8b4d52b335ab0.gfq0BBvvFy04iwTb
  model: glm-4-plus
  baseUrl: https://open.bigmodel.cn/api/paas/v4
  temperature: 0.7
  maxTokens: 8192
  logLevel: INFO
```

## Testing Your Configuration

To test your custom OpenAI configuration:

1. Save your configuration in `~/.autodev/config.yaml`
2. Run `autodev`
3. Send a simple message: "Hello, can you hear me?"
4. If successful, you'll receive a response from the model

## Contributing

To add support for new OpenAI-compatible providers:

1. Test the provider's compatibility with OpenAI API spec
2. Add an example configuration to this document
3. Update the example config file: `mpp-ui/config.yaml.example`
4. Submit a pull request

## References

- [OpenAI Chat Completions API](https://platform.openai.com/docs/api-reference/chat)
- [ChatGLM API Documentation](https://open.bigmodel.cn/dev/api)
- [AutoDev Configuration Guide](../README.md)

