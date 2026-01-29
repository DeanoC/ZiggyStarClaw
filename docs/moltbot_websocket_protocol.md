# Moltbot WebSocket Protocol Documentation

**Author:** Manus AI
**Date:** January 29, 2026

## 1. Introduction

The Moltbot ecosystem utilizes a comprehensive WebSocket-based protocol for its single control plane and node transport layer. All clients, including the command-line interface (CLI), web-based user interfaces, and companion applications (macOS, iOS, Android), connect to a central Gateway via this protocol. This document provides a detailed overview of the protocol, its message formats, and the communication patterns that govern the interactions between clients and the Gateway. The information is derived from the analysis of the official `moltbot` source code [1].

## 2. Transport and Framing

The protocol is built on top of a standard WebSocket connection, using text frames with JSON-encoded payloads. All communication adheres to a simple yet robust framing structure that distinguishes between requests, responses, and asynchronous events.

There are three fundamental frame types, identified by a `type` field in the JSON payload:

| Frame Type | Description                                                                 |
| :--------- | :-------------------------------------------------------------------------- |
| `req`      | A **Request** frame, used by a client to invoke a method on the server (RPC). |
| `res`      | A **Response** frame, used by the server to reply to a specific request.      |
| `event`    | An **Event** frame, used by the server to push asynchronous notifications to clients. |

### 2.1. Frame Schemas

The basic structure for each frame type is defined as follows [2]:

**Request Frame (`req`)**

```json
{
  "type": "req",
  "id": "<unique_request_id>",
  "method": "<method_name>",
  "params": { ... }
}
```

**Response Frame (`res`)**

```json
{
  "type": "res",
  "id": "<unique_request_id>",
  "ok": true | false,
  "payload": { ... },
  "error": { ... }
}
```

**Event Frame (`event`)**

```json
{
  "type": "event",
  "event": "<event_name>",
  "payload": { ... },
  "seq": 123,
  "stateVersion": { ... }
}
```

- The `id` field in `req` and `res` frames is used to correlate requests with their corresponding responses.
- The `ok` field in the `res` frame indicates whether the request was successful. If `false`, the `error` field will contain a structured error object.
- The `seq` field in the `event` frame is a sequence number that allows clients to detect message gaps.


## 3. Handshake and Connection Establishment

A WebSocket connection to the Moltbot Gateway is initiated with a mandatory handshake process. The first frame sent by the client **must** be a `connect` request. This request serves to authenticate the client, declare its capabilities, and negotiate the protocol version.

### 3.1. The `connect` Method

The client initiates the handshake by sending a `connect` request. The `params` object of this request contains detailed information about the client's identity, capabilities, and authentication credentials.

**Client `connect` Request Parameters**

| Parameter         | Type     | Description                                                                                             |
| :---------------- | :------- | :------------------------------------------------------------------------------------------------------ |
| `minProtocol`     | `number` | The minimum protocol version supported by the client.                                                   |
| `maxProtocol`     | `number` | The maximum protocol version supported by the client.                                                   |
| `client`          | `object` | An object containing detailed information about the client application (see below).                     |
| `caps`            | `array`  | An array of strings representing the client's high-level capabilities (e.g., `camera`, `screen`).        |
| `commands`        | `array`  | An array of strings listing the specific commands the client can execute (e.g., `camera.snap`).         |
| `permissions`     | `object` | A map of granular permissions, where keys are permission names and values are booleans.                 |
| `role`            | `string` | The client's role, which can be `operator` (for control clients) or `node` (for companion devices).     |
| `scopes`          | `array`  | An array of strings defining the client's access scopes (for `operator` roles).                         |
| `auth`            | `object` | An object containing authentication credentials, such as a `token` or `password`.                         |
| `device`          | `object` | An object containing the client's device identity, used for pairing and authentication (see below).     |

**Client Information (`client` object)**

