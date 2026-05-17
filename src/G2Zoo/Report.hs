-- | 動物園の3種類の補助 HTML レポート.
--
-- * 'renderMatrix'             -- A: 命題 × 命題 含意行列 (HTML)
-- * 'renderCounterexamplesHtml' -- B: 反例モデルカード (HTML)
-- * 'renderLatticeHtml'        -- C: 格子図 + 辺注釈テーブル (HTML)
module G2Zoo.Report
  ( renderMatrix
  , renderCounterexamplesHtml
  , renderLatticeHtml
  ) where

import Data.List (intercalate, nub, sortBy)
import Data.Ord  (comparing)

import G2Zoo.Search (Expected (..), Query (..))
import G2Zoo.Zoo

-- ============================================================================
-- 共通ヘルパ
-- ============================================================================

-- | HTML の < > & をエスケープする.
htmlEsc :: String -> String
htmlEsc = concatMap f
  where
    f '<' = "&lt;"; f '>' = "&gt;"; f '&' = "&amp;"; f c = [c]

-- | 辺リストに登場する命題を (rank, column) 昇順に並べる.
propsSorted :: [Edge] -> [Prop]
propsSorted es =
  sortBy (comparing (\p -> (propRank p, propColumn p)))
    $ nub $ concatMap (\e -> [edgeFrom e, edgeTo e]) es

-- | 辺を (fromRank, fromCol, toRank, toCol, kind) 順にソートする.
edgesSorted :: [Edge] -> [Edge]
edgesSorted = sortBy $ comparing $ \e ->
  ( propRank   (edgeFrom e), propColumn (edgeFrom e)
  , propRank   (edgeTo   e), propColumn (edgeTo   e)
  , edgeKind e
  )

-- | ✓ / ✗ / ? バッジ (span つき).
kindBadge :: EdgeKind -> String
kindBadge Proved    = "<span class=\"proved\">✓</span>"
kindBadge Separated = "<span class=\"sep\">✗</span>"
kindBadge Open      = "<span class=\"open\">?</span>"

-- | 全ページ共通 CSS.
commonCss :: String
commonCss = unlines
  [ "body { font-family: sans-serif; margin: 2em; background: #fafafa; color: #222; }"
  , "h1 { font-size: 1.5em; margin-bottom: 0.2em; }"
  , "h2 { font-size: 1.15em; border-bottom: 1px solid #ccc; padding-bottom: 0.2em; margin-top: 1.2em; }"
  , "p  { color: #555; margin: 0.3em 0 0.9em; }"
  , ".proved { color: #1a7a1a; font-weight: bold; }"
  , ".sep    { color: #cc2222; font-weight: bold; }"
  , ".open   { color: #cc7700; font-weight: bold; }"
  ]

-- ============================================================================
-- A: 含意行列 (HTML)
-- ============================================================================

-- | 命題 × 命題の含意行列を HTML テーブルとして生成する.
--
-- 行 = from（前件）, 列 = to（後件）.
-- 同じペアに複数辺がある場合（文脈違いの成立と反例など）はすべて列挙する.
renderMatrix :: [Edge] -> String
renderMatrix es = unlines
  [ "<!DOCTYPE html>"
  , "<html lang=\"ja\"><head><meta charset=\"UTF-8\">"
  , "<title>G2-Zoo: 含意行列</title>"
  , "<style>"
  , commonCss
  , "table { border-collapse: collapse; }"
  , "th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: center; white-space: nowrap; font-size: 0.9em; }"
  , "th { background: #f0f0f0; }"
  , "td.diag { background: #e0e0e0; }"
  , "td.empty { color: #bbb; }"
  , "dl.legend { margin-top: 1.5em; }"
  , "dl.legend dt { font-weight: bold; float: left; width: 1.6em; }"
  , "dl.legend dd { margin: 0 0 0.3em 2em; }"
  , "</style></head><body>"
  , "<h1>G2-Zoo: 含意行列</h1>"
  , "<p>行 = from, 列 = to。同一ペアに複数の文脈がある場合はすべて表示する。</p>"
  , matrixTable props es
  , "<dl class=\"legend\">"
  , "<dt class=\"proved\">✓</dt><dd>含意が成立する（文脈を付記）</dd>"
  , "<dt class=\"sep\">✗</dt><dd>反例が存在する（文脈を付記）</dd>"
  , "<dt class=\"open\">?</dt><dd>未解決</dd>"
  , "<dt style=\"color:#bbb\">—</dt><dd>辺なし</dd>"
  , "</dl>"
  , "</body></html>"
  ]
  where
    props = propsSorted es

