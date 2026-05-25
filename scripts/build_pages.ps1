$ErrorActionPreference = 'Stop'

$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$Out = Join-Path $Root 'out'
$Tex = Join-Path $Out 'tex'
$TexCache = Join-Path ([System.IO.Path]::GetTempPath()) 'aps-zoo-tex-cache'
$SlidesOut = Join-Path $Out 'slides'

New-Item -ItemType Directory -Force $Out, $Tex, $TexCache, $SlidesOut | Out-Null
$env:TEXMFVAR = $TexCache
$env:TEXMFCACHE = $TexCache
Copy-Item -LiteralPath (Join-Path $Root 'assets/aps-zoo-head.jpg') -Destination (Join-Path $Out 'aps-zoo-head.jpg') -Force

$slideSource = Join-Path $Root 'assets/slides'
if (Test-Path $slideSource) {
  Copy-Item -LiteralPath (Join-Path $slideSource 'aps_g2_algebraic_reverse_math_v4.pdf') -Destination (Join-Path $SlidesOut 'aps_g2_algebraic_reverse_math_v4.pdf') -Force
}

function Write-Utf8 {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Text
  )
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

Write-Utf8 (Join-Path $Out 'index.html') @'
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>APS-ZOO</title>
  <style>
    body { background:#fff2f6; color:#26141b; font-family:"Times New Roman","Noto Serif JP",serif;
           line-height:1.65; margin:0 auto; max-width:900px; padding:1.2em 2em 3em; }
    h1 { font-size:1.55em; margin:0.2em 0 0.6em; font-weight:normal; }
    h2 { font-size:1.08em; margin:1.2em 0 0.3em; font-weight:normal; }
    a { color:#0044aa; }
    nav a { display:block; margin:0.12em 0; }
    .head-image { display:block; max-width:100%; max-height:360px; height:auto; margin:0.5em 0 1em; }
    .mark { color:#8a3050; }
    .note { font-size:0.95em; }
  </style>
</head>
<body>
  <h1>APS-ZOO</h1>
  <img class="head-image" src="aps-zoo-head.jpg" alt="APS-ZOO">
  <p>抽象的証明可能体系 (APS) と第二不完全性現象のための，TeX/PDF 中心の小さな動物園．</p>

  <p><a href="https://jikokennobun.github.io/">&larr; 自己嫌悪文のページへ戻る</a></p>

  <h2><span class="mark">◆</span> TeX PDFs</h2>
  <nav>
    <a href="aps-zoo.pdf">APS-ZOO overview</a>
    <a href="aps-classification.pdf">APSモデル分類</a>
    <a href="aps-truth-tables.pdf">APSモデル真理値表</a>
    <a href="aps-countermodels.pdf">反例モデル表</a>
    <a href="aps-implication-matrix.pdf">含意図・含意表</a>
    <a href="g2-zoo.pdf">G2-ZOO overview</a>
    <a href="g2-lattice.pdf">証明可能性条件と無矛盾性動物園</a>
    <a href="g2-chain.pdf">FG2 と G2 の間の階層</a>
    <a href="algebra-domain.pdf">代数系・領域代数</a>
  </nav>

  <h2><span class="mark">◆</span> Profile / slides</h2>
  <nav>
    <a href="profile.html">自己紹介ページ</a>
    <a href="slides/aps_g2_algebraic_reverse_math_v4.pdf">APS / G2 algebraic reverse mathematics v4</a>
  </nav>

  <h2><span class="mark">◆</span> Notes</h2>
  <p class="note">PDF は Chrome 印刷ではなく LaTeX で作成する．表は TeX の tabular / tabularx / longtable を使う．HTML は入口と自己紹介だけにする．</p>
</body>
</html>
'@

Write-Utf8 (Join-Path $Out 'profile.html') @'
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Jikokenno-Bun</title>
  <style>
    body { background:#fff2f6; color:#26141b; font-family:"Times New Roman","Noto Serif JP",serif;
           line-height:1.65; margin:0 auto; max-width:820px; padding:1.2em 2em 3em; }
    h1 { font-size:1.55em; margin:0.2em 0 0.8em; font-weight:normal; }
    h2 { font-size:1.08em; margin:1.2em 0 0.3em; font-weight:normal; }
    a { color:#0044aa; }
    .name-block { white-space:pre-line; margin:0.5em 0 1em; }
    .mark { color:#8a3050; }
  </style>
</head>
<body>
  <h1>Jikokenno-Bun</h1>
  <p><a href="./">&larr; APS-ZOOへ戻る</a></p>

  <h2><span class="mark">◆</span> 自己紹介</h2>
  <div class="name-block">自己嫌悪文
自我憎恨的句子
Jikokenno-Bun
Selbsthass-Sätze
προτάσεις αυτομίσους</div>

  <p>webpage: <a href="https://jikokennobun.github.io/">jikokennobun.github.io</a><br>
  twitter: <a href="https://twitter.com/jikokennobun">@jikokennobun</a><br>
  e-mail: <a href="mailto:yizhi6331@gmail.com">yizhi6331@gmail.com</a></p>

  <p>未だ A student の身なり．<br>
  Structuality と Abstraction を大事にする．<br>
  Mathematical Logician を目指したい．</p>

  <h2><span class="mark">◆</span> Slides</h2>
  <p>B2Dフォーラムや若手の会で使うスライドは，ここに置いていく．</p>
  <ul>
    <li><a href="slides/aps_g2_algebraic_reverse_math_v4.pdf">APS / G2 algebraic reverse mathematics v4</a></li>
  </ul>
</body>
</html>
'@

Write-Utf8 (Join-Path $Tex 'common.tex') @'
\documentclass[a4paper,11pt]{ltjsarticle}
\usepackage[top=20mm,bottom=22mm,left=18mm,right=18mm]{geometry}
\usepackage{amsmath,amssymb}
\usepackage{booktabs,longtable,tabularx,array,graphicx}
\usepackage[table]{xcolor}
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning,calc}
\usepackage[colorlinks=true,linkcolor=magenta!45!black,urlcolor=blue!60!black]{hyperref}
\definecolor{softpink}{HTML}{FFF2F6}
\definecolor{rulepink}{HTML}{B85D7C}
\setlength{\parindent}{0pt}
\setlength{\parskip}{4pt}
\renewcommand{\arraystretch}{1.15}
\newcolumntype{Y}{>{\raggedright\arraybackslash}X}
\newcommand{\ZooTitle}[1]{%
  {\Large\bfseries #1\par}
  \vspace{2mm}{\color{rulepink}\hrule height 0.6pt}\vspace{4mm}}
\pagecolor{white}
'@

Write-Utf8 (Join-Path $Tex 'aps-zoo.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{APS-ZOO overview}
\begin{center}
\includegraphics[width=.78\linewidth,height=.24\textheight,keepaspectratio]{../aps-zoo-head.jpg}
\end{center}
APS を中心に，モデル分類・演算表・反例表を TeX の表として読むための入口である．
HTML は最小限の索引に留め，重い表現は PDF に分ける．

\section*{構造の見取り図}
\begin{tabularx}{\textwidth}{>{\bfseries}p{.19\textwidth}Y p{.22\textwidth}}
\toprule
対象 & この版での扱い & 備考\\
\midrule
APS & $A_1$--$A_4$ を満たす基本構造．有限モデル分類，真理値表，反例表の基準． & 既存実装あり\\
弱含意付きAPS & 内在化条件を弱めた含意付き構造として整理する． & 拡張予定\\
剰余付きAPS & Heyting / 残余演算と APS の比較対象． & 代数系PDFへ接続\\
ファイバーAPS & 基底ごとの APS を束ねる相対化された構造． & モデル追加領域\\
相対APS & 文脈・基底理論をパラメータ化した APS． & 辺ラベルに反映\\
2重APS & 二つの証明可能性演算・二重様相の比較用． & 設計項目\\
領域代数 & 不動点空間やコンパクト元と接続する代数的領域． & 代数系PDFへ接続\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'aps-classification.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{APSモデル分類}
有限前順序上で得られるプロファイルを，巨大なHTML表ではなく要約表として読む．詳細な全列挙データはプログラム側に残す．

\begin{tabularx}{\textwidth}{>{\bfseries}p{.22\textwidth}r r Y}
\toprule
担体 & 列挙モデル数 & プロファイル数 & 読み方\\
\midrule
3点線形 & 729 & 204 & 最小の検査領域．基本反例と既知モデルの照合に使う．\\
4点線形 & 65536 & 385 & 線形担体で反例候補を広げる．\\
4点ダイアモンド & 65536 & 429 & 非線形の分岐を入れた比較対象．\\
\bottomrule
\end{tabularx}

\section*{代表モデル}
\begin{tabularx}{\textwidth}{>{\bfseries}p{.18\textwidth}Y}
\toprule
モデル & 役割\\
\midrule
Case1 / Case2 & APS で $G_2$ は成り立つが $\mathrm{FG}_2$ は落ちる反例．\\
Case3 & $A_3$ が落ちる境界例．\\
Case4 & $A_4$ が落ちる境界例．\\
Trivial2 & 2点の基礎検査用モデル．\\
Case1Godel / L4Id & 含意演算や4点線形の比較用モデル．\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'aps-truth-tables.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{APSモデル真理値表}
\small
\begin{longtable}{>{\bfseries}p{.18\textwidth}cccccccccccc}
\toprule
Model & A1&A2&A3&A4&A4'&Con&G2&WFG2&FG2&FLoeb&Loeb&$\exists\boxtimes$FP\\
\midrule
\endhead
Linear3 (L\_Id) & --&--&+&+&+&+&+&+&+&+&--&+\\
Case1 & +&+&+&+&+&+&+&+&--&+&--&--\\
Case2 & +&+&+&+&+&+&+&+&--&+&--&--\\
Case3 & +&+&--&+&+&+&--&--&--&+&--&+\\
Case4 & +&+&+&--&+&+&--&--&--&+&--&+\\
Trivial2 & +&--&+&+&+&+&--&+&+&+&--&+\\
Case1Godel & +&+&+&+&+&+&+&+&--&+&--&--\\
L4Id & +&+&+&+&+&+&+&+&--&+&--&--\\
\bottomrule
\end{longtable}
\normalsize
記号 $+$ は成立，-- は不成立を表す．
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'aps-countermodels.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{反例モデル表}
反例は「どの仮定を満たしたまま，どの結論が落ちるか」を見るために使う．

\begin{tabularx}{\textwidth}{>{\bfseries}p{.17\textwidth}p{.23\textwidth}p{.23\textwidth}Y}
\toprule
モデル & 保つ条件 & 落ちる条件 & 用途\\
\midrule
Case1 & $A_1,A_2,A_3,A_4,G_2$ & $\mathrm{FG}_2$, $\exists\boxtimes$FP & $G_2\not\Rightarrow\mathrm{FG}_2$ の基本反例．\\
Case2 & $A_1,A_2,A_3,A_4,G_2$ & $\mathrm{FG}_2$, $\exists\boxtimes$FP & Case1 と同型でない確認用反例．\\
Case3 & $A_1,A_2,A_4$ & $A_3,G_2,\mathrm{WFG}_2,\mathrm{FG}_2$ & $A_3$ の必要性を見る境界例．\\
Case4 & $A_1,A_2,A_3$ & $A_4,G_2,\mathrm{WFG}_2,\mathrm{FG}_2$ & $A_4$ の必要性を見る境界例．\\
Trivial2 & $A_1,A_3,A_4,\mathrm{FG}_2$ & $A_2,G_2,\mathrm{Loeb}$ & 2点担体の簡約例．\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'aps-implication-matrix.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{含意図・含意表}
\begin{center}
\begin{tikzpicture}[
  node distance=16mm and 24mm,
  box/.style={draw=rulepink, rounded corners=2pt, fill=softpink, inner sep=5pt, align=center},
  arr/.style={-{Stealth[length=2.2mm]}, thick},
  lab/.style={fill=white, inner sep=1pt, font=\small}
]
\node[box] (dfp) {$\exists\boxtimes$-FP};
\node[box, right=of dfp] (fg2) {$\mathrm{FG}_2$};
\node[box, below=of fg2] (wfg2) {$\mathrm{WFG}_2$};
\node[box, below=of wfg2] (g2) {$G_2$};
\draw[arr] (dfp) -- node[lab, above] {APS} (fg2);
\draw[arr] (fg2) -- node[lab, right] {PreAPS} (wfg2);
\draw[arr] (wfg2) -- node[lab, right] {$A_1+A_2$} (g2);
\draw[arr] (fg2) to[bend left=16] node[lab, left] {$A_1+A_2$} (g2);
\draw[arr] (fg2) to[bend left=16] node[lab, above] {$A_1$} (dfp);
\draw[arr] (dfp) to[bend right=18] node[lab, below] {APS} (g2);
\end{tikzpicture}
\end{center}

\begin{tabularx}{\textwidth}{>{\bfseries}p{.24\textwidth}p{.18\textwidth}Y}
\toprule
含意 & 文脈 & 備考\\
\midrule
$\exists\boxtimes$-FP $\Rightarrow \mathrm{FG}_2$ & APS & B\&S 型の主含意．\\
$\exists\boxtimes$-FP $\Rightarrow G_2$ & APS & 上の含意と $\mathrm{FG}_2\Rightarrow G_2$ から読む．\\
$\mathrm{FG}_2\Rightarrow\mathrm{WFG}_2$ & PreAPS & 形式的弱化．\\
$\mathrm{WFG}_2\Rightarrow G_2$ & $A_1+A_2$ & 弱含意から第二不完全性型条件へ．\\
$\mathrm{FG}_2\Rightarrow G_2$ & $A_1+A_2$ & syntactical result の中心線．\\
$\mathrm{FG}_2\Rightarrow\exists\boxtimes$-FP & $A_1$ & 逆向きの条件付き含意．\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'g2-zoo.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{G2-ZOO overview}
第二不完全性現象の周辺を，章ごとのPDFに分けて読む．

\section*{主要な章}
\begin{tabularx}{\textwidth}{>{\bfseries}p{.30\textwidth}Y p{.18\textwidth}}
\toprule
章 & 内容 & 状態\\
\midrule
$\exists\boxtimes$FP と TAUT の間の階層 & 不動点存在から恒真性条件へ向かう含意・反例の整理． & 骨組み\\
FG2 と G2 の間の階層 & FG2, WFG2, G2, Loeb, $\exists\boxtimes$FP の関係． & 図あり\\
証明可能性条件と無矛盾性動物園 & Con, G2, Loeb, 形式化条件の比較． & 接続済み\\
自己言及補題 vs. 相互言及補題 & 単一不動点と相互参照型不動点の比較． & 設計項目\\
基数不変量 (不動点空間) & 不動点空間の大きさ・分類を不変量として扱う． & 設計項目\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'g2-lattice.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{証明可能性条件と無矛盾性動物園}
\begin{tabularx}{\textwidth}{>{\bfseries}p{.20\textwidth}Y p{.20\textwidth}}
\toprule
条件 & 意味 & 位置づけ\\
\midrule
$G_2$ & 第二不完全性型の無矛盾性条件． & 中心\\
$\mathrm{FG}_2$ & 形式化された第二不完全性条件． & 強い\\
$\mathrm{WFG}_2$ & 弱い形式化条件． & 中間\\
Loeb & Loeb 型の反射条件． & 比較対象\\
FLoeb & 形式化Loeb条件． & 多くの有限例で成立\\
Consistency & 最小元がBoxで潰れないこと． & 基礎条件\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'g2-chain.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{FG2 と G2 の間の階層}
\begin{center}
\begin{tikzpicture}[
  node distance=15mm,
  box/.style={draw=rulepink, rounded corners=2pt, fill=softpink, minimum width=30mm, inner sep=5pt, align=center},
  arr/.style={-{Stealth[length=2.2mm]}, thick}
]
\node[box] (fg2) {$\mathrm{FG}_2$};
\node[box, below=of fg2] (wfg2) {$\mathrm{WFG}_2$};
\node[box, below=of wfg2] (g2) {$G_2$};
\node[box, left=26mm of fg2] (dfp) {$\exists\boxtimes$-FP};
\draw[arr] (dfp) -- node[above, font=\small] {APS} (fg2);
\draw[arr] (fg2) -- node[right, font=\small] {PreAPS} (wfg2);
\draw[arr] (wfg2) -- node[right, font=\small] {$A_1+A_2$} (g2);
\draw[arr] (fg2) to[bend left=18] node[right, font=\small] {$A_1+A_2$} (g2);
\end{tikzpicture}
\end{center}

\begin{tabularx}{\textwidth}{>{\bfseries}p{.24\textwidth}Y}
\toprule
階層 & 説明\\
\midrule
$\mathrm{FG}_2$ & 形式化を含む強い条件．\\
$\mathrm{WFG}_2$ & 形式化の弱い中間条件．\\
$G_2$ & 通常の第二不完全性型条件．\\
\bottomrule
\end{tabularx}
\end{document}
'@

Write-Utf8 (Join-Path $Tex 'algebra-domain.tex') @'
\input{common.tex}
\begin{document}
\ZooTitle{代数系・領域代数}
\begin{center}
\begin{tikzpicture}[
  node distance=12mm and 18mm,
  box/.style={draw=rulepink, rounded corners=2pt, fill=softpink, inner sep=5pt, align=center},
  arr/.style={-{Stealth[length=2.2mm]}, thick}
]
\node[box] (pre) {PreOrder};
\node[box, above=of pre] (boxd) {Box / Diamond};
\node[box, above=of boxd] (preaps) {PreAPS};
\node[box, above left=of preaps] (aps) {APS};
\node[box, above=of preaps] (fp) {FixedPointAPS};
\node[box, above right=of preaps] (loeb) {LoebAPS};
\node[box, right=of aps] (imp) {ImpAPS};
\node[box, right=of fp] (domain) {領域代数};
\draw[arr] (pre) -- (boxd);
\draw[arr] (boxd) -- (preaps);
\draw[arr] (preaps) -- (aps);
\draw[arr] (preaps) -- (fp);
\draw[arr] (preaps) -- (loeb);
\draw[arr] (aps) -- (imp);
\draw[arr] (fp) -- (domain);
\end{tikzpicture}
\end{center}

\begin{tabularx}{\textwidth}{>{\bfseries}p{.24\textwidth}Y}
\toprule
対象 & 見るもの\\
\midrule
ImpAPS & 含意演算と内在化条件．\\
FixedPointAPS & 不動点存在の構造的条件．\\
LoebAPS & Loeb 条件の抽象化．\\
領域代数 & 不動点空間，コンパクト元，基数不変量への接続．\\
\bottomrule
\end{tabularx}
\end{document}
'@

$texNames = @(
  'aps-zoo',
  'aps-classification',
  'aps-truth-tables',
  'aps-countermodels',
  'aps-implication-matrix',
  'g2-zoo',
  'g2-lattice',
  'g2-chain',
  'algebra-domain'
)

Push-Location $Tex
try {
  foreach ($name in $texNames) {
    & lualatex -interaction=nonstopmode -halt-on-error "$name.tex"
    if ($LASTEXITCODE -ne 0) {
      throw "lualatex failed for $name.tex"
    }
  }
}
finally {
  Pop-Location
}

foreach ($name in $texNames) {
  Copy-Item -LiteralPath (Join-Path $Tex "$name.pdf") -Destination (Join-Path $Out "$name.pdf") -Force
}
