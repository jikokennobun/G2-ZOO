-- | g2-zoo 実行可能形式.
--
-- サブコマンド:
--
-- * 引数なし: 動物園 dot 出力 + モデル充足表
-- * @search@: 既定の分離問題を有限モデル探索で機械的に検証
module Main (main) where

import Data.Proxy        (Proxy (..))
import System.Directory  (createDirectoryIfMissing)
import System.Environment (getArgs)
import System.Exit       (exitFailure)
import System.IO         (IOMode (..), hPutStr, withFile)

import G2Zoo

main :: IO ()
main = do
  args <- getArgs
  case args of
    []          -> generate
    ["search"]  -> search
    ["auto"]    -> auto
    ["proved"]  -> proved
    ["matrix"]  -> matrix
    ["sep"]      -> sep
    ["lattice"]  -> lattice
    ["classify"] -> classify
    ["guide"]    -> guide
    _            -> usage

usage :: IO ()
usage = do
  putStrLn "Usage: g2-zoo [search|auto|proved|matrix|sep|lattice]"
  putStrLn ""
  putStrLn "  (no args)   手書きの動物園 dot を出力し各モデルの充足表を表示"
  putStrLn "  search      有限モデル探索で既定の分離問題を検証"
  putStrLn "  auto        命題リストと文脈リストから動物園を自動生成"
  putStrLn "  proved      正の含意のみを抽出した格子図 dot を出力"
  putStrLn "  matrix      命題 × 命題の含意行列 HTML を生成  (A)"
  putStrLn "  sep         反例モデルカード HTML を生成         (B)"
  putStrLn "  lattice     格子図 + 辺注釈テーブル HTML を生成  (C)"
  putStrLn "  classify    有限モデル分類データベース HTML を生成"
  putStrLn "  guide       名前付きモデルの構成ガイド HTML を生成"
  exitFailure

generate :: IO ()
generate = do
  createDirectoryIfMissing True "out"
  let dot   = renderDot   defaultZoo
      tex   = renderTikZ  defaultZoo
      notes = renderNotes defaultZoo
  withFile "out/zoo.dot"      WriteMode $ \h -> hPutStr h dot
  withFile "out/zoo.tex"      WriteMode $ \h -> hPutStr h tex
  withFile "out/zoo-notes.md" WriteMode $ \h -> hPutStr h notes
  putStrLn "Wrote out/zoo.dot"
  putStrLn "Wrote out/zoo.tex"
  putStrLn "Wrote out/zoo-notes.md"
  putStrLn ""
  putStrLn "  Render to SVG:    dot -Tsvg out/zoo.dot -o out/zoo.svg"
  putStrLn "  Render to PNG:    dot -Tpng out/zoo.dot -o out/zoo.png"
  putStrLn "  Render via TeX:   pdflatex -output-directory=out out/zoo.tex"
  putStrLn ""
  putStrLn "===== Model report ====="
  mapM_ printReport models
  printImpReport

models :: [Report]
models =
  [ reportOn "Linear3 (L_Id)" (Proxy :: Proxy Linear3)
  , reportOn "Case1"          (Proxy :: Proxy Case1)
  , reportOn "Case2"          (Proxy :: Proxy Case2)
  , reportOn "Case3"          (Proxy :: Proxy Case3)
  , reportOn "Case4"          (Proxy :: Proxy Case4)
  , reportOn "Trivial2"       (Proxy :: Proxy Trivial2)
  , reportOn "Case1Godel"     (Proxy :: Proxy Case1Godel)
  , reportOn "L4Id"           (Proxy :: Proxy L4Id)
  ]

printImpReport :: IO ()
printImpReport = do
  putStrLn ""
  putStrLn "===== ImpAPS 含意演算の比較 (Case1 担体: 3点線形) ====="
  putStrLn ""
  putStrLn "  内在化条件: ⊤ ≤ x→y ⟺ x ≤ y"
  putStrLn ""
  rowImp "Case1 + Łukasiewicz" (checkImpInternalization (Proxy :: Proxy Case1))
  rowImp "Case1 + Gödel      " (checkImpInternalization (Proxy :: Proxy Case1Godel))
  where
    rowImp name v = putStrLn $ "  " ++ name ++ ": " ++ tick v
    tick True  = "✓"
    tick False = "✗"

printReport :: Report -> IO ()
printReport r = do
  putStrLn ""
  putStrLn $ "[" ++ reportName r ++ "]"
  row "A1"          (reportA1 r)
  row "A2"          (reportA2 r)
  row "A3"          (reportA3 r)
  row "A4"          (reportA4 r)
  row "A4'"         (reportA4Prime r)
  row "Consistent"  (reportConsistent r)
  row "G2"          (reportG2 r)
  row "WFG2"        (reportWFG2 r)
  row "FG2"         (reportFG2 r)
  row "FLoeb"       (reportFLoeb r)
  row "Loeb"        (reportLoeb r)
  row "∃☒-FP"      (reportHasDiamFP r)
  row "∃□-FP"      (reportHasBoxFP r)
  where
    row name v = putStrLn $ "  " ++ pad 12 name ++ tick v
    tick True  = "✓"
    tick False = "✗"
    pad n s = s ++ replicate (max 0 (n - length s)) ' '

