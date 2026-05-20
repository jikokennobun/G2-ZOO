# G2-ZOO / Incompleteness Kite

APS (Abstract Provability Structure) 周辺の代数的逆数学を Haskell で視覚化するプロジェクトです.
Beklemishev & Shamkanov (2016) の主定理および渋谷個別セミナー (2026.4.15 / 2026.5.08) で議論した
内容を, 型クラス階層 + 動物園 (Zoo) 図として整理することを目指します.

## 現在のスコープ（Scope A + B + C）

Scope A:

- 型クラス階層: `PreOrder`、`Box`、`Diamond`、`PreAPS`、`APS`、`FixedPointAPS`、`LoebAPS`、...
- 公理A1〜A4と命題G2／FG2／Löb／∃☒-FPの有限モデル上の検査
- seminar2メモのCase1〜Case4を具体インスタンスとして実装
- 動物園データ + Graphviz dot出力（出典は別ファイル`zoo-notes.md`に分離）

Scope B:

- `APSData a` / `Carrier a` データ型による前順序代数の機械的表現
- 3点線形担体上での□・☒関数の全列挙（729モデル）
- `searchSeparation` で「前提を満たすが結論を満たさない」モデルを発見
- 既定の分離問題（Case1〜Case3を自動再発見、B&S 2016主定理が反例なしであることを確認）
- A1 上での FG2 ⇒ ∃☒-FP は3点線形上で反例なし、逆向きは反例あり、を Search で検証

Scope C:

- `G2Zoo.AutoZoo` モジュールによる動物園の自動生成
- 命題リスト × 文脈リストから全ペアの含意関係を推論
- 各 (P, Q) ペアあたり最大1辺（最弱の Proved 文脈、なければ最強の Separated 文脈）
- `stack exec g2-zoo -- auto` で `out/zoo-auto.dot` / `out/zoo-auto-notes.md` を生成

Scope D:

- GitHub Pages 用の単純な `index.html` を CI で生成
- 自己嫌悪文ホームページ（<https://jikokennobun.github.io/>）からリンクしやすい Project Pages 構成
- 公開ページ名は `APS-ZOO`
- 公開artifactは `index.html`、頭画像 `aps-zoo-head.svg`、PDF群を基本とする
- 分類・真理値表・反例表・G2-ZOO 図は PDF として公開し、中間HTML/DOT/TEX/PNGはアップロード前に削除する
- 設計参考は RM Zoo documentation（<https://rmzoo.math.uconn.edu/documentation/>）の「データから図を生成する」構成

未実装（今後の課題）:

- 4〜5元担体／非線形・部分順序での探索拡張
- Lean／Coqでの形式化
- 含意付きAPSの含意演算定義の検討
- マグマ・モノイド・代数領域系の型クラス階層

## ビルドと実行

```sh
stack build
stack exec g2-zoo            # 手書き動物園 + モデル充足表
stack exec g2-zoo -- search  # 既定の分離問題を有限モデル探索
stack exec g2-zoo -- auto    # 動物園の自動生成
```

それぞれの出力:

| サブコマンド | 主な出力 | 用途 |
|-----|-----|-----|
| なし | `out/zoo.dot`、`out/zoo-notes.md` | seminar2メモから手書きした動物園 |
| `search` | 標準出力に分離問題8件の検証結果 | 既知の含意・反例を機械検証 |
| `auto` | `out/zoo-auto.dot`、`out/zoo-auto-notes.md` | 命題×文脈の全ペアを推論した動物園 |

分類図PNGへのレンダリング（Graphvizが必要）:

```sh
dot -Tpng out/zoo-proved.dot -o out/zoo-proved.png
```

CI ではこの PNG を中間素材として PDF 化し、公開artifactには残さない。

## 自動生成（`auto`サブコマンド）の使い方

`stack exec g2-zoo -- auto`を実行すると、`defaultAutoProps`（命題リスト）と`defaultAutoContexts`（文脈リスト）の全ペア（P, Q）について「P⇒Qが成立するか」を3点線形担体上の729モデルを全列挙して機械的に検証し、動物園を再構築する。

### 出力の読み方

