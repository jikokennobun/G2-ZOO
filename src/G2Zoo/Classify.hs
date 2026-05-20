-- | 有限担体上の全モデルを命題プロファイルで分類するデータベース生成器.
module G2Zoo.Classify
  ( PropProfile (..)
  , ModelRecord (..)
  , ProfileGroup (..)
  , propCols
  , classifyModels
  , groupByProfile
  , renderClassifyHtml
  ) where

import Data.List (groupBy, intercalate, sortBy)
import Data.Ord  (Down (..), comparing)

import G2Zoo.Search

-- ============================================================================
-- 型定義
-- ============================================================================

-- | 命題プロファイル: 全命題の充足状況をまとめたレコード.
data PropProfile = PropProfile
  { ppA1    :: Bool  -- A1
  , ppA2    :: Bool  -- A2
  , ppA3    :: Bool  -- A3
  , ppA4    :: Bool  -- A4
  , ppA4p   :: Bool  -- A4'
  , ppCons  :: Bool  -- Consistent
  , ppG2    :: Bool  -- G2
  , ppWFG2  :: Bool  -- WFG2
  , ppFG2   :: Bool  -- FG2
  , ppFLoeb :: Bool  -- FLoeb
  , ppLoeb  :: Bool  -- Loeb
  , ppDFP   :: Bool  -- ∃☒-FP
  , ppBFP   :: Bool  -- ∃□-FP
  } deriving (Eq, Ord)

-- | 命題列の定義 (表示名, data属性ID, accessor).
propCols :: [(String, String, PropProfile -> Bool)]
propCols =
  [ ("A1",     "a1",    ppA1)
  , ("A2",     "a2",    ppA2)
  , ("A3",     "a3",    ppA3)
  , ("A4",     "a4",    ppA4)
  , ("A4'",    "a4p",   ppA4p)
  , ("Cons",   "cons",  ppCons)
  , ("G2",     "g2",    ppG2)
  , ("WFG2",   "wfg2",  ppWFG2)
  , ("FG2",    "fg2",   ppFG2)
  , ("FLoeb",  "floeb", ppFLoeb)
  , ("Loeb",   "loeb",  ppLoeb)
  , ("∃☒-FP", "dfp",   ppDFP)
  , ("∃□-FP", "bfp",   ppBFP)
  ]

-- | 1件のモデルとその命題プロファイル.
data ModelRecord = ModelRecord
  { mrCarrier  :: String
  , mrUniverse :: [Int]
  , mrBox      :: [Int]   -- ^ □(u) を universe の順に並べたリスト
  , mrDiam     :: [Int]   -- ^ ☒(u) を universe の順に並べたリスト
  , mrProfile  :: PropProfile
  }

-- | 同一プロファイルを持つモデルのグループ.
data ProfileGroup = ProfileGroup
  { pgProfile :: PropProfile
  , pgCount   :: Int
  , pgRep     :: ModelRecord  -- ^ 代表モデル (辞書順最小)
  }

-- ============================================================================
-- 分類関数
-- ============================================================================

profileOf :: APSData Int -> PropProfile
profileOf m = PropProfile
  { ppA1    = apsA1         m
  , ppA2    = apsA2         m
  , ppA3    = apsA3         m
  , ppA4    = apsA4         m
  , ppA4p   = apsA4'        m
  , ppCons  = apsConsistent m
  , ppG2    = apsG2         m
  , ppWFG2  = apsWFG2       m
  , ppFG2   = apsFG2        m
  , ppFLoeb = apsFLoeb      m
  , ppLoeb  = apsLoeb       m
  , ppDFP   = apsHasDiamFP  m
  , ppBFP   = apsHasBoxFP   m
  }

toRecord :: Carrier Int -> APSData Int -> ModelRecord
toRecord c m = ModelRecord
  { mrCarrier  = cName c
  , mrUniverse = u
  , mrBox      = map (dBox  m) u
  , mrDiam     = map (dDiam m) u
  , mrProfile  = profileOf m
  }
  where u = cUniverse c

-- | 担体上の全モデルを分類する.
classifyModels :: Carrier Int -> [ModelRecord]
classifyModels c = map (toRecord c) (enumerateModels c)

-- | 同一プロファイルでグループ化し、件数降順に並べる.
groupByProfile :: [ModelRecord] -> [ProfileGroup]
groupByProfile rs =
  sortBy (comparing (Down . pgCount)) $
  map summarize $
  groupBy sameP $
  sortBy (comparing mrProfile) rs
  where
    sameP a b   = mrProfile a == mrProfile b
    summarize g = ProfileGroup
      { pgProfile = mrProfile (head g)
      , pgCount   = length g
      , pgRep     = head g
      }

