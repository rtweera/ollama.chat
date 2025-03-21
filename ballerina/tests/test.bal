// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/os;
import ballerina/test;
import ballerina/io;

configurable decimal timeout = 240.0;
configurable string liveServerUrl = "http://localhost:11434/api";
configurable string mockServerUrl = "http://localhost:9090";
configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

const string llama3_2 = "llama3.2";
const string mistral = "mistral";
const string deepseek = "deepseek-r1";
const string llava = "llava";
const string incorrectModel = "model_xyz";
const string suffix = "Ends your answer with `I am fine.`";
const string prompt = "Hello, how are you?";
const string personPrompt = "Tell me about an imaginary person named " + personName + " who is " + personAge + " years old. Give me the answer in structured format.";
const string personName = "John Doe";
const string personAge = "30";
type Person record {
    string name;
    int age;
};

final Client ollama = check initClient();

isolated function initClient() returns Client|error {
    if isLiveServer {
        return check new ({
            timeout: timeout
        }, liveServerUrl);
    }
    return check new ({}, mockServerUrl);
}

@test:BeforeSuite
function beforeSuite() returns error? {
    // TODO: Need to check the availability of the needed ollama models before running the tests. This has to be done
    // through the ollama.manage connector, which is yet to be implemented.
}

@test:Config {
    groups: ["negative_tests", "loading"]
}
isolated function testLoadUnavailableModel() returns error? {
    ChatRequest request = {
        model: incorrectModel,
        messages: []
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is http:ClientRequestError, "Error loading unavailable model");
    if response is http:ClientRequestError {
        test:assertEquals(response.detail()["statusCode"], 404, "Invalid status code for unavailable model");
    }
}

@test:Config {
    groups: ["positive_tests", "loading"]
}
isolated function testLoadAvailableModel() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [],
        'stream: true
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatStreamResponse, "Error loading available model");
    if response is ChatStreamResponse {
        test:assertEquals(response.done, true, "Invalid field value for done");
        test:assertEquals(response?.done_reason ?: "", "load", "Done reason should be load");
        test:assertEquals(response.message.content, "", "Message content should be empty");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "stream_response"],
    enable: false
}
isolated function testStreamResponse() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: prompt
            }
        ],
        'stream: true
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    io:println("Response: ", response);
    test:assertTrue(response is ChatStreamResponse, "Error generating stream response");
    if response is ChatStreamResponse {
        test:assertEquals(response.done, false, "Stream response should not be done for the first chunk");
        test:assertNotEquals(response.message.content, "", "Message content should not be empty");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "single_response"]
}
isolated function testSingleResponse() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: prompt
            }
        ],
        'stream: false
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response");
    if response is ChatSingleResponse {
        test:assertEquals(response.done, true, "Single response should be done");
        test:assertNotEquals(response.message.content, "", "Message content should not be empty");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "single_response", "system_message"],
    enable: false
}
isolated function testSingleResponseWithSystemMessage() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "You must end your answer with 'I am fine.'"
            },
            {
                role: "user",
                content: prompt
            }
        ],
        'stream: false
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    io:print("Response: ", response);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response with system message");
    if response is ChatSingleResponse {
        test:assertEquals(response.done, true, "Single response should be done");
        test:assertTrue(response.message.content.endsWith("I am fine."), "Response should end with 'I am fine.'");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "stream_response", "structured_response"]
}
isolated function testSingleResponseWithJsonFormat() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: "Respond with a simple JSON object containing name and age for " + personName + " who is " + personAge + " years old."
            }
        ],
        'stream: false,
        format: "json"
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response with JSON format");
    if response is ChatSingleResponse {
        json|error jsonParsed = response.message.content.fromJsonString();
        test:assertTrue(jsonParsed is json, "Message.content should be JSON");
    }
}

@test:Config {
    groups: ["negative_tests", "chat", "stream_response", "structured_response"]
}
isolated function testSingleResponseWithJsonFormatFails() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: prompt
            }
        ],
        'stream: false
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response without JSON format");
    if response is ChatSingleResponse {
        io:println("JSONFAILS: ", response.message.content);
        json|error jsonParsed = response.message.content.fromJsonString();
        test:assertFalse(jsonParsed is json, "Message.content should not be JSON");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "stream_response", "structured_response"]
}
isolated function testSingleResponseWithOptions() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: personPrompt
            }
        ],
        'stream: false,
        options: {
            temperature: 0.7,
            top_p: 0.9,
            num_ctx: 2048
        }
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response with options");
    if response is ChatSingleResponse {
        io:println("Response: ", response.message.content);
        test:assertNotEquals(response.message.content, "", "Message content can't be empty");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "stream_response", "multimodal"]
}
isolated function testSingleResponseWithImages() returns error? {
    ChatRequest request = {
        model: llava,
        messages: [
            {
                role: "user",
                content: "what is in this image?",
                images: getImages()
            }
        ],
        'stream: false
    };
    ChatStreamResponse|ChatSingleResponse|error response = ollama->/chat.post(request);
    io:println("Response: ", response);
    test:assertTrue(response is ChatSingleResponse, "Error generating single response with images");
    if response is ChatSingleResponse {
        test:assertNotEquals(response.message.content, "", "Message content can't be empty");
    }
}