| Parameter         | Type     | Description                                                                                             |
| :---------------- | :------- | :------------------------------------------------------------------------------------------------------ |
| `id`              | `string` | A unique identifier for the client application (e.g., `cli`, `moltbot-ios`).                                |
| `displayName`     | `string` | A human-readable name for the client instance.                                                          |
| `version`         | `string` | The version of the client application.                                                                  |
| `platform`        | `string` | The operating system of the client (e.g., `macos`, `ios`).                                                |
| `mode`            | `string` | The client's operational mode (e.g., `ui`, `backend`, `node`).                                          |
| `instanceId`      | `string` | A unique identifier for this specific client instance, used for presence tracking.                      |

**Device Identity (`device` object)**

| Parameter   | Type     | Description                                                                                             |
| :---------- | :------- | :------------------------------------------------------------------------------------------------------ |
| `id`        | `string` | A unique fingerprint of the device's keypair.                                                           |
| `publicKey` | `string` | The public key of the device, used for signature verification.                                          |
| `signature` | `string` | A signature of the `connect.challenge` nonce, used to prove ownership of the private key.             |
| `signedAt`  | `number` | The timestamp at which the signature was generated.                                                     |
| `nonce`     | `string` | The nonce received from the server in the `connect.challenge` event.                                    |

### 3.2. Server Response (`hello-ok`)

Upon a successful connection and authentication, the Gateway responds with a `hello-ok` message in the `payload` of a `res` frame. This message confirms the connection and provides the client with essential server-side information.

**`hello-ok` Payload**

| Parameter  | Type     | Description                                                                                             |
| :--------- | :------- | :------------------------------------------------------------------------------------------------------ |
| `type`     | `string` | Always `hello-ok`.                                                                                      |
| `protocol` | `number` | The protocol version negotiated between the client and server.                                          |
| `server`   | `object` | An object containing information about the server, including its version and a unique connection ID.      |
| `features` | `object` | An object listing the RPC methods and events supported by the server.                                     |
| `snapshot` | `object` | An initial snapshot of the system state, including presence and health information.                     |
| `auth`     | `object` | An object containing a `deviceToken` if one was issued to the client.                                   |
| `policy`   | `object` | An object defining server policies, such as the `tickIntervalMs` for keepalive messages.                 |

### 3.3. Device Authentication Challenge (`connect.challenge`)

For non-local connections, the Gateway will send a `connect.challenge` event immediately after the WebSocket connection is established, before the client sends its `connect` request. This event contains a cryptographic nonce that the client must sign with its device's private key and include in the `device.signature` field of the `connect` request. This mechanism ensures that the client is in possession of the private key corresponding to its claimed device identity.

**`connect.challenge` Event Payload**

```json
{
  "nonce": "<cryptographic_nonce>",
  "ts": 1737264000000
}
```

## 4. RPC Methods

The Moltbot WebSocket protocol exposes a rich set of RPC methods that allow clients to interact with the Gateway and the broader Moltbot ecosystem. All RPC calls are made using the `req` frame format, specifying the method name and its parameters. The server responds with a `res` frame containing the result of the operation.

### 4.1. Core Methods

These methods provide fundamental functionalities for interacting with the Gateway.

| Method                  | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `health`                | Retrieves a comprehensive health snapshot of the Gateway.                                               |
| `status`                | Retrieves a brief summary of the Gateway's status.                                                      |
| `system-presence`       | Retrieves the current list of connected clients and nodes.                                              |
| `system-event`          | Posts a system-level event or note.                                                                     |
| `send`                  | Sends a message through one of the active messaging channels.                                           |
| `agent`                 | Initiates an agent turn, which can involve processing a message, executing tools, and generating a response. |
| `agent.identity.get`    | Retrieves the identity of a specific agent.                                                             |
| `agent.wait`            | Waits for a specific agent run to complete.                                                             |

### 4.2. Node and Device Management

These methods are used to manage companion nodes and paired devices.

