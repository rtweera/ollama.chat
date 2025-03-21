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