proved :: IO ()
proved = do
  createDirectoryIfMissing True "out"
  let edges = filterProved defaultZoo
      dot   = renderDot   edges
      tex   = renderTikZ  edges
      notes = renderNotes edges
  withFile "out/zoo-proved.dot"      WriteMode $ \h -> hPutStr h dot
  withFile "out/zoo-proved.tex"      WriteMode $ \h -> hPutStr h tex
  withFile "out/zoo-proved-notes.md" WriteMode $ \h -> hPutStr h notes
  putStrLn "Wrote out/zoo-proved.dot"
  putStrLn "Wrote out/zoo-proved.tex"
  putStrLn "Wrote out/zoo-proved-notes.md"
  putStrLn ""
  putStrLn $ "Proved edges: " ++ show (length edges)
  putStrLn ""
  putStrLn "  Render to SVG:    dot -Tsvg out/zoo-proved.dot -o out/zoo-proved.svg"
  putStrLn "  Render to PNG:    dot -Tpng out/zoo-proved.dot -o out/zoo-proved.png"
  putStrLn "  Render via TeX:   pdflatex -output-directory=out out/zoo-proved.tex"

auto :: IO ()
auto = do
  createDirectoryIfMissing True "out"
  let edges = buildAutoZoo linearCarrier3 defaultAutoContexts defaultAutoProps
      dot   = renderDot   edges
      tex   = renderTikZ  edges
      notes = renderNotes edges
  withFile "out/zoo-auto.dot"      WriteMode $ \h -> hPutStr h dot
  withFile "out/zoo-auto.tex"      WriteMode $ \h -> hPutStr h tex
  withFile "out/zoo-auto-notes.md" WriteMode $ \h -> hPutStr h notes
  putStrLn "Wrote out/zoo-auto.dot"
  putStrLn "Wrote out/zoo-auto.tex"
  putStrLn "Wrote out/zoo-auto-notes.md"
  putStrLn ""
  putStrLn $ "Edges inferred: " ++ show (length edges)
  putStrLn ""
  putStrLn "  Render to SVG:    dot -Tsvg out/zoo-auto.dot -o out/zoo-auto.svg"
  putStrLn "  Render to PNG:    dot -Tpng out/zoo-auto.dot -o out/zoo-auto.png"
  putStrLn "  Render via TeX:   pdflatex -output-directory=out out/zoo-auto.tex"

-- | A: 含意行列 HTML
matrix :: IO ()
matrix = do
  createDirectoryIfMissing True "out"
  let html = renderMatrix defaultZoo
  withFile "out/zoo-matrix.html" WriteMode $ \h -> hPutStr h html
  putStrLn "Wrote out/zoo-matrix.html"

-- | B: 反例モデルカード HTML
sep :: IO ()
sep = do
  createDirectoryIfMissing True "out"
  html <- renderCounterexamplesHtml defaultQueries
  withFile "out/counterexamples.html" WriteMode $ \h -> hPutStr h html
  putStrLn "Wrote out/counterexamples.html"
  putStrLn $ "  " ++ show (length sepQs) ++ " counterexample card(s)"
  where
    sepQs = filter ((== Sep) . queryExpect) defaultQueries

-- | E: 名前付きモデル構成ガイド HTML
guide :: IO ()
guide = do
  createDirectoryIfMissing True "out"
  let ms = namedModels
      html = renderGuideHtml ms
  withFile "out/zoo-guide.html" WriteMode $ \h -> hPutStr h html
  putStrLn "Wrote out/zoo-guide.html"
  putStrLn $ "  " ++ show (length ms) ++ " named model(s)"

