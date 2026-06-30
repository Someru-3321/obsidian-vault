---
name: reference-obsidian-vault
description: メインのObsidian Vaultの場所とClaude CodeからのMCP接続経路
metadata: 
  node_type: memory
  type: reference
  originSessionId: 94c2e7d2-ba07-4d6d-a7ac-8585fdfeb4be
---

メインObsidian Vault: `~/Library/CloudStorage/GoogleDrive-yuki.watabe@someru.me/マイドライブ/Obsidian Vault/`（Google Drive同期）

Claude CodeからはMCP経由でアクセス可能。`~/.claude.json` の `mcpServers.obsidian` に `http://127.0.0.1:27123/mcp` で登録済み。バックエンドは Obsidian プラグイン「Local REST API & MCP Server」v4.0.2（HTTP/HTTPSサーバーをObsidianが起動中のみ動作）。

**前提**: Obsidianアプリが起動していて、当該Vaultが開かれていること。閉じているとMCP接続不可。

**セキュリティ注意**: APIキー・TLS秘密鍵が `<vault>/.obsidian/plugins/obsidian-local-rest-api/data.json` に保存され、Google Driveに同期される。loopback専用なので外部攻撃面は無いが、Googleアカウント漏洩時のリスクとして認識。