-- ============================================================================
-- HTML レンダリング
-- ============================================================================

htmlEsc :: String -> String
htmlEsc = concatMap f
  where
    f '<' = "&lt;"; f '>' = "&gt;"; f '&' = "&amp;"
    f '"' = "&quot;"; f c = [c]

-- | (担体名, 総モデル数, プロファイルグループ) のリストから HTML を生成する.
renderClassifyHtml :: [(String, Int, [ProfileGroup])] -> String
renderClassifyHtml sections = unlines $
  [ "<!DOCTYPE html>"
  , "<html lang=\"ja\"><head>"
  , "<meta charset=\"UTF-8\">"
  , "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
  , "<title>G2-Zoo: 有限モデル分類データベース</title>"
  , "<style>" ++ css ++ "</style>"
  , "</head><body>"
  , "<h1>G2-Zoo: 有限モデル分類データベース</h1>"
  , "<p>各担体上の全モデルを命題プロファイルでグループ化。"
  , "列ヘッダーでソート、フィルタボタンで絞り込みができます。</p>"
  , "<nav class=\"tab-bar\">"
  ] ++
  [ "  <button class=\"tab-btn" ++ (if i == 0 then " active" else "")
    ++ "\" onclick=\"switchTab('" ++ secId i ++ "',this)\">"
    ++ htmlEsc name ++ "</button>"
  | (i, (name, _, _)) <- zip [(0 :: Int)..] sections
  ] ++
  [ "</nav>" ] ++
  concatMap renderSection (zip [(0 :: Int)..] sections) ++
  [ "<script>" ++ js ++ "</script>"
  , "</body></html>"
  ]
  where
    secId i = "sec" ++ show (i :: Int)

    renderSection (i, (name, total, groups)) =
      let sid   = "sec" ++ show (i :: Int)
          nProf = length groups
      in
      [ "<section id=\"" ++ sid ++ "\" class=\"tab-pane"
        ++ (if i == 0 then " active" else "") ++ "\">"
      , "<h2>" ++ htmlEsc name ++ "</h2>"
      , "<p>全 " ++ show total ++ " モデル &nbsp;|&nbsp; "
        ++ "<span id=\"vis-" ++ sid ++ "\">" ++ show nProf ++ "</span> / "
        ++ show nProf ++ " プロファイルを表示中</p>"
      , renderFilterBar sid
      , renderTable sid groups
      , "</section>"
      ]

renderFilterBar :: String -> String
renderFilterBar sid = unlines $
  [ "<div class=\"filter-bar\" id=\"fb-" ++ sid ++ "\">"
  , "  <span class=\"filter-label\">フィルタ:</span>"
  ] ++
  [ "  <button class=\"fp-btn axiom-btn\" data-sid=\"" ++ sid
    ++ "\" data-prop=\"" ++ pid ++ "\" onclick=\"cycleFilter(this)\">"
    ++ htmlEsc label ++ "</button>"
  | (label, pid, _) <- take 5 propCols  -- A1..A4'
  ] ++
  [ "  <span class=\"filter-sep\">|</span>" ] ++
  [ "  <button class=\"fp-btn prop-btn\" data-sid=\"" ++ sid
    ++ "\" data-prop=\"" ++ pid ++ "\" onclick=\"cycleFilter(this)\">"
    ++ htmlEsc label ++ "</button>"
  | (label, pid, _) <- drop 5 propCols  -- Cons..∃□-FP
  ] ++
  [ "  <button class=\"reset-btn\" onclick=\"resetFilters('" ++ sid ++ "')\">リセット</button>"
  , "</div>"
  ]

renderTable :: String -> [ProfileGroup] -> String
renderTable sid groups = unlines $
  [ "<div class=\"table-wrap\">"
  , "<table id=\"tbl-" ++ sid ++ "\">"
  , "<thead><tr>"
  , "  <th></th>"
  ] ++
  [ "  <th class=\"sortable" ++ grpCls col ++ "\" onclick=\"sortTable('tbl-"
    ++ sid ++ "'," ++ show (col + 1) ++ ")\">"
    ++ htmlEsc label ++ "</th>"
  | (col, (label, _, _)) <- zip [(0 :: Int)..] propCols
  ] ++
  [ "  <th class=\"sortable count-hdr\" onclick=\"sortTable('tbl-"
    ++ sid ++ "'," ++ show (length propCols + 1) ++ ")\">件数</th>"
  , "</tr></thead>"
  , "<tbody>"
  ] ++
  concatMap (renderGroupRow sid) (zip [(0 :: Int)..] groups) ++
  [ "</tbody></table></div>" ]
  where
    grpCls c
      | c < 5    = " axiom-hdr"
      | otherwise = " prop-hdr"