| Method                  | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `node.pair.request`     | Initiates a pairing request for a new node.                                                             |
| `node.pair.list`        | Lists all pending node pairing requests.                                                                |
| `node.pair.approve`     | Approves a pending node pairing request.                                                                |
| `node.pair.reject`      | Rejects a pending node pairing request.                                                                 |
| `node.pair.verify`      | Verifies the pairing status of a node.                                                                  |
| `node.list`             | Lists all currently connected and paired nodes.                                                         |
| `node.describe`         | Retrieves detailed information about a specific node, including its capabilities and supported commands.    |
| `node.invoke`           | Invokes a command on a specific node (e.g., `camera.snap`, `canvas.navigate`).                            |
| `node.invoke.result`    | Used by a node to send the result of a command invocation back to the Gateway.                          |
| `node.event`            | Used by a node to send an asynchronous event to the Gateway.                                            |
| `device.pair.list`      | Lists all pending device pairing requests.                                                              |
| `device.pair.approve`   | Approves a pending device pairing request.                                                              |
| `device.pair.reject`    | Rejects a pending device pairing request.                                                               |
| `device.token.rotate`   | Rotates the authentication token for a paired device.                                                   |
| `device.token.revoke`   | Revokes the authentication token for a paired device.                                                   |

### 4.3. Configuration and Session Management

These methods are used to manage the Gateway's configuration and user sessions.

| Method                  | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `config.get`            | Retrieves the current Gateway configuration.                                                            |
| `config.set`            | Sets the Gateway configuration.                                                                         |
| `config.apply`          | Applies a new configuration to the Gateway.                                                             |
| `config.patch`          | Applies a partial update to the Gateway configuration.                                                  |
| `config.schema`         | Retrieves the JSON schema for the Gateway configuration.                                                |
| `sessions.list`         | Lists all active user sessions.                                                                         |
| `sessions.preview`      | Retrieves a preview of a specific session's transcript.                                                 |
| `sessions.patch`        | Applies a partial update to a specific session.                                                         |
| `sessions.reset`        | Resets a specific session.                                                                              |
| `sessions.delete`       | Deletes a specific session.                                                                             |
| `sessions.compact`      | Compacts the transcript of a specific session.                                                          |

### 4.4. Chat and Logging

These methods are used for real-time chat and log retrieval.

| Method                  | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `chat.history`          | Retrieves the chat history for a specific session.                                                      |
| `chat.send`             | Sends a message within a specific chat session.                                                         |
| `chat.abort`            | Aborts an ongoing agent run within a specific chat session.                                             |
| `logs.tail`             | Tails the Gateway's log file, streaming new log entries to the client.                                  |

### 4.5. Scheduled Tasks (Cron)

These methods are used to manage scheduled tasks.

| Method                  | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `cron.list`             | Lists all scheduled cron jobs.                                                                          |
| `cron.status`           | Retrieves the status of the cron service.                                                               |
| `cron.add`              | Adds a new cron job.                                                                                    |
| `cron.update`           | Updates an existing cron job.                                                                           |
| `cron.remove`           | Removes a cron job.                                                                                     |
| `cron.run`              | Manually triggers a cron job to run.                                                                    |
| `cron.runs`             | Retrieves the run history for a specific cron job.                                                      |

## 5. Asynchronous Events

The Moltbot WebSocket protocol uses asynchronous events to push real-time updates and notifications from the Gateway to connected clients. These events are sent using the `event` frame format.