各ペア（P, Q）あたり最大1辺。

- **青の実線（Proved）**: その含意が成立する**もっとも弱い文脈**を表示。例:「∃☒-FP → FG2」がAPSラベルで青実線なら、APS（A1+A2+A3+A4）が必要だが、それより弱い文脈では成立しない。
- **赤の点線＋否定矢印（Separated）**: どの文脈でも成立せず、**もっとも強い文脈**でも反例が見つかった場合。例:「G2 → FG2」がAPSラベルで赤点線なら、APSを仮定しても反例（Case1）が見つかる。
- **辺なし**: 反例も成立も見つからなかった場合（通常は文脈リストが不十分）。

### 命題（定理／条件）を追加する手順

1. `src/G2Zoo/Search.hs`に新しい述語を書く。たとえばFLöb（形式化Löb）を追加するなら:

   ```haskell
   apsFLoeb :: APSData a -> Bool
   apsFLoeb m = ...
   ```

2. `src/G2Zoo/Zoo.hs`の`Prop`列挙型に`PFLoeb`がすでにあることを確認（なければ追加）。`propLabel`、`propId`にも対応する分岐を追加する。

3. `src/G2Zoo/AutoZoo.hs`の`defaultAutoProps`に追加:

   ```haskell
   defaultAutoProps =
     [ ...
     , AutoProp "FLöb" PFLoeb apsFLoeb
     ]
   ```

4. `stack exec g2-zoo -- auto`を実行。新しい命題がほかの命題とどう関係するかが自動で動物園に追加される。

### 文脈（公理セット）を追加する手順

新しい公理の組み合わせを試したいときは`src/G2Zoo/AutoZoo.hs`の`defaultAutoContexts`を編集する:

```haskell
defaultAutoContexts =
  [ AutoContext (CCustom "A1")          [ apsA1 ]
  , AutoContext (CCustom "A1+A2")       [ apsA1, apsA2 ]
  , AutoContext (CCustom "A1+A4")       [ apsA1, apsA4 ]   -- 新しい文脈
  , AutoContext (CCustom "A1+A2+A4")    [ apsA1, apsA2, apsA4 ]
  , AutoContext COverAPS                [ apsA1, apsA2, apsA3, apsA4 ]
  ]
```

リストの順序は「弱い順」にする。`auto`は前にある文脈から検証し、最初にProvedが見つかった文脈を表示するため、順序が画像の見やすさに直結する。

### 担体を変更する手順

既定は3点線形担体だが、より大きな担体で探索するには`linearCarrier3`を`linearCarrier4`に変更する。`app/Main.hs`の`auto`関数:

```haskell
auto = do
  ...
  let edges = buildAutoZoo linearCarrier4 defaultAutoContexts defaultAutoProps
  ...
```

ただし4点だと探索空間は256×256 = 65536モデルになるため、数秒〜数十秒かかる。

### 典型的な使用シナリオ

1. **新しい定理を予想したとき**: 述語を1行で書き、`auto`を回せば、ほかの命題との関係（成立／反例／辺なし）が自動で動物園に並ぶ。
2. **既知の定理の必要十分性を調べたいとき**: 文脈リストにA1単独、A1+A2、APSを並べておけば、最弱の十分条件が画像上に直接見える。
3. **反例の有無を網羅的に確認したいとき**: `auto`は3点線形担体の全モデルを試すので、3点線形に限れば反例が存在しないことを機械的に保証できる。

注意: 「3点線形担体に反例なし」は数学的な定理の証明ではなく、その担体クラスでの検証にすぎない。4点以上やほかの担体で反例が出ることはある。Lean／Coqでの形式化（Scope D予定）が補完する役割。

分類図PNGへのレンダリング（Graphvizが必要）:

```sh
dot -Tpng out/zoo-proved.dot -o out/zoo-proved.png
```

## GitHub Pages 連携

このリポジトリは `.github/workflows/pages.yml` で GitHub Pages 用成果物を `out/` に生成する。
想定公開URLは次の通り:

<https://jikokennobun.github.io/G2-ZOO/>

