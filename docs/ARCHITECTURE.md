# ARCHITECTURE.md

## 概要

Kick×Kick MVPのアーキテクチャ方針を定義する。

本アプリは、Flutterによるローカルファーストなスニーカーコレクションアプリである。

---

# 基本方針

Kick×Kickは以下を優先する。

```text
シンプル
安定
拡張可能
オフラインファースト
```

---

# Architecture Overview

```text
Presentation
↓
Provider
↓
Repository
↓
Database
```

---

# Layer

## Presentation

画面とUIを担当する。

対象

```text
Home
Collection
Shoe Detail
Shoe Form
Settings
```

---

## Provider

Riverpodによる状態管理を担当する。

責務

```text
データ取得
非同期状態管理
UIへの状態提供
```

---

## Repository

データ操作の窓口。

責務

```text
CRUD
検索
統計取得
```

---

## Database

SQLite / Drift によるローカル保存。

責務

```text
スニーカーデータ保存
画像パス保存
登録日時管理
```

---

# Data Flow

## Read

```text
Screen
↓
Provider
↓
Repository
↓
Database
↓
Repository
↓
Provider
↓
Screen
```

---

## Write

```text
Form Screen
↓
Repository
↓
Database
↓
Provider invalidate
↓
Screen update
```

---

# State Management

使用

```text
Riverpod
```

方針

```text
AsyncValueを使用する
Providerを増やしすぎない
画面単位で状態を管理する
```

---

# Database

使用

```text
SQLite
Drift
```

MVPでは

```text
shoes
```

テーブルを中心に実装する。

---

# Offline First

Kick×Kickのデータはユーザーの端末内に保存する。

MVPでは以下を使用しない。

```text
Firebase
Cloud Sync
Authentication
```

---

# Routing

ルーティングはシンプルに保つ。

```text
/
 /collection
 /shoe/new
 /shoe/:id
 /shoe/:id/edit
 /settings
```

---

# Error Handling

Repositoryで例外を扱い、UIでは分かりやすいメッセージを表示する。

表示例

```text
データの取得に失敗しました
```

---

# Forbidden

MVPでは以下を禁止する。

```text
ログイン
クラウド同期
AI鑑定
相場取得
SNS共有
売買機能
```

---

# Design Principle

Kick×Kickは

```text
ただのスニーカー管理アプリ
```

ではない。

```text
スニーカーを登録し、ステッカー化し、棚やボードに飾って楽しむ
スニーカーコレクションアプリ
```

である。

アーキテクチャもこの思想を壊さないように、
機能追加より安定性と所有感を優先する。