namedModels :: [NamedModel]
namedModels =
  [ mkNamedModel "Linear3 (L_Id)" "3点線形"
      "最も単純な 3点線形モデル。□=☒=恒等写像。\
      \A2: ⊤≤☒⊥=⊥ が ⊤≤⊥ となり成立しないため、公理系の前提なしでは使えない。\
      \□ と ☒ の基準点として参照用に掲載。"
      (Proxy :: Proxy Linear3)

  , mkNamedModel "Case1" "3点線形"
      "seminar2 の Case1。APS (A1–A4) を満たし G2 を満たすが FG2 は満たさない 3値最小例。\
      \☒⊤=a, ☒a=⊤, ☒⊥=⊤ と設定することで ☒☒⊤=☒a=⊤ > a=☒⊤ となり FG2 が失敗する。\
      \∃☒-FP も持たない。APS ならば FG2 ⟺ ∃☒-FP (B&S 2016) と整合的。"
      (Proxy :: Proxy Case1)

  , mkNamedModel "Case2" "3点線形"
      "Case1 と同じ □/☒ テーブルを持つ別名モデル (seminar2 では同表)。\
      \seminar2 での Case2 は「APS で G2 を満たし ∃☒-FP を持たない例」として導入された。\
      \Case1 との同型性を明示するために別名で定義してある。"
      (Proxy :: Proxy Case2)

  , mkNamedModel "Case3" "3点線形"
      "A1+A2+A4 を満たすが A3 を外したモデル。☒a=a なので ∃☒-FP を持つ。\
      \しかし FG2 は満たさない (☒☒⊤=☒⊥=⊤ > ⊥=☒⊤ ... 実は ☒⊤=⊥ であることを確認のこと)。\
      \「A3 なしでは ∃☒-FP ⇒ FG2 が成立しない」ことを示す分離例。"
      (Proxy :: Proxy Case3)

  , mkNamedModel "Case4" "3点線形"
      "A1+A2+A3 を満たすが A4 (☒x≤□☒x) は外したモデル。□≡⊥ と設定。\
      \A4': □x≤□□x は満たす (□≡⊥ なら □□x=□⊥=⊥=□x で成立)。\
      \∃☒-FP あり (☒a=a)。「A4 と A4' は等価でない」を示す分離例。"
      (Proxy :: Proxy Case4)

  , mkNamedModel "Trivial2" "2点"
      "2点退化モデル ({⊥,⊤})。□=id, ☒≡⊥ (☒は常に⊥を返す)。\
      \A2: ⊤≤☒⊥=⊥ が成立しないため APS 公理を満たさない。\
      \一貫性は満たす (⊤≰⊥)。G2: ☒⊤=⊥≤⊥ ならば ⊤≤⊥ となるべきだが後者が偽→G2 失敗。\
      \Syntactical Result の反例モデルとして seminar2 で多用される。"
      (Proxy :: Proxy Trivial2)

  , mkNamedModel "Case1Godel" "3点線形"
      "Case1 と同じ APS 構造を持ち、含意演算を Gödel 含意 (x→y = ⊤ if x≤y, else y) に替えたモデル。\
      \内在化条件 ⊤≤x→y ⟺ x≤y を Łukasiewicz 含意 (Case1) と比較するための例。\
      \Gödel 含意は内在化条件を満たすが Łukasiewicz は満たさない。"
      (Proxy :: Proxy Case1Godel)

  , mkNamedModel "L4Id" "4点線形"
      "WFG2 ⇏ FG2 の最小反例。4点線形 {⊥<a<b<⊤}、□=id。\
      \☒⊤=a, ☒b=a, ☒a=b, ☒⊥=⊤ と設定。\
      \WFG2: ☒⊤=a≠⊥ なので前提が偽→空虚に真。\
      \FG2: ☒☒⊤=☒a=b, ☒⊤=a, b≰a で失敗。APS (A1–A4) はすべて満たす。"
      (Proxy :: Proxy L4Id)
  ]

-- | D: 有限モデル分類データベース HTML
classify :: IO ()
classify = do
  createDirectoryIfMissing True "out"
  putStrLn "=== 有限モデル分類 ==="
  sections <- mapM run
    [ ("3点線形",        linearCarrier3)
    , ("4点線形",        linearCarrier4)
    , ("4点ダイアモンド", diamondCarrier)
    ]
  let html = renderClassifyHtml sections
  withFile "out/zoo-classify.html" WriteMode $ \h -> hPutStr h html
  putStrLn "Wrote out/zoo-classify.html"
  where
    run (name, c) = do
      putStr $ "  " ++ name ++ " ... "
      let recs   = classifyModels c
          groups = groupByProfile recs
          total  = length recs
          nProf  = length groups
      putStrLn $ show total ++ " モデル → " ++ show nProf ++ " プロファイル"
      return (name, total, groups)

-- | C: 格子図 + 注釈テーブル HTML
lattice :: IO ()
lattice = do
  createDirectoryIfMissing True "out"
  let html = renderLatticeHtml defaultZoo
  withFile "out/zoo-lattice.html" WriteMode $ \h -> hPutStr h html
  putStrLn "Wrote out/zoo-lattice.html"

search :: IO ()
search = do
  putStrLn "===== Counterexample search ====="
  putStrLn ""
  results <- mapM run defaultQueries
  let bad = filter not results
  putStrLn ""
  putStrLn $ "Summary: " ++ show (length results - length bad) ++ "/"
          ++ show (length results) ++ " queries matched expectation."
  case bad of
    [] -> pure ()
    _  -> exitFailure
  where
    run q = do
      putStrLn $ "[" ++ queryName q ++ "]"
      r <- queryRun q
      let ok = case (r, queryExpect q) of
                 (Just _, Sep)   -> True
                 (Nothing, NoSep) -> True
                 _ -> False
      case r of
        Just m  -> do
          putStrLn "  → counterexample found:"
          mapM_ (putStrLn . ("    " ++)) (lines m)
        Nothing ->
          putStrLn "  → no counterexample on this carrier (within search bound)"
      putStrLn $ "  expectation: " ++ show (queryExpect q)
                 ++ "  " ++ (if ok then "✓" else "✗ MISMATCH")
      putStrLn ""
      pure ok