自己嫌悪文ホームページ側には、既存のリンク欄または `seminar_page.html#aps-zoo` 相当の場所から次を差し込む:

```html
<a href="https://jikokennobun.github.io/G2-ZOO/">抽象的証明可能体系動物園 (Zoo of APS)</a>
```

公開トップは `APS-ZOO` とし、自己嫌悪文ホームページから地続きに見えるように、戻りリンクと最小限のPDFリンクだけを置く。

CI が公開するPDF:

- `aps-zoo.pdf` — APS-ZOO overview
- `aps-classification.pdf` — APSモデル分類
- `aps-truth-tables.pdf` — APSモデル真理値表
- `aps-countermodels.pdf` — 反例モデル表
- `aps-implication-matrix.pdf` — 含意行列
- `g2-zoo.pdf` — G2-ZOO overview
- `g2-lattice.pdf` — 証明可能性条件と無矛盾性動物園
- `g2-chain.pdf` — FG2 と G2 の間の階層
- `algebra-domain.pdf` — 代数系・領域代数

## テスト

```sh
stack test
```

seminar2 メモの Case1-4 が想定通りに公理・命題を充足するかを回帰的に検査する.

## ディレクトリ構成

```
.
├── g2-zoo.cabal
├── stack.yaml
├── README.md
├── src/
│   └── G2Zoo/
│       ├── PreOrder.hs   -- 前順序 / Box / Diamond
│       ├── APS.hs        -- PreAPS / APS / FixedPointAPS / LoebAPS / ImpAPS
│       ├── Properties.hs -- 公理 A1-A4 と命題 G2/FG2/Löb の検査
│       ├── Instances.hs  -- Linear3, Case1-4, Trivial2
│       └── Zoo.hs        -- 動物園データと dot レンダラ
├── app/
│   └── Main.hs           -- g2-zoo 実行可能形式
└── test/
    └── Spec.hs           -- Case1-4 の回帰テスト
```

## 型クラス階層

```
                 ImpAPS
                   |
   FixedPointAPS  APS  LoebAPS  BoxFixedPointAPS
        \         |       /         /
         \        |      /         /
          +-----+ | +---+         /
                \|/             /
                PreAPS  --------+
                  |
                Box, Diamond
                  |
                PreOrder
```

`APS` クラスは A1-A4 を満たすことを意図したマーカ. 法則の充足は `G2Zoo.Properties` の
述語 (`checkA1`, ..., `checkA4`, `checkG2`, ...) で個別に検査する.

## 動物園 (Zoo) の辺の見方

矢印は含意関係を表し, ラベルにその含意が成立する文脈 (どの代数構造の上での話か) を
書き込む:

- 黒の実線 (`PreAPS`, `APS`, `LoebAPS`, ...): その文脈で成立する含意
- 緑の破線 + `?` : 成否未解決の含意
- 赤の点線 + `✗` (棒矢印): 反例モデルが存在することが確認されている

例:

- `∃☒-FP --[APS]--> FG2` : B&S 2016 主定理 (実線)
- `FG2 --[A1+A2]--> G2` : Syntactical Result メモの Fact (実線)
- `G2 -.-[APS]-✗-> FG2` : seminar2 Case1 による分離 (赤点線)

## 参考文献

- L. Beklemishev, D. Shamkanov (2016).
  *Some abstract versions of Gödel's second incompleteness theorem based on non-classical logics*.
  arXiv:1602.05728.
- F. Pakhomov, A. Visser (2022). *Predicative extension of APS*.
- 渋谷個別セミナー 2026.4.15.Wed (seminar1) / 2026.5.08.Fri (seminar2)
- Syntactical Result about APS (Google Docs)

## 関連リンク

- 逆数学動物園: <https://rmzoo.math.uconn.edu/>
- RM Zoo documentation: <https://rmzoo.math.uconn.edu/documentation/>
- Tao の PFR Lean blueprint: <https://terrytao.wordpress.com/2023/11/18/formalizing-the-proof-of-pfr-in-lean4-using-blueprint-a-short-tour/>
- Graphviz: <https://graphviz.org/>
- diagrams: <https://diagrams.github.io/>