| Event                   | Description                                                                                             |
| :---------------------- | :------------------------------------------------------------------------------------------------------ |
| `connect.challenge`     | Sent to a client immediately after connection to provide a cryptographic nonce for device authentication. |
| `agent`                 | Streams events from an agent run, including tool calls, intermediate outputs, and the final response.     |
| `chat`                  | Streams events related to a specific chat session, such as new messages and agent state changes.        |
| `presence`              | Notifies clients of changes in the presence status of other clients and nodes.                          |
| `tick`                  | A periodic keepalive message to confirm the liveness of the connection.                                 |
| `talk.mode`             | Notifies clients of changes in the talk mode (e.g., voice input).                                       |
| `shutdown`              | Informs clients that the Gateway is shutting down.                                                      |
| `health`                | Pushes updates to the Gateway's health status.                                                          |
| `heartbeat`             | A periodic heartbeat event.                                                                             |
| `cron`                  | Notifies clients of events related to scheduled tasks.                                                  |
| `node.pair.requested`   | Informs operator clients that a new node has requested to be paired.                                    |
| `node.pair.resolved`    | Informs clients that a node pairing request has been resolved (approved or rejected).                   |
| `node.invoke.request`   | Sent to a node to request the invocation of a command.                                                  |
| `device.pair.requested` | Informs operator clients that a new device has requested to be paired.                                  |
| `device.pair.resolved`  | Informs clients that a device pairing request has been resolved (approved or rejected).                 |
| `voicewake.changed`     | Notifies clients of changes in the voice wake-word detection state.                                     |
| `exec.approval.requested` | Informs operator clients that a command execution requires approval.                                    |
| `exec.approval.resolved`  | Informs clients that a command execution approval request has been resolved.                            |

## 6. Node-Specific Communication

Companion nodes, such as the iOS and Android apps, have a special role in the Moltbot ecosystem. They connect to the Gateway with the `node` role and expose a set of capabilities and commands that can be invoked by the Gateway. This enables the agent to perform actions in the physical world, such as taking pictures, recording audio, and accessing sensor data.

### 6.1. Node Capabilities and Commands

Nodes declare their capabilities and the commands they support in the `caps` and `commands` fields of the `connect` request. The Gateway uses this information to determine which commands can be invoked on a given node.

### 6.2. Command Invocation (`node.invoke`)

The Gateway invokes commands on a node by sending a `node.invoke` request. The `params` of this request specify the `nodeId` of the target node, the `command` to be executed, and any parameters required by the command.

### 6.3. Command Results (`node.invoke.result`)

After executing a command, the node sends the result back to the Gateway using the `node.invoke.result` method. This allows the agent to process the output of the command and continue its execution.

### 6.4. Asynchronous Node Events (`node.event`)

Nodes can also send asynchronous events to the Gateway using the `node.event` method. This is useful for notifying the Gateway of events that occur on the device, such as a change in location or a sensor reading.

## 7. Roles and Scopes

The Moltbot protocol uses a role-based access control system to manage client permissions. Clients declare their role and requested scopes during the `connect` handshake, and the Gateway enforces these permissions for all subsequent operations.

### 7.1. Roles

There are two primary roles in the Moltbot ecosystem:

| Role       | Description                                                                                             |
| :--------- | :------------------------------------------------------------------------------------------------------ |
| `operator` | Control plane clients, such as the CLI, web UI, and automation scripts. Operators can manage the Gateway, sessions, and nodes. |
| `node`     | Capability hosts, such as companion apps on iOS, Android, and macOS. Nodes expose commands like `camera.snap`, `screen.record`, and `system.run`. |

### 7.2. Scopes (for Operators)

Operator clients request specific scopes to define their access level. Common scopes include:

| Scope               | Description                                                                                             |
| :------------------ | :------------------------------------------------------------------------------------------------------ |
| `operator.read`     | Allows reading status, health, and session information.                                                 |
| `operator.write`    | Allows sending messages and invoking agent turns.                                                       |
| `operator.admin`    | Allows modifying Gateway configuration and managing sessions.                                           |
| `operator.approvals`| Allows resolving exec approval requests.                                                                |
| `operator.pairing`  | Allows approving or rejecting device and node pairing requests.                                         |

### 7.3. Capabilities, Commands, and Permissions (for Nodes)

Nodes declare their capabilities at connect time using three fields:

