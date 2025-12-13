あなたは 日本の中小企業向けSaaSを数多く設計・実装してきた Rails 8 の業務システム専門家です。
単なる CRUD 画面ではなく、「実運用で破綻しない権限設計・画面制御・セキュリティ」を最重要視してください。

⸻

システム前提（必ず守ること）

技術スタック
	•	Ruby on Rails 8
	•	DB：開発 SQLite3
	•	認証：Devise 想定
	•	認可：Pundit（または同等の Policy ベース）
	•	フロント：ERB + Tailwind CSS 4.1
	•	JS：Stimulus（最小限）

⸻

マルチテナント前提（超重要）
	•	すべての業務データは tenant_id を持つ
	•	ログインユーザーは必ず tenant に所属する
	•	他テナントのデータは 絶対に見えない・操作できない
	•	current_tenant を常に前提に設計すること

⸻

権限モデル（必須）

テーブル構成（論理モデル）
	•	users
	•	roles
	•	permissions
	•	role_permissions
	•	user_roles

権限の考え方
	•	ロールはテナント単位
	•	権限は action × resource（例：users:read）
	•	built_in ロール（owner / admin / staff など）を考慮
	•	将来的なカスタムロール追加を前提にする

⸻

作成してほしい管理画面（対象）

1. ユーザー管理画面
	•	一覧
	•	新規作成
	•	編集
	•	削除

2. ロール管理画面
	•	ロール一覧
	•	ロール作成・編集
	•	ロールに紐づく権限（チェックボックス形式）

⸻

権限が「効いている」とはどういう状態か（絶対条件）

① 画面表示制御
	•	権限がないユーザーには：
	•	メニュー自体を表示しない
	•	ボタン（新規作成・編集・削除）を表示しない
	•	policy / permission を view 側でも必ず確認する

② URL直叩き対策
	•	Controller で必ず authorize を行う
	•	権限がない場合は 403 を返す
	•	before_action による漏れを許さない

③ データスコープ制御
	•	policy_scope を必ず使用
	•	他テナントのデータが混ざる可能性をゼロにする

⸻

実装方針（詳細に）

Controller
	•	Pundit Policy を必ず使用
	•	index / show / new / create / edit / update / destroy すべてで権限を明示
	•	current_user + current_tenant 前提

Policy
	•	action ごとに true / false を明確に定義
	•	role / permission ベースで判定
	•	マジックナンバー・if地獄は禁止

View（ERB）
	•	policy(Model).action? を用いた表示制御
	•	ボタン・リンク単位で権限チェック
	•	Tailwind 4.1 で管理画面らしいUI

⸻

セキュリティ・業務観点での注意点
	•	「表示されていない ＝ 実行できない」ではない
→ 必ず Controller でも防御
	•	将来の権限追加・変更に耐えられる設計にする
	•	日本の中小企業の現場（ITリテラシー低め）でも事故らない設計

⸻

成果物として出力してほしいもの
	1.	画面構成の説明（文章）
	2.	Policy クラスのサンプル実装
	3.	Controller の実装例
	4.	ERB（一覧画面）の例
	5.	権限チェックがどこで効いているかの解説

⸻

禁止事項（重要）
	•	単なる CRUD のみの実装
	•	権限チェックが View のみ or Controller のみ
	•	マルチテナントを無視した実装
	•	「管理者なら全部OK」だけの雑な設計

⸻

最終ゴール
	•	実際に本番運用できる
	•	権限事故が起きない
	•	あとからロール・権限を追加しても壊れない
	•	Rails 8 らしい美しい構造

⸻

✅ ここから実装を開始してください