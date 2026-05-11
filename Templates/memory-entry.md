<%*
// Claude記憶エントリを作成するTemplater テンプレート。
// 「Templater: Create new note from template」(⌘⇧M) から呼び出す。
// プロンプトで入力 → memory/ に正しい名前で配置 → MEMORY.md に1行追加。

const types = ["user", "feedback", "project", "reference"];
const type = await tp.system.suggester(types, types, false, "記憶タイプを選択");
if (!type) { return; }

const slug = await tp.system.prompt("ファイル名スラッグ (例: project_xxx, user_yyy)");
if (!slug) { return; }

const title = await tp.system.prompt("人間用タイトル (MEMORY.md表示用)", slug);
if (!title) { return; }

const desc = await tp.system.prompt("一行説明 (MEMORY.mdインデックスに載る)");
if (!desc) { return; }

const memDir = "00 Claude Instructions/memory";
const target = `${memDir}/${slug}`;

const existing = app.vault.getAbstractFileByPath(`${target}.md`);
if (existing) {
  new Notice(`既に存在: ${target}.md (上書きしません)`);
  return;
}

await tp.file.rename(slug);
await tp.file.move(target);

const memPath = `${memDir}/MEMORY.md`;
const memFile = app.vault.getAbstractFileByPath(memPath);
if (memFile) {
  const content = await app.vault.read(memFile);
  const newLine = `- [${title}](${slug}.md) — ${desc}`;
  const newContent = content.replace(/\n+$/, "") + "\n" + newLine + "\n";
  await app.vault.modify(memFile, newContent);
  new Notice(`MEMORY.md に追加: ${title}`);
} else {
  new Notice(`MEMORY.md が見つからない: ${memPath}`);
}

tR += `---\nname: ${title}\ndescription: ${desc}\ntype: ${type}\n---\n\n`;
_%>