| Field         | Description                                                                                             |
| :------------ | :------------------------------------------------------------------------------------------------------ |
| `caps`        | High-level capability categories (e.g., `camera`, `canvas`, `screen`, `location`, `voice`).             |
| `commands`    | A specific allowlist of commands the node can execute (e.g., `camera.snap`, `canvas.navigate`).         |
| `permissions` | Granular toggles for specific actions (e.g., `screen.record: true`, `camera.capture: false`).           |

The Gateway treats these as claims and enforces server-side allowlists to ensure security.

## 8. Error Handling

When an RPC request fails, the Gateway returns a `res` frame with `ok: false` and an `error` object in the payload. The error object follows a structured format that provides detailed information about the failure.

### 8.1. Error Shape

| Field         | Type      | Description                                                                                             |
| :------------ | :-------- | :------------------------------------------------------------------------------------------------------ |
| `code`        | `string`  | A machine-readable error code.                                                                          |
| `message`     | `string`  | A human-readable description of the error.                                                              |
| `details`     | `unknown` | Optional additional details about the error.                                                            |
| `retryable`   | `boolean` | Indicates whether the client should retry the request.                                                  |
| `retryAfterMs`| `number`  | If `retryable` is true, this field suggests a delay in milliseconds before retrying.                    |

### 8.2. Standard Error Codes

| Code              | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `NOT_LINKED`      | The messaging channel (e.g., WhatsApp) is not authenticated.                                            |
| `NOT_PAIRED`      | The node or device is not paired with the Gateway.                                                      |
| `AGENT_TIMEOUT`   | The agent did not respond within the configured deadline.                                               |
| `INVALID_REQUEST` | The request failed schema or parameter validation.                                                      |
| `UNAVAILABLE`     | The Gateway is shutting down or a required dependency is unavailable.                                   |

## 9. Detailed Node Commands

Companion nodes expose a variety of commands that can be invoked by the Gateway using the `node.invoke` method. These commands enable the agent to interact with the physical world through the node's sensors and capabilities.

### 9.1. Canvas Commands

These commands control the WebView canvas on the node.

| Command           | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `canvas.present`  | Presents the canvas WebView with a specified URL or local file path.                                    |
| `canvas.hide`     | Hides the canvas WebView.                                                                               |
| `canvas.navigate` | Navigates the canvas WebView to a new URL.                                                              |
| `canvas.eval`     | Evaluates JavaScript code within the canvas WebView.                                                    |
| `canvas.snapshot` | Captures a screenshot of the canvas WebView.                                                            |

### 9.2. Camera Commands

These commands control the node's camera.

| Command           | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `camera.list`     | Lists the available cameras on the node.                                                                |
| `camera.snap`     | Captures a photo from the camera.                                                                       |
| `camera.clip`     | Records a video clip from the camera.                                                                   |

### 9.3. Screen Commands

These commands control screen recording on the node.

| Command           | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `screen.record`   | Records the node's screen.                                                                              |

### 9.4. Location Commands

These commands access the node's location services.

| Command           | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `location.get`    | Retrieves the node's current location (latitude, longitude, accuracy).                                  |

### 9.5. System Commands (Node Host / macOS Node)

These commands execute system-level operations on the node.

| Command                   | Description                                                                                             |
| :------------------------ | :------------------------------------------------------------------------------------------------------ |
| `system.run`              | Executes a shell command on the node.                                                                   |
| `system.which`            | Finds the path to an executable on the node.                                                            |
| `system.notify`           | Sends a system notification on the node.                                                                |
| `system.execApprovals.get`| Retrieves the exec approvals configuration for the node.                                                |
| `system.execApprovals.set`| Sets the exec approvals configuration for the node.                                                     |

### 9.6. SMS Commands (Android Only)

These commands send SMS messages from Android nodes.

| Command           | Description                                                                                             |
| :---------------- | :------------------------------------------------------------------------------------------------------ |
| `sms.send`        | Sends an SMS message to a specified phone number.                                                       |

## 10. Protocol Versioning

The Moltbot protocol uses a versioning system to ensure compatibility between clients and the Gateway. The current protocol version is **3** [3].

