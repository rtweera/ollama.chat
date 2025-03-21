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