matrixTable :: [Prop] -> [Edge] -> String
matrixTable props es = unlines $
  [ "<table><thead>"
  , "<tr><th>↓ from / to →</th>"
    ++ concatMap (\p -> "<th>" ++ htmlEsc (propLabel p) ++ "</th>") props
    ++ "</tr></thead><tbody>"
  ]
  ++ [ matrixRow from props es | from <- props ]
  ++ [ "</tbody></table>" ]

matrixRow :: Prop -> [Prop] -> [Edge] -> String
matrixRow from props es =
  "<tr><th>" ++ htmlEsc (propLabel from) ++ "</th>"
  ++ concatMap (matrixCell from es) props
  ++ "</tr>"

matrixCell :: Prop -> [Edge] -> Prop -> String
matrixCell from es to
  | from == to = "<td class=\"diag\">—</td>"
  | null rel   = "<td class=\"empty\">—</td>"
  | otherwise  = "<td>" ++ intercalate "<br>" (map fmtEntry rel) ++ "</td>"
  where
    rel = [ e | e <- es, edgeFrom e == from, edgeTo e == to ]
    fmtEntry e =
      kindBadge (edgeKind e) ++ "&thinsp;"
      ++ "<small>" ++ htmlEsc (contextLabel (edgeCtx e)) ++ "</small>"

-- ============================================================================
-- B: 反例モデルカード (HTML)
-- ============================================================================

-- | Sep クエリを実行し、各反例モデルを HTML カード形式で並べたページを生成する.
renderCounterexamplesHtml :: [Query] -> IO String
renderCounterexamplesHtml qs = do
  cards <- mapM mkCard sepQs
  return $ unlines
    [ "<!DOCTYPE html>"
    , "<html lang=\"ja\"><head><meta charset=\"UTF-8\">"
    , "<title>G2-Zoo: 反例モデルカード</title>"
    , "<style>"
    , commonCss
    , ".card { background: white; border: 1px solid #ddd; border-radius: 6px;"
    , "        padding: 0.9em 1.3em; margin: 0.8em 0; max-width: 660px; }"
    , ".card h2 { font-size: 1.0em; margin: 0 0 0.5em; color: #222; border: none; padding: 0; }"
    , "pre.model { background: #f4f4f4; padding: 0.6em 0.9em; border-radius: 4px;"
    , "            font-family: monospace; font-size: 0.88em; margin: 0; line-height: 1.5; }"
    , ".warn { color: #cc7700; font-style: italic; margin: 0; }"
    , "</style></head><body>"
    , "<h1>G2-Zoo: 反例モデルカード</h1>"
    , "<p>" ++ show (length sepQs) ++ " 件の分離問題について"
      ++ " <code>searchSeparation</code> が発見した最小反例モデルを示す。</p>"
    , unlines cards
    , "</body></html>"
    ]
  where
    sepQs = filter ((== Sep) . queryExpect) qs

mkCard :: Query -> IO String
mkCard q = do
  result <- queryRun q
  return $ case result of
    Nothing -> unlines
      [ "<article class=\"card\">"
      , "  <h2>" ++ htmlEsc (queryName q) ++ "</h2>"
      , "  <p class=\"warn\">担体内で反例が見つかりませんでした。</p>"
      , "</article>"
      ]
    Just model -> unlines
      [ "<article class=\"card\">"
      , "  <h2>" ++ htmlEsc (queryName q) ++ "</h2>"
      , "  <pre class=\"model\">" ++ htmlEsc model ++ "</pre>"
      , "</article>"
      ]