renderGroupRow :: String -> (Int, ProfileGroup) -> [String]
renderGroupRow sid (rowIdx, pg) =
  let rowId  = sid ++ "_r" ++ show rowIdx
      detId  = sid ++ "_d" ++ show rowIdx
      p      = pgProfile pg
      rep    = pgRep pg
      dataAttrs = concatMap
        (\(_, pid, acc) -> " data-" ++ pid ++ "=\"" ++ (if acc p then "1" else "0") ++ "\"")
        propCols
      showTbl u vs = intercalate ", " [ show x ++ "↦" ++ show v | (x,v) <- zip u vs ]
  in
  [ "<tr id=\"" ++ rowId ++ "\" class=\"group-row\"" ++ dataAttrs ++ ">"
  , "  <td><button class=\"xbtn\" onclick=\"toggleDetail('" ++ detId ++ "',this)\">▶</button></td>"
  ] ++
  [ "  <td class=\"pc " ++ (if acc p then "yes" else "no") ++ "\">"
    ++ (if acc p then "✓" else "✗") ++ "</td>"
  | (_, _, acc) <- propCols
  ] ++
  [ "  <td class=\"cnt\">" ++ show (pgCount pg) ++ "</td>"
  , "</tr>"
  , "<tr id=\"" ++ detId ++ "\" class=\"det-row\" style=\"display:none\">"
  , "  <td colspan=\"" ++ show (length propCols + 2) ++ "\">"
  , "    <div class=\"det-box\">"
  , "      <b>代表モデル</b> — 担体: " ++ htmlEsc (mrCarrier rep)
  , "      &nbsp; ⊥=" ++ show (head (mrUniverse rep))
    ++ " ⊤=" ++ show (last (mrUniverse rep))
  , "      <br>□ : " ++ htmlEsc (showTbl (mrUniverse rep) (mrBox  rep))
  , "      <br>☒ : " ++ htmlEsc (showTbl (mrUniverse rep) (mrDiam rep))
  , "    </div>"
  , "  </td>"
  , "</tr>"
  ]

-- ============================================================================
-- CSS
-- ============================================================================

css :: String
css = concat
  [ "* { box-sizing: border-box; }"
  , "body { background: #fff; color: #111;"
  , "       font-family: system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", \"Noto Sans JP\", Meiryo, sans-serif;"
  , "       line-height: 1.55; margin: 0 auto; max-width: 1100px; padding: 1em 2em 3em; }"
  , "h1 { font-size: 1.3em; margin: 0.3em 0 0.5em; }"
  , "h2 { font-size: 1.1em; margin-top: 0.5em; border-bottom: 1px solid #000; padding-bottom: 0.1em; }"
  , "p  { margin: 0.2em 0 0.5em; }"
  , ".tab-bar { display: flex; flex-wrap: wrap; gap: 0.25em; margin: 0.7em 0 0;"
  , "           border-bottom: 2px solid #000; }"
  , ".tab-btn { padding: 0.2em 0.7em; border: 1px solid #000; border-bottom: none;"
  , "           background: #fff; cursor: pointer; font-family: inherit; font-size: 0.9em; }"
  , ".tab-btn.active { background: #eee; font-weight: bold; }"
  , ".tab-pane { display: none; padding-top: 0.5em; }"
  , ".tab-pane.active { display: block; }"
  , ".filter-bar { display: flex; flex-wrap: wrap; gap: 0.3em; align-items: center;"
  , "              margin-bottom: 0.5em; padding: 0.3em 0;"
  , "              border-top: 1px solid #ccc; border-bottom: 1px solid #ccc; }"
  , ".filter-label { font-size: 0.9em; }"
  , ".filter-sep { margin: 0 0.2em; }"
  , ".fp-btn { padding: 0.1em 0.4em; border: 1px solid #999; cursor: pointer;"
  , "          font-family: inherit; background: #fff; font-size: 0.85em; }"
  , ".fp-btn.state-yes { color: #060; font-weight: bold; border-color: #060; }"
  , ".fp-btn.state-no  { color: #900; font-weight: bold; border-color: #900; text-decoration: line-through; }"
  , ".reset-btn { padding: 0.1em 0.4em; border: 1px solid #999; cursor: pointer;"
  , "             font-family: inherit; background: #fff; font-size: 0.85em; margin-left: auto; }"
  , ".table-wrap { overflow-x: auto; }"
  , "table { border-collapse: collapse; font-size: 0.88em; }"
  , "th, td { border: 1px solid #ccc; padding: 2px 5px; text-align: center; white-space: nowrap; }"
  , "th { background: #f5f5f5; }"
  , "th.sortable { cursor: pointer; user-select: none; }"
  , "th.sortable:hover { text-decoration: underline; }"
  , ".pc.yes { color: #060; font-weight: bold; }"
  , ".pc.no  { color: #900; }"
  , ".cnt { font-weight: bold; }"
  , ".xbtn { background: none; border: none; cursor: pointer; padding: 0 3px; }"
  , ".group-row:hover > td { background: #f5f5f5; }"
  , ".det-row td { background: #f5f5f5; text-align: left; }"
  , ".det-box { padding: 0.4em 1em; font-family: monospace; }"
  , "@media print { body { max-width: none; padding: 0.8cm; font-size: 9pt; }"
  , "  .tab-bar, .filter-bar { display: none; } .tab-pane { display: block; page-break-before: always; }"
  , "  .tab-pane:first-of-type { page-break-before: auto; } .det-row { display: none !important; }"
  , "  table { width: 100%; font-size: 8pt; } h1 { font-size: 16pt; } h2 { font-size: 12pt; }"
  , "  a { color: #000; text-decoration: none; } }"
  ]

