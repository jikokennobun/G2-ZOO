# Claude Code 引き継ぎメモ

最終更新: 2026-05-20

## 目的

`G2-ZOO` を自己嫌悪文ホームページから参照できる GitHub Pages 用ページとして整える。
公開名は `APS-ZOO`。見た目は <https://jikokennobun.github.io/> に寄せて、装飾を減らした単純な入口にする。
設計の参考は RM Zoo documentation (<https://rmzoo.math.uconn.edu/documentation/>)。データから図を生成し、読みにくい巨大HTMLではなくPDFへ逃がす方針にした。

## 現在の方針

- 公開先想定URL: <https://jikokennobun.github.io/G2-ZOO/>
- ホームページ側に足すリンク:

  ```html
  <a href="https://jikokennobun.github.io/G2-ZOO/">抽象的証明可能体系動物園 (Zoo of APS)</a>
  ```

- 公開artifactは `index.html`、`aps-zoo-head.jpg`、PDF群のみ。
- `zoo.svg`、`zoo-auto.svg`、`zoo-proved.svg`、`zoo.png`、`zoo-auto.png`、中間HTML、DOT、TEX、notes は不要。
- 中間HTML/DOT/PNGはPDF作成後に GitHub Actions の `Prune Pages artifact` で削除する。

## 主な関係ファイル

- `.github/workflows/pages.yml`
  - Pages artifact を `out/` からアップロード。
  - Graphviz PNG を中間生成し、Chrome headless で PDF 化。
  - `index.html` は単純なPDFリンク集。
  - `assets/aps-zoo-head.jpg` を `out/aps-zoo-head.jpg` にコピーし、トップ用ヘッダー画像として使う。

- `src/G2Zoo/Zoo.hs`
  - Graphviz DOT 出力を分類図らしくするため、矩形ノード・直角線・抑えた配色へ変更。
  - CI で `fonts-noto-cjk` を入れ、DOTのフォントは `Noto Sans CJK JP` にしている。
  - PNG化でフォント依存の強い `∃☒-FP` が化けないよう、DOT画像用ラベルは `Diam-FP` にしている。

- `app/Main.hs`
  - Windowsでも数学記号を含むファイルを書けるよう、出力ファイルと標準出力をUTF-8に設定済み。

- `src/G2Zoo/Report.hs`
  - PDF印刷用に読みやすい sans-serif と print CSS を設定。

- `src/G2Zoo/Classify.hs`, `src/G2Zoo/Guide.hs`, `src/G2Zoo/G2Chain.hs`, `src/G2Zoo/AlgebraHier.hs`
  - PDF印刷用に読みやすい sans-serif と print CSS を設定。

- `README.md`
  - GitHub Pages連携、公開URL、画像方針を追記。

## 生成コマンド

```sh
stack build
stack exec g2-zoo
stack exec g2-zoo -- auto
stack exec g2-zoo -- proved
stack exec g2-zoo -- matrix
stack exec g2-zoo -- sep
stack exec g2-zoo -- lattice
stack exec g2-zoo -- classify
stack exec g2-zoo -- guide
stack exec g2-zoo -- g2chain
stack exec g2-zoo -- algebra
dot -Tpng out/zoo-proved.dot -o out/zoo-proved.png
dot -Tpng out/zoo-g2chain.dot -o out/zoo-g2chain.png
dot -Tpng out/zoo-algebra.dot -o out/zoo-algebra.png
```

ローカルWindows環境では `dot` が見つからない場合がある。その場合も GitHub Actions の Ubuntu 環境では `sudo apt-get install -y graphviz` 後に生成される。

PDF化はCIで Chrome/Chromium の `--print-to-pdf` を使う。

## 確認済み

- `stack build --silent`
- `stack test --silent`
- `stack exec g2-zoo` / `auto` / `proved` / `matrix` / `sep` / `lattice` / `classify` / `guide` / `g2chain` / `algebra` によるテキストデータ生成
- `out/` 内の画像整理は前回確認済み。改善2ではCI artifact側を `index.html` + PDF + head JPG に剪定する方針へ変更。
- `Invoke-WebRequest http://127.0.0.1:8770/zoo-lattice.html` でHTTP 200

Browserプレビューはローカルサーバー自体はHTTP 200だったが、Codex in-app browser 側で `ERR_BLOCKED_BY_CLIENT` になった。

## 注意

- 自己嫌悪文ホームページ側の `seminar_page.html` は確認時点で404だった。トップページのリンク欄に直接 `G2-ZOO/` を置くか、`seminar_page.html#aps-zoo` を作るかは未決。
- 数学的内容のバックアップPDF:
  - `C:\Users\20010215fjii\Downloads\Syntactical Result about APS.pdf`
  - `C:\Users\20010215fjii\Downloads\shibuya.seminar1.memo.pdf`
  - `C:\Users\20010215fjii\Downloads\shibuya.seminar2.memo.pdf`

## 次にやるなら

- ホームページリポジトリ側を編集できる状態で、上記リンクを `index.html` または `seminar_page.html` に追加する。
- `assets/aps-zoo-head.jpg` はユーザー指定のティーパーティー風イラスト。差し替える場合は同名ファイルを更新する。
- PDF中の未実装章（自己言及 vs 相互言及、基数不変量など）を数学的内容で埋める。