// Sample tool response for testing tool calls
const string calculatorToolResponse = "The answer is 42";

@test:Config {
    groups: ["positive_tests", "chat", "conversation"]
}
isolated function testContinuedConversation() returns error? {
    // Initial question
    ChatRequest initialRequest = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: "What are the three primary colors?"
            }
        ],
        'stream: false
    };
    ChatSingleResponse|ChatStreamResponse|error initialResponse = ollama->/chat.post(initialRequest);
    test:assertTrue(initialResponse is ChatSingleResponse, "Error in first conversation turn");
    
    string assistantResponse = "";
    if initialResponse is ChatSingleResponse {
        assistantResponse = initialResponse.message.content;
        test:assertNotEquals(assistantResponse, "", "Initial response cannot be empty");
    }
    
    // Follow-up question referencing previous context
    ChatRequest followupRequest = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: "What are the three primary colors?"
            },
            {
                role: "assistant",
                content: assistantResponse
            },
            {
                role: "user",
                content: "What colors do you get when you mix them?"
            }
        ],
        'stream: false
    };
    
    ChatSingleResponse|ChatStreamResponse|error followupResponse = ollama->/chat.post(followupRequest);
    test:assertTrue(followupResponse is ChatSingleResponse, "Error in follow-up conversation turn");
    
    if followupResponse is ChatSingleResponse {
        test:assertNotEquals(followupResponse.message.content, "", "Follow-up response cannot be empty");
        io:println("Follow-up response: ", followupResponse.message.content);
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "tool_calling"],
    enable: isLiveServer
}
isolated function testToolCalling() returns error? {
    // Initial request with system prompt for tool use
    ChatRequest toolRequest = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "When a calculation is needed, you must use the calculator tool. Never calculate yourself."
            },
            {
                role: "user",
                content: "What is 6 times 7?"
            }
        ],
        tools: [
            {
                'type: "function",
                'function: {
                    name: "calculator",
                    description: "Perform mathematical calculations",
                    parameters: {
                        "type": "object",
                        "properties": {
                            "expression": {
                                "type": "string",
                                "description": "The mathematical expression to evaluate"
                            }
                        },
                        "required": ["expression"]
                    }
                }
            }
        ],
        'stream: false
    };
    
    ChatSingleResponse|ChatStreamResponse|error toolResponse = ollama->/chat.post(toolRequest);
    test:assertTrue(toolResponse is ChatSingleResponse, "Error in tool initiation request");
    
    if toolResponse is ChatSingleResponse {
        string responseContent = toolResponse.message.content;
        
        // Verify tool call format
        test:assertFalse(toolResponse.message?.tool_calls is (), "Tool calls should be present in the response");
        
        if toolResponse.message?.tool_calls is ToolCall[] {
            ToolCall[] toolCalls = <ToolCall[]>toolResponse.message?.tool_calls;
            test:assertTrue(toolCalls.length() > 0, "At least one tool call should be present");
            
            ToolCall toolCall = toolCalls[0];
            test:assertFalse(toolCall.'function is (), "Function details should be present in tool call");
            
            if toolCall.'function is ToolCall_function {
                ToolCall_function? functionDetails = toolCall.'function;

                test:assertFalse(functionDetails is (), "Function details should not be empty");
                
                // Verify tool name and arguments
                test:assertEquals(functionDetails?.name, "calculator", "Tool name should be 'calculator'");
                test:assertTrue(functionDetails?.arguments.toString().includes("expression"), 
                               "Tool arguments should include 'expression' parameter");
                
                // Extract the expression from arguments for demonstration
                json arguments = functionDetails?.arguments.toJson();
                test:assertTrue(arguments is json, "Arguments should be JSON");
                json expressionArg = check arguments.expression;
                // json expressionArg = check functionDetails.arguments.expression;
                test:assertTrue(expressionArg is string, "Expression argument should be a string");
                test:assertTrue((<string>expressionArg).includes("6") && (<string>expressionArg).includes("7"), 
                               "Expression should include operands 6 and 7");
            }
        }
        
        // Simulate tool call response
        ChatRequest toolCallbackRequest = {
            model: llama3_2,
            messages: [
                {
                    role: "system",
                    content: "When a calculation is needed, you must use the calculator tool. Never calculate yourself."
                },
                {
                    role: "user",
                    content: "What is 6 times 7?"
                },
                {
                    role: "assistant",
                    content: responseContent,
                    tool_calls: toolResponse.message?.tool_calls
                },
                {
                    role: "tool",
                    content: calculatorToolResponse
                }
            ],
            'stream: false
        };
        
        ChatSingleResponse|ChatStreamResponse|error finalResponse = ollama->/chat.post(toolCallbackRequest);
        test:assertTrue(finalResponse is ChatSingleResponse, "Error in tool callback response");
        
        if finalResponse is ChatSingleResponse {
            test:assertNotEquals(finalResponse.message.content, "", "Tool callback response cannot be empty");
            
            // Verify final response incorporates tool results
            test:assertTrue(finalResponse.message.content.includes("42") || 
                           finalResponse.message.content.includes("forty-two") || 
                           finalResponse.message.content.includes("forty two"), 
                           "Final response should include the result from the tool");
            
            io:println("Tool callback response: ", finalResponse.message.content);
        }
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "tool_calling", "multiple_tools"],
    enable: isLiveServer
}
isolated function testMultipleToolCalling() returns error? {
    // Request with multiple available tools
    ChatRequest toolRequest = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "Use the appropriate tool when needed."
            },
            {
                role: "user",
                content: "What's the weather in New York and what is 5 plus 7?"
            }
        ],
        tools: [
            {
                'type: "function",
                'function: {
                    name: "calculator",
                    description: "Perform mathematical calculations",
                    parameters: {
                        "type": "object",
                        "properties": {
                            "expression": {
                                "type": "string",
                                "description": "The mathematical expression to evaluate"
                            }
                        },
                        "required": ["expression"]
                    }
                }
            },
            {
                'type: "function",
                'function: {
                    name: "get_weather",
                    description: "Get current weather for a location",
                    parameters: {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "The city name"
                            },
                            "unit": {
                                "type": "string",
                                "enum": ["celsius", "fahrenheit"],
                                "description": "Temperature unit"
                            }
                        },
                        "required": ["location"]
                    }
                }
            }
        ],
        'stream: false
    };
    
    ChatSingleResponse|ChatStreamResponse|error toolResponse = ollama->/chat.post(toolRequest);
    test:assertTrue(toolResponse is ChatSingleResponse, "Error in multiple tool request");
    
    if toolResponse is ChatSingleResponse {
        // Verify tool call format
        test:assertFalse(toolResponse.message?.tool_calls is (), "Tool calls should be present in the response");
        
        if toolResponse.message?.tool_calls is ToolCall[] {
            ToolCall[] toolCalls = <ToolCall[]>toolResponse.message?.tool_calls;
            
            // Process each tool call and prepare responses
            Message[] toolResponses = [];
            foreach ToolCall toolCall in toolCalls {
                if toolCall.'function is ToolCall_function {
                    ToolCall_function? functionDetails = toolCall.'function;

                    test:assertFalse(functionDetails is (), "Function details should be present in tool call");
                    
                    // Prepare appropriate tool response based on tool name
                    if (functionDetails?.name == "calculator") {
                        toolResponses.push({
                            role: "tool",
                            content: "The result is 12"
                        });
                    } else if (functionDetails?.name == "get_weather") {
                        toolResponses.push({
                            role: "tool",
                            content: "It's currently 75°F and sunny in New York"
                        });
                    }
                }
            }
            
            // Only proceed if we have tool responses
            if (toolResponses.length() > 0) {
                // Create messages array for callback request
                Message[] callbackMessages = [
                    {
                        role: "system",
                        content: "Use the appropriate tool when needed."
                    },
                    {
                        role: "user",
                        content: "What's the weather in New York and what is 5 plus 7?"
                    },
                    {
                        role: "assistant",
                        content: toolResponse.message.content,
                        tool_calls: toolResponse.message?.tool_calls
                    }
                ];
                
                // Add tool responses
                foreach Message toolResp in toolResponses {
                    callbackMessages.push(toolResp);
                }
                
                // Send callback request with tool responses
                ChatRequest finalRequest = {
                    model: llama3_2,
                    messages: callbackMessages,
                    'stream: false
                };
                
                ChatSingleResponse|ChatStreamResponse|error finalResponse = ollama->/chat.post(finalRequest);
                test:assertTrue(finalResponse is ChatSingleResponse, "Error in multiple tool callback response");
                
                if finalResponse is ChatSingleResponse {
                    // Verify final response incorporates results from both tools
                    test:assertTrue(finalResponse.message.content.includes("12") || 
                                  finalResponse.message.content.includes("twelve"), 
                                  "Final response should include calculator result");
                    
                    test:assertTrue(finalResponse.message.content.includes("New York") && 
                                  (finalResponse.message.content.includes("sunny") || 
                                   finalResponse.message.content.includes("75")), 
                                  "Final response should include weather information");
                }
            }
        }
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "json_validation"]
}
isolated function testJsonOutputValidation() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "You are a structured data API. Always respond with valid JSON."
            },
            {
                role: "user",
                content: "Give me details about a person named " + personName + " who is " + personAge + 
                         " years old. Include name, age, occupation, and a list of hobbies."
            }
        ],
        'stream: false,
        format: "json"
    };
    
    ChatSingleResponse|ChatStreamResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating JSON response");
    
    if response is ChatSingleResponse {
        json|error jsonResponse = response.message.content.fromJsonString();
        test:assertTrue(jsonResponse is json, "Response should be valid JSON");
        
        if jsonResponse is json {
            // Check expected structure
            json nameValue = check jsonResponse.name;
            test:assertTrue(nameValue is string, "Name field should be a string");
            test:assertEquals(nameValue.toString(), personName, "Name should match requested person");
            
            json ageValue = check jsonResponse.age;
            test:assertTrue(ageValue is int|string, "Age field should be a number or string");
            
            // Convert to string for comparison since age could be number or string
            test:assertEquals(ageValue.toString(), personAge, "Age should match requested age");
            
            json occupationValue = check jsonResponse.occupation;
            test:assertTrue(occupationValue is string, "Occupation field should be a string");
            
            json hobbiesValue = check jsonResponse.hobbies;
            test:assertTrue(hobbiesValue is json[], "Hobbies field should be an array");
        }
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "chat_history"]
}
isolated function testComplexConversationHistory() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "You are a helpful assistant."
            },
            {
                role: "user",
                content: "Hello, my name is Alice."
            },
            {
                role: "assistant",
                content: "Hello Alice! How can I help you today?"
            },
            {
                role: "user",
                content: "I'm planning a trip to Paris."
            },
            {
                role: "assistant",
                content: "That sounds exciting! Paris is a beautiful city. What would you like to know about Paris?"
            },
            {
                role: "user",
                content: "Can you recommend some must-see attractions?"
            }
        ],
        'stream: false
    };
    
    ChatSingleResponse|ChatStreamResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error with complex conversation history");
    
    if response is ChatSingleResponse {
        test:assertNotEquals(response.message.content, "", "Response with conversation history cannot be empty");
        // Should mention Paris attractions since the context has been maintained
        test:assertTrue(response.message.content.includes("Eiffel") || 
                       response.message.content.includes("Louvre") || 
                       response.message.content.includes("Notre Dame") || 
                       response.message.content.includes("attraction") || 
                       response.message.content.includes("visit"), 
                       "Response should be relevant to Paris attractions");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "long_context"]
}
isolated function testLongContextHandling() returns error? {
    // Create a long prompt that approaches context window limits
    string longPrompt = "Summarize the following text in 3 bullet points: " + 
                        string:'join("", from int i in 1...100 select "The quick brown fox jumps over the lazy dog. ");
    
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "user",
                content: longPrompt
            }
        ],
        'stream: false,
        options: {
            num_ctx: 4096  // Ensure large context window
        }
    };
    
    ChatSingleResponse|ChatStreamResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse || response is http:ClientRequestError, 
                  "Long context should either return a valid response or a well-formed error");
    
    if response is ChatSingleResponse {
        test:assertNotEquals(response.message.content, "", "Long context response cannot be empty");
        test:assertTrue(response.message.content.includes("•") || 
                       response.message.content.includes("-") || 
                       response.message.content.includes("1."), 
                       "Response should contain bullet points");
    }
}

@test:Config {
    groups: ["positive_tests", "chat", "function_outputs"]
}
isolated function testGeneratingCode() returns error? {
    ChatRequest request = {
        model: llama3_2,
        messages: [
            {
                role: "system",
                content: "You are a helpful programming assistant specializing in Ballerina language."
            },
            {
                role: "user",
                content: "Write a simple Ballerina function that calculates the factorial of a number."
            }
        ],
        'stream: false
    };
    
    ChatSingleResponse|ChatStreamResponse|error response = ollama->/chat.post(request);
    test:assertTrue(response is ChatSingleResponse, "Error generating code");
    
    if response is ChatSingleResponse {
        test:assertNotEquals(response.message.content, "", "Code generation response cannot be empty");
        // Check for code block markers or function signature
        test:assertTrue(response.message.content.includes("function factorial") || 
                       response.message.content.includes("```") || 
                       response.message.content.includes("public function"), 
                       "Response should contain Ballerina code");
    }
}