-- ============================================================================
-- JavaScript
-- ============================================================================

js :: String
js = concat
  [ "function switchTab(id,btn){"
  , "  document.querySelectorAll('.tab-pane').forEach(p=>p.classList.remove('active'));"
  , "  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));"
  , "  document.getElementById(id).classList.add('active');"
  , "  btn.classList.add('active');}"
  , "var fs={};"
  , "function cycleFilter(btn){"
  , "  var k=btn.dataset.sid+':'+btn.dataset.prop;"
  , "  fs[k]=((fs[k]||0)+1)%3;"
  , "  btn.classList.remove('state-yes','state-no');"
  , "  if(fs[k]===1)btn.classList.add('state-yes');"
  , "  else if(fs[k]===2)btn.classList.add('state-no');"
  , "  applyFilters(btn.dataset.sid);}"
  , "function resetFilters(sid){"
  , "  document.querySelectorAll('#fb-'+sid+' .fp-btn').forEach(b=>{"
  , "    fs[sid+':'+b.dataset.prop]=0;"
  , "    b.classList.remove('state-yes','state-no');});"
  , "  applyFilters(sid);}"
  , "function applyFilters(sid){"
  , "  var vis=0;"
  , "  document.querySelectorAll('#tbl-'+sid+' tbody .group-row').forEach(function(row){"
  , "    var ok=true;"
  , "    document.querySelectorAll('#fb-'+sid+' .fp-btn').forEach(function(btn){"
  , "      var s=fs[sid+':'+btn.dataset.prop]||0;"
  , "      if(s===0)return;"
  , "      var v=row.dataset[btn.dataset.prop];"
  , "      if(s===1&&v!=='1')ok=false;"
  , "      if(s===2&&v!=='0')ok=false;});"
  , "    row.style.display=ok?'':'none';"
  , "    var det=document.getElementById(row.id.replace('_r','_d'));"
  , "    if(det&&!ok)det.style.display='none';"
  , "    if(ok)vis++;});"
  , "  var el=document.getElementById('vis-'+sid);"
  , "  if(el)el.textContent=vis;}"
  , "var sd={};"
  , "function sortTable(tid,col){"
  , "  var k=tid+':'+col, asc=!sd[k]; sd[k]=asc;"
  , "  var tbody=document.getElementById(tid).querySelector('tbody');"
  , "  var rows=Array.from(tbody.querySelectorAll('.group-row'));"
  , "  rows.sort(function(a,b){"
  , "    var av=a.cells[col].textContent.trim();"
  , "    var bv=b.cells[col].textContent.trim();"
  , "    var an=parseFloat(av),bn=parseFloat(bv);"
  , "    if(!isNaN(an)&&!isNaN(bn))return asc?an-bn:bn-an;"
  , "    return asc?av.localeCompare(bv):bv.localeCompare(av);});"
  , "  rows.forEach(function(row){"
  , "    tbody.appendChild(row);"
  , "    var det=document.getElementById(row.id.replace('_r','_d'));"
  , "    if(det)tbody.appendChild(det);});}"
  , "function toggleDetail(id,btn){"
  , "  var row=document.getElementById(id);"
  , "  var hidden=(row.style.display==='none'||row.style.display==='');"
  , "  row.style.display=hidden?'table-row':'none';"
  , "  btn.textContent=hidden?'▼':'▶';}"
  ]
