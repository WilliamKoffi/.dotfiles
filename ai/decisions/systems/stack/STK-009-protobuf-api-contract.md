---
id: STK-009
title: "The API contract is written in `.proto`; the client picks JSON or binary by `Accept`"
system: stack
status: locked
date: 2026-10-07
conflicts: []
requires: [LNG-002]
supersedes: null
---
# STK-009 — The API contract is written in `.proto`; the client picks JSON or binary by `Accept`

## Decision

The `.proto` files are the single contract of the API. Every type that crosses it, on the server
and in each client, is generated from them (`buf generate`); none is written by hand.

Every endpoint serves both encodings, chosen by the client's `Accept` header:

```
GET /products   Accept: application/x-protobuf   → binary
GET /products   Accept: application/json         → JSON
GET /products   (no Accept)                      → JSON
```

JSON keys are the proto field names, never protobuf's default camelCase. The server keeps no list
of "binary endpoints"; a client asks for binary where the payload is large or the network weak
(offline sync, long lists, reports), and JSON elsewhere.

## Why

Types written by hand in several languages drift apart; one contract generated everywhere cannot.
Two encodings on every endpoint let a client trade readability for size per call, without a
second API.

## Consequences

- The keep-field-names option is turned on in every generator and runtime, so keys stay
  snake_case (LNG-002).
- A 64-bit integer is a string in the JSON form; clients read it as such.
- A change to the API is a change to a `.proto` file first.
