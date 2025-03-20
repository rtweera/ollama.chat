// // Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
// //
// // WSO2 LLC. licenses this file to you under the Apache License,
// // Version 2.0 (the "License"); you may not use this file except
// // in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing,
// // software distributed under the License is distributed on an
// // "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// // KIND, either express or implied.  See the License for the
// // specific language governing permissions and limitations
// // under the License.

// import ballerina/http;

// type ErrorResponse record {
//     string 'error;
//     int statusCode;
// };

// service / on new http:Listener(9090) {
//     isolated resource function post generate(@http:Payload GenerateRequest payload) returns json|http:Error {
//         if payload.model == incorrectModel {
//             // error<ErrorResponse> error404 = error("Error from mock service", 'error="model 'model_xyz' not found", statusCode=404);
//             // return error("Error from mock service", 'error="model 'model_xyz' not found", statusCode=404);
//             return {statusCode: 500,
//         body:{message: "Error from mock service kjhkfjdhksfhkfjhjk"}};
//             // return error404;
//         } else if payload.model == llama3_2 {
//             if payload.'stream == true {    // TODO: Stream logic is not checked; this is only a stub
//                 return {
//                     model: payload.model,
//                     created_at: "2023-08-04T19:22:45.499127Z",
//                     response: "",
//                     done: true,
//                     done_reason: "load"
//                 };
//             } else if payload.format is string && payload.format == "json" {
//                 return {
//                     model: payload.model,
//                     created_at: "2023-08-04T19:22:45.499127Z",
//                     response: "{\"id\": 12, \"name\": \"John\"}",
//                     done: true
//                 };
//             } else if payload.format is json {
//                 return {
//                     model: payload.model,
//                     created_at: "2023-08-04T19:22:45.499127Z",
//                     response: "{\"name\":\"John Doe\",\"age\":30}",
//                     done: true
//                 };
//             } else {
//                 return {
//                     model: payload.model,
//                     created_at: "2023-08-04T19:22:45.499127Z",
//                     response: "The sky is blue because it is the color of the sky.",
//                     done: true
//                 };
//             }
//         } else if payload.model == llava && payload.images is string[] {
//             return {
//                 model: payload.model,
//                 created_at: "2023-08-04T19:22:45.499127Z",
//                 response: "A happy cartoon character, which is cute and cheerful.",
//                 done: true
//             };
//         } else if payload.model == deepseek && payload.suffix is string {
//             return {
//                 model: payload.model,
//                 created_at: "2023-08-04T19:22:45.499127Z",
//                 response: "Hello, how are you? I am fine.",
//                 done: true
//             };
//         }
//         // error<ErrorResponse> error500 = error("Error from mock service", 'error="model 'model_xyz' not found", statusCode=500);
//         return {statusCode: 500,
//         body:{message: "Error from mock service gfghddgfdgfdgf"}};
//     }
// }
