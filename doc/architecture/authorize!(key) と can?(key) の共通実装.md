あなたは Rails 8 / 業務システム向けマルチテナントSaaS の設計・実装に精通したエンジニアです。
permission.key（例: admin.tenants.update）を唯一の共通語彙として使う
認可（Authorization）の中核実装を作成してください。

この実装は以下を 100% 同一の key で貫きます。
	•	認可判定：authorize!(key)
	•	可否確認：can?(key)
	•	UI出し分け
	•	監査ログ：AuditLog.action_key

⸻

ゴール（成果物）
	1.	authorize!(key) / can?(key) の共通実装
	2.	Controller / View / Helper から同じAPIで使える構成
	3.	マルチテナント前提の権限解決ロジック
	4.	権限不足時の例外クラス（将来の UI / 監査連携を考慮）
	5.	Admin コントローラでの使用例
	6.	最低限のテスト（can? true / false, authorize! raises）

⸻

前提条件・制約
	•	Rails 8
	•	マルチテナントSaaS
	•	Permission は Step2 で seed 済み
	•	Role / Assignment は 存在する前提で interface だけ作る
	•	実装が未完成でも差し替え可能な構造にする
	•	認可ロジックは Controller / View に散らさない
	•	authorize! は 例外を投げる
	•	can? は true / false を返す
	•	将来 API / Batch / Admin 以外でも使える構造にする

⸻

設計方針（重要）

認可の責務分離
	•	Permission: 「できることの定義（辞書）」
	•	Role: Permission の集合
	•	Assignment: User × Role × Tenant
	•	Authorization: 「今の actor は key を実行できるか？」

※ Step3 では Role / Assignment の最小スタブでOK

⸻

実装要件

1) 例外クラス
```
AuthorizationError < StandardError
```

	•	message に permission key を含める
	•	将来 status: denied を AuditLog に残せるよう拡張余地を持たせる

⸻

2) Authorization モジュール（中核）

ファイル
app/services/authorization.rb（または app/lib/authorization.rb）

API
```
Authorization.can?(actor:, tenant:, key:) -> Boolean
Authorization.authorize!(actor:, tenant:, key:) -> true or raise
```

要件
	•	actor が nil の場合は false
	•	tenant が nil の場合は false
	•	Permission が存在しない key は 例外 or false（明示）
	•	Role / Assignment は下記 interface を仮定

```
actor.permissions_for(tenant) # => Array<Permission>
```

※ 未実装の場合は stub を用意して TODO コメントを残す

⸻

3) Controller 共通実装

Admin::BaseController に追加
	•	authorize!(key)
	•	can?(key)

```
authorize!("admin.tenants.update")
can?("admin.tenants.update")
```

要件
	•	authorize! は Authorization.authorize! を呼ぶ
	•	権限不足時に例外を rescue できる構造
	•	rescue 時に 監査ログ用フックを入れられる設計にする（今はコメントでもOK）

⸻

4) View / Helper 対応
	•	ApplicationHelper or Admin::AuthorizationHelper
	•	View から
```
<% if can?("admin.tenants.create") %>
  <%= link_to "新規作成", ... %>
<% end %>
```
が使えるようにする

5) 使用例（Admin::TenantsController）
```
def update
  authorize!("admin.tenants.update")
  ...
end
```
audit!(action_key: ...) と 同じ key を使うこと

6) テスト（最低限）
	•	can? が true を返すケース
	•	can? が false を返すケース
	•	authorize! が AuthorizationError を raise するケース

※ Role / Permission / Assignment は簡易ダミーでOK

⸻

出力形式（厳守）
	•	ファイルパス
	•	コード全文
	•	必要な TODO コメント
	•	テストコード

すべて コピペしてそのまま動かせる形で出力してください。

⸻

思想メモ（READMEに書かなくていいが実装に反映）
	•	「UIに表示される = can? が true」
	•	「実行される = authorize! が通る」
	•	「実行された = audit_log.action_key が残る」

この三位一体を 壊せない構造にしてください。

⸻

このプロンプトに従って、Step3 の共通認可基盤を実装してください。