-- ============================================================================
-- C: 格子図 HTML (zoo-proved.svg 参照 + 全辺注釈テーブル)
-- ============================================================================

-- | 正の含意格子図（zoo-proved.svg）と全辺の注釈テーブルを並べた HTML を生成する.
--
-- SVG ファイルは同ディレクトリの @zoo-proved.svg@ を参照するので、
-- あらかじめ @stack exec g2-zoo -- proved@ を実行しておく必要がある。
renderLatticeHtml :: [Edge] -> String
renderLatticeHtml es = unlines
  [ "<!DOCTYPE html>"
  , "<html lang=\"ja\"><head><meta charset=\"UTF-8\">"
  , "<title>G2-Zoo: 格子図ビュー</title>"
  , "<style>"
  , commonCss
  , ".layout { display: flex; gap: 2.5em; align-items: flex-start; flex-wrap: wrap; }"
  , ".diagram { flex: 0 0 auto; background: white; border: 1px solid #ddd;"
  , "           border-radius: 6px; padding: 1em 1.2em; }"
  , ".diagram object, .diagram img { display: block; max-width: 500px; height: auto; }"
  , ".sidebar { flex: 1 1 320px; }"
  , "table { border-collapse: collapse; width: 100%; }"
  , "th, td { border: 1px solid #ccc; padding: 4px 8px; font-size: 0.85em; }"
  , "th { background: #f0f0f0; white-space: nowrap; }"
  , "td.note { color: #666; font-size: 0.8em; max-width: 160px; }"
  , "tr.proved-row { background: #f0fff0; }"
  , "tr.sep-row    { background: #fff4f4; }"
  , "tr.open-row   { background: #fffbf0; }"
  , "</style></head><body>"
  , "<h1>G2-Zoo: 格子図ビュー</h1>"
  , "<div class=\"layout\">"
  , "  <div class=\"diagram\">"
  , "    <h2>正の含意（格子図）</h2>"
  , "    <object data=\"zoo-proved.svg\" type=\"image/svg+xml\">"
  , "      <img src=\"zoo-proved.svg\" alt=\"proved-only lattice\">"
  , "    </object>"
  , "    <p style=\"font-size:0.8em;color:#888;margin-top:0.5em\">"
  , "      実線 = 成立した含意</p>"
  , "  </div>"
  , "  <div class=\"sidebar\">"
  , "    <h2>辺の一覧（全種別）</h2>"
  , edgeTable es
  , "  </div>"
  , "</div>"
  , "</body></html>"
  ]

edgeTable :: [Edge] -> String
edgeTable es = unlines $
  [ "<table>"
  , "<thead><tr>"
  , "<th>種</th><th>from</th><th>to</th><th>文脈</th><th>注記</th>"
  , "</tr></thead><tbody>"
  ]
  ++ map edgeRow (edgesSorted es)
  ++ [ "</tbody></table>" ]

edgeRow :: Edge -> String
edgeRow e =
  "<tr class=\"" ++ rowCls ++ "\">"
  ++ "<td>" ++ kindBadge (edgeKind e) ++ "</td>"
  ++ "<td>" ++ htmlEsc (propLabel (edgeFrom e)) ++ "</td>"
  ++ "<td>" ++ htmlEsc (propLabel (edgeTo   e)) ++ "</td>"
  ++ "<td>" ++ htmlEsc (contextLabel (edgeCtx e)) ++ "</td>"
  ++ "<td class=\"note\">" ++ htmlEsc (if null (edgeNote e) then "—" else edgeNote e) ++ "</td>"
  ++ "</tr>"
  where
    rowCls = case edgeKind e of
      Proved    -> "proved-row"
      Separated -> "sep-row"
      Open      -> "open-row"