Clients declare their supported protocol version range using the `minProtocol` and `maxProtocol` fields in the `connect` request. The Gateway will reject connections if the client's version range does not overlap with the server's supported version.

Protocol schemas and models are generated from TypeBox definitions in the source code. The following commands can be used to regenerate them:

- `pnpm protocol:gen` - Generates TypeScript schemas.
- `pnpm protocol:gen:swift` - Generates Swift models.
- `pnpm protocol:check` - Validates the protocol schemas.

## 11. Conclusion

The Moltbot WebSocket protocol is a well-designed and comprehensive communication layer that enables seamless interaction between the Gateway, control clients, and companion nodes. Its clear framing structure, robust handshake and authentication mechanism, and rich set of RPC methods and events provide a solid foundation for the entire Moltbot ecosystem.

## References

[1] Moltbot GitHub Repository. [https://github.com/moltbot/moltbot](https://github.com/moltbot/moltbot)
[2] `frames.ts` - Moltbot Source Code. `/src/gateway/protocol/schema/frames.ts`
[3] `protocol-schemas.ts` - Moltbot Source Code. `/src/gateway/protocol/schema/protocol-schemas.ts`

## Appendix A: Example Message Flows

This appendix provides complete example message flows for common operations in the Moltbot WebSocket protocol.

### A.1. Operator Connection Handshake

**Step 1: Client connects to WebSocket**

The client establishes a WebSocket connection to `ws://127.0.0.1:18789`.

**Step 2: Server sends challenge (for non-local connections)**

```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": {
    "nonce": "a1b2c3d4e5f6g7h8",
    "ts": 1737264000000
  }
}
```

**Step 3: Client sends connect request**

```json
{
  "type": "req",
  "id": "req-001",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "cli",
      "version": "1.2.3",
      "platform": "macos",
      "mode": "cli"
    },
    "role": "operator",
    "scopes": ["operator.read", "operator.write", "operator.admin"],
    "caps": [],
    "commands": [],
    "permissions": {},
    "auth": {
      "token": "your-gateway-token"
    },
    "device": {
      "id": "device_fingerprint_abc123",
      "publicKey": "base64url_encoded_public_key",
      "signature": "base64url_encoded_signature",
      "signedAt": 1737264000000,
      "nonce": "a1b2c3d4e5f6g7h8"
    }
  }
}
```

**Step 4: Server responds with hello-ok**

```json
{
  "type": "res",
  "id": "req-001",
  "ok": true,
  "payload": {
    "type": "hello-ok",
    "protocol": 3,
    "server": {
      "version": "1.2.3",
      "commit": "abc123",
      "host": "my-gateway",
      "connId": "conn-12345"
    },
    "features": {
      "methods": ["health", "status", "send", "agent", "node.list", "..."],
      "events": ["agent", "presence", "tick", "shutdown", "..."]
    },
    "snapshot": {
      "presence": [],
      "health": {},
      "stateVersion": { "presence": 1, "health": 1 },
      "uptimeMs": 123456
    },
    "auth": {
      "deviceToken": "issued_device_token",
      "role": "operator",
      "scopes": ["operator.read", "operator.write", "operator.admin"]
    },
    "policy": {
      "maxPayload": 26214400,
      "maxBufferedBytes": 52428800,
      "tickIntervalMs": 15000
    }
  }
}
```

### A.2. Node Connection and Command Invocation

**Step 1: Node connects and sends connect request**

```json
{
  "type": "req",
  "id": "node-req-001",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "moltbot-ios",
      "displayName": "Deano's iPhone",
      "version": "1.2.3",
      "platform": "ios",
      "mode": "node"
    },
    "role": "node",
    "scopes": [],
    "caps": ["camera", "canvas", "screen", "location"],
    "commands": ["camera.snap", "camera.clip", "canvas.navigate", "canvas.snapshot", "screen.record", "location.get"],
    "permissions": {
      "camera.capture": true,
      "screen.record": true,
      "location.access": true
    },
    "auth": {
      "token": "node-auth-token"
    },
    "device": {
      "id": "ios_device_fingerprint",
      "publicKey": "base64url_encoded_public_key",
      "signature": "base64url_encoded_signature",
      "signedAt": 1737264000000,
      "nonce": "server_provided_nonce"
    }
  }
}
```

**Step 2: Gateway sends invoke request to node**

```json
{
  "type": "event",
  "event": "node.invoke.request",
  "payload": {
    "id": "invoke-001",
    "nodeId": "ios_device_fingerprint",
    "command": "camera.snap",
    "paramsJSON": "{\"facing\":\"back\",\"quality\":0.9}",
    "timeoutMs": 30000,
    "idempotencyKey": "idem-key-001"
  }
}
```

**Step 3: Node sends invoke result back to Gateway**

```json
{
  "type": "req",
  "id": "node-req-002",
  "method": "node.invoke.result",
  "params": {
    "id": "invoke-001",
    "nodeId": "ios_device_fingerprint",
    "ok": true,
    "payloadJSON": "{\"format\":\"jpg\",\"base64\":\"...base64_encoded_image_data...\"}"
  }
}
```

### A.3. Agent Turn with Streaming Response

**Step 1: Client sends agent request**

```json
{
  "type": "req",
  "id": "agent-req-001",
  "method": "agent",
  "params": {
    "message": "What's the weather like today?",
    "sessionKey": "session-main",
    "idempotencyKey": "agent-idem-001"
  }
}
```

**Step 2: Server sends acknowledgment**

```json
{
  "type": "res",
  "id": "agent-req-001",
  "ok": true,
  "payload": {
    "runId": "run-12345",
    "status": "accepted"
  }
}
```

**Step 3: Server streams agent events**

```json
{
  "type": "event",
  "event": "agent",
  "payload": {
    "runId": "run-12345",
    "seq": 0,
    "stream": "output",
    "ts": 1737264001000,
    "data": { "delta": "The weather today is " }
  },
  "seq": 100
}
```

```json
{
  "type": "event",
  "event": "agent",
  "payload": {
    "runId": "run-12345",
    "seq": 1,
    "stream": "output",
    "ts": 1737264002000,
    "data": { "delta": "sunny with a high of 22°C." }
  },
  "seq": 101
}
```

**Step 4: Server sends final response**

```json
{
  "type": "res",
  "id": "agent-req-001",
  "ok": true,
  "payload": {
    "runId": "run-12345",
    "status": "ok",
    "summary": "The weather today is sunny with a high of 22°C."
  }
}
```

## Appendix B: Client Identifiers and Modes

The following tables list the predefined client identifiers and operational modes used in the Moltbot protocol.

### B.1. Client Identifiers

| Identifier         | Description                                                |
| :----------------- | :--------------------------------------------------------- |
| `webchat-ui`       | The web-based chat user interface.                         |
| `moltbot-control-ui` | The web-based control panel user interface.              |
| `webchat`          | A generic webchat client.                                  |
| `cli`              | The command-line interface.                                |
| `gateway-client`   | A generic gateway client.                                  |
| `moltbot-macos`    | The macOS companion application.                           |
| `moltbot-ios`      | The iOS companion application.                             |
| `moltbot-android`  | The Android companion application.                         |
| `node-host`        | A headless node host.                                      |
| `test`             | A test client.                                             |
| `moltbot-probe`    | A probe client for health checks.                          |

### B.2. Client Modes

| Mode       | Description                                                |
| :--------- | :--------------------------------------------------------- |
| `webchat`  | A webchat client mode.                                     |
| `cli`      | A command-line interface mode.                             |
| `ui`       | A user interface mode.                                     |
| `backend`  | A backend service mode.                                    |
| `node`     | A companion node mode.                                     |
| `probe`    | A probe mode for health checks.                            |
| `test`     | A test mode.                                               |
