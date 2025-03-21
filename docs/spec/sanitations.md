_Author_:  @rtweera\
_Created_: 2025/03/20 \
_Updated_: 2025/03/20 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the generated OpenAPI specification for Ollama.
The OpenAPI specification is obtained from [Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. Change the `url` property of the objects in servers array

   - **Original**:
   `http://localhost:11434`

   - **Updated**:
   `http://localhost:11434/api`

   - **Reason**: This change of adding the common prefix `/api` to the base url makes it easier to access the endpoints using the client, also makes the code readable.

2. Update the API `paths`

   - **Original**: Paths included the common prefix above `/api` in each endpoint.
   `/api/chat`

   - **Updated**: Common prefix removed from path endpoints.
   `/chat`

   - **Reason**: This simplifies the API paths making them shorter and easier to read.

3. Change datatype `date-time` to `datetime`

   - **Original**: `date-time`

   - **Updated**: `datetime`

   - **Reason**: Original `date-time` format is not supported in Ballerina.

4. Add `tool` role to the enums of `Message` object

   - **Original**: The original OpenAPI spec did not include `tool` role in the `Message` object.
   `enum: ["system", "user", "assistant"]`

   - **Updated**: Added `tool` role to the `Message` object.
   `enum: ["system", "user", "assistant", "tool"]`

   - **Reason**: The `tool` role supported by Ollama (for supported models only), but it was missing from the OpenAPI spec. This change ensures that the generated client can handle this role correctly.

5. Change `minItems` in `components\schemas\ChatRequest\properties\messages` to `0`

   - **Original**: The original OpenAPI spec had `minItems` set to `1`.

   - **Updated**: Changed `minItems` to `0`.

   - **Reason**: Ollama API have an option to load the model by setting the `messages` object to an empty array. To add this functionality to the client, API spec was updated to acccept empty arrays.

6. Add `tools` property to ChatRequest schema

   - **Original**: The original OpenAPI spec did not include `tools` property in the `ChatRequest` object.

   - **Updated**: Added `tools` property to the `ChatRequest` object.

   ```yaml
   tools:
     type: array
     items:
       $ref: '#/components/schemas/Tool'
     description: List of tools (e.g., functions) available for the model to use, if supported.
     minItems: 0
   ```

   - **Reason**: Tool calling is supported by Ollama (for supported models), but it was missing from the OpenAPI spec. This change allows the client to specify available tools for the model to use.

7. Add new schemas for tool calling

   - **Original**: The original OpenAPI spec did not include schemas for tool calling.

   - **Updated**: Added `Tool` and `ToolCall` schemas to support tool calling functionality.

   - **Reason**: These schemas are required to properly implement tool calling, allowing models to invoke predefined functions and to properly handle tool call responses.

8. Add `tool_calls` property to Message schema

   - **Original**: The original OpenAPI spec did not include `tool_calls` property in the `Message` object.

   - **Updated**: Added `tool_calls` property to the `Message` object.

   ```yaml
   tool_calls:
     type: array
     items:
       $ref: '#/components/schemas/ToolCall'
     description: List of tool calls requested by the assistant (present when the model invokes tools).
   ```

<!-- 4. Add `done_reason` to `GenerateStreamResponse` object

   - **Original**: The original OpenAPI spec did not include `done_reason` in the `GenerateStreamResponse` object.

   - **Updated**: Added `done_reason` to the `GenerateStreamResponse` object.

   - **Reason**: `done_reason` is provided in the last response from the server. -->

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/openapi.yaml --mode client --license docs/license.txt -o ballerina 
```

Note: The license year is hardcoded to 2025, change if necessary.
