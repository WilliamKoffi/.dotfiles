---
id: LRV-003
title: "Aggregate children are nested under their owner"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-003 — Aggregate children are nested under their owner

## Decision

A model that belongs to an aggregate sits in a namespace under its owner and uses one
noun: `Order\Item`, `Order\Adjustment`, `Cart\Item`. It declares its table explicitly
(`#[Table('order_items')]`).

## Why

`OrderItem` inside `Orders\Models` repeats the aggregate's name. The namespace already
says who owns the child, and the explicit table keeps the database names unchanged.

## Consequences

- A class name that repeats its parent's name (`Order\OrderItem`) is a finding.
- Two short names that collide in one file are aliased at the import.
