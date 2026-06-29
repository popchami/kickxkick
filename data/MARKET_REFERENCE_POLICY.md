# Kick×Kick Market Reference Policy

## Purpose

Kick×Kickのモデルデータは、日本ユーザーが実際に探すモデルを登録できることを重視する。

国内大手販売サイトを、完成形に近い国内流通リファレンスとして扱い、Kick×Kickのデータベースを継続的に育成する。

---

## Core Rule

国内大手販売サイトに掲載されているブランド・モデルは、Kick×Kickの登録候補にする。

新作モデルが増えた場合は、Kick×Kickでも追加候補として扱う。

---

## Brand-First Rule

モデルを一気にすべて埋める前に、まずブランド名を国内流通リファレンスに近づける。

```text
1. ブランド名を先に広く登録する
2. ブランドは Tier C / brand-only として追加してよい
3. モデル・Alias・searchKeywordsは、ブランドごとに少しずつ追加する
4. 代表モデルだけで止めず、最終的には国内流通リファレンスの掲載量に近づける
```

---

## Coverage Goal

Kick×Kickの目標は、代表モデルだけを少数登録することではない。

国内大手販売サイトに掲載されているブランド・モデル量に近づけることを目標にする。

```text
代表モデルだけで止めない。
国内流通リファレンスとの差分を見て、未登録モデルを継続的に追加する。
新作が10件増えたら、Kick×Kickでも10件を追加候補にする。
```

---

## Update Flow

```text
1. 国内流通リファレンスでブランド候補を確認
2. 既存 brands.json と比較
3. 未登録ブランドを brands.json に先行追加
4. app/assets/data/brands.json に同期
5. ブランドごとにモデル候補を確認
6. 公式サイトまたは信頼できる公式情報で正式名称を確認
7. models.json / aliases.json / search_keywords.json を段階追加
8. app/assets/data/*.json に同期
9. data/CHANGELOG.md に監査ログを残す
10. specs/MODEL_MASTER_COVERAGE.md / specs/KICKXKICK_TASK_BOARD.md を更新
```

---

## Tier Policy

```text
Tier S: MVP PASS後も差分監査を継続
Tier A: MVP PASS後も差分監査を継続
Tier B: 国内流通ブランドを中心にモデル拡張
Tier C: ブランド名を先行登録し、モデルは段階追加
```

---

## Quality Gate

以下は追加しない。

```text
- 色名だけ
- コラボ名だけ
- 商品説明文
- 商品画像
- 在庫情報
- 公式表記が確認できない低確度モデル
- 広すぎるAlias/searchKeywords
```

---

## Final Principle

Kick×Kickのデータ資産は、一度作って終わりではない。

まずブランド名を国内流通リファレンスに近づける。

その後、各ブランドのモデル・Alias・searchKeywordsを継続的に追加し、データ量を国内流通リファレンスに近づけていく。
