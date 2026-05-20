-- | 名前付き有限モデルの一覧とその構成方法を HTML で生成する.
module G2Zoo.Guide
  ( NamedModel (..)
  , mkNamedModel
  , renderGuideHtml
  ) where

import Data.Proxy (Proxy (..))

import G2Zoo.APS
import G2Zoo.PreOrder
import G2Zoo.Properties

-- ============================================================================
-- データ型
-- ============================================================================

-- | 名前・説明・担体・□☒テーブル・命題レポートをまとめたモデル記述.
data NamedModel = NamedModel
  { nmName    :: String
  , nmDesc    :: String        -- ^ 数学的意義の説明
  , nmCarrier :: String        -- ^ 担体名 (表示用)
  , nmUniv    :: [Int]         -- ^ 台集合 (fromEnum した整数列)
  , nmTop     :: Int
  , nmBot     :: Int
  , nmBoxTbl  :: [Int]         -- ^ □ の値 (nmUniv と同じ順序)
  , nmDiamTbl :: [Int]         -- ^ ☒ の値 (nmUniv と同じ順序)
  , nmReport  :: Report
  }

-- | 型クラスインスタンスから NamedModel を構築する.
mkNamedModel
  :: forall a. (PreAPS a, Bounded a, Enum a)
  => String   -- ^ モデル名
  -> String   -- ^ 担体名 (例: "3点線形")
  -> String   -- ^ 説明
  -> Proxy a
  -> NamedModel
mkNamedModel name carrier desc _ = NamedModel
  { nmName    = name
  , nmDesc    = desc
  , nmCarrier = carrier
  , nmUniv    = u
  , nmTop     = fromEnum (top :: a)
  , nmBot     = fromEnum (bot :: a)
  , nmBoxTbl  = map (fromEnum . box)  elems
  , nmDiamTbl = map (fromEnum . diam) elems
  , nmReport  = reportOn name (Proxy :: Proxy a)
  }
  where
    elems = [minBound .. maxBound] :: [a]
    u     = map fromEnum elems

-- ============================================================================
-- HTML レンダリング
-- ============================================================================

htmlEsc :: String -> String
htmlEsc = concatMap f
  where
    f '<' = "&lt;"; f '>' = "&gt;"; f '&' = "&amp;"
    f '"' = "&quot;"; f c = [c]

-- | 台集合の整数を記号表記に変換する.
-- n点線形: 0=⊥, n-1=⊤, 中間は a,b,c,...
elemLabel :: Int -> Int -> String
elemLabel n i
  | i == 0     = "⊥"
  | i == n - 1 = "⊤"
  | otherwise  = [['a'..'z'] !! (i - 1)]

-- | NamedModel のリストから HTML ページを生成する.
renderGuideHtml :: [NamedModel] -> String
renderGuideHtml models = concat
  [ "<!DOCTYPE html>\n"
  , "<html lang=\"ja\"><head>\n"
  , "<meta charset=\"UTF-8\">\n"
  , "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n"
  , "<title>G2-Zoo: 有限 APS モデル構成ガイド</title>\n"
  , "<style>" , css , "</style>\n"
  , "</head><body>\n"
  , "<h1>G2-Zoo: 有限 APS モデル構成ガイド</h1>\n"
  , "<p>各モデルの □ / ☒ テーブル、命題の充足状況、数学的意義を一覧する。\n"
  , "公理は APS (A1–A4) を基準とし、追加の命題 (G2, FG2, Loeb 等) を色分けで示す。</p>\n"
  , legend
  , concatMap renderCard models
  , "</body></html>\n"
  ]

legend :: String
legend = concat
  [ "<div class=\"legend\">"
  , "<span class=\"badge aps\">APS</span> A1–A4 すべて成立 &nbsp;"
  , "<span class=\"badge preaps\">PreAPS</span> A1–A4 のうち一部成立 &nbsp;"
  , "<span class=\"badge noaps\">非APS</span> A1–A4 のいずれも不成立"
  , "</div>\n"
  ]

renderCard :: NamedModel -> String
renderCard m = concat
  [ "<div class=\"card " , cardCls , "\">\n"
  , "  <div class=\"card-hdr\">"
  , "<span class=\"mname\">" , htmlEsc (nmName m) , "</span>"
  , "<span class=\"carrier\">" , htmlEsc (nmCarrier m) , "</span>"
  , "<span class=\"badge " , cardCls , "\">" , badgeTxt , "</span>"
  , "</div>\n"
  , "  <p class=\"desc\">" , htmlEsc (nmDesc m) , "</p>\n"
  , "  <div class=\"body\">\n"
  , "    <div class=\"tbl-wrap\">\n"
  , renderOpTable m
  , "    </div>\n"
  , "    <div class=\"props-wrap\">\n"
  , renderProps m
  , "    </div>\n"
  , "  </div>\n"
  , "</div>\n"
  ]
  where
    r      = nmReport m
    isAps  = reportA1 r && reportA2 r && reportA3 r && reportA4 r
    isPre  = reportA1 r || reportA2 r || reportA3 r || reportA4 r
    cardCls | isAps  = "aps"
            | isPre  = "preaps"
            | otherwise = "noaps"
    badgeTxt | isAps  = "APS"
             | isPre  = "PreAPS"
             | otherwise = "非APS"

-- | □ / ☒ の演算テーブルを HTML table で生成する.
renderOpTable :: NamedModel -> String
renderOpTable m = concat
  [ "<table class=\"op-tbl\">\n"
  , "  <tr><th>x</th>"
    , concatMap (\i -> "<td>" ++ lbl i ++ "</td>") (nmUniv m)
    , "</tr>\n"
  , "  <tr><th>□<i>x</i></th>"
    , concatMap (\v -> "<td>" ++ lbl v ++ "</td>") (nmBoxTbl m)
    , "</tr>\n"
  , "  <tr><th>☒<i>x</i></th>"
    , concatMap (\v -> "<td>" ++ lbl v ++ "</td>") (nmDiamTbl m)
    , "</tr>\n"
  , "</table>\n"
  ]
  where
    n   = length (nmUniv m)
    lbl = elemLabel n

-- | 命題チップ列を生成する.
renderProps :: NamedModel -> String
renderProps m = concat
  [ "<div class=\"props\">\n"
  , concatMap chip propList
  , "</div>\n"
  ]
  where
    r = nmReport m
    propList =
      [ ("A1",     reportA1         r)
      , ("A2",     reportA2         r)
      , ("A3",     reportA3         r)
      , ("A4",     reportA4         r)
      , ("A4'",    reportA4Prime    r)
      , ("Cons",   reportConsistent r)
      , ("G2",     reportG2         r)
      , ("WFG2",   reportWFG2       r)
      , ("FG2",    reportFG2        r)
      , ("FLoeb",  reportFLoeb      r)
      , ("Loeb",   reportLoeb       r)
      , ("∃☒-FP", reportHasDiamFP  r)
      , ("∃□-FP", reportHasBoxFP   r)
      ]
    chip (name, True)  = "<span class=\"chip yes\">" ++ htmlEsc name ++ " ✓</span>\n"
    chip (name, False) = "<span class=\"chip no\">"  ++ htmlEsc name ++ " ✗</span>\n"

-- ============================================================================
-- CSS
-- ============================================================================

css :: String
css = concat
  [ "* { box-sizing: border-box; }"
  , "body { background: #fff; color: #111;"
  , "       font-family: system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", \"Noto Sans JP\", Meiryo, sans-serif;"
  , "       line-height: 1.55; margin: 0 auto; max-width: 950px; padding: 1em 2em 3em; }"
  , "h1 { font-size: 1.3em; margin: 0.3em 0 0.5em; }"
  , "p  { margin: 0.3em 0 0.7em; }"
  , ".legend { margin: 0.8em 0 1.2em; padding: 0.5em 0;"
  , "          border-top: 1px solid #000; border-bottom: 1px solid #000; font-size: 0.9em; }"
  , ".card { border-top: 1px solid #ccc; margin-bottom: 1em; padding-top: 0.6em; }"
  , ".card-hdr { display: flex; align-items: baseline; gap: 0.7em; flex-wrap: wrap; }"
  , ".mname { font-size: 1.05em; font-weight: bold; }"
  , ".carrier { font-size: 0.9em; color: #555; }"
  , ".badge { font-size: 0.8em; font-weight: bold; margin-left: auto; }"
  , ".badge.aps    { color: #060; }"
  , ".badge.preaps { color: #00a; }"
  , ".badge.noaps  { color: #777; }"
  , ".desc { font-size: 0.9em; margin: 0.3em 0 0; }"
  , ".body { display: flex; gap: 1em; padding: 0.5em 0 0.3em; flex-wrap: wrap; }"
  , ".tbl-wrap { flex: 0 0 auto; }"
  , ".op-tbl { border-collapse: collapse; font-size: 0.88em; }"
  , ".op-tbl th, .op-tbl td { border: 1px solid #ccc; padding: 2px 7px; text-align: center; min-width: 2em; }"
  , ".op-tbl th { background: #f5f5f5; }"
  , ".props-wrap { flex: 1 1 200px; }"
  , ".props { display: flex; flex-wrap: wrap; gap: 0.3em; align-content: flex-start; }"
  , ".chip { display: inline-block; padding: 0 0.4em; font-size: 0.8em; border: 1px solid #ccc; }"
  , ".chip.yes { color: #060; }"
  , ".chip.no  { color: #aaa; }"
  , "@media print { body { max-width: none; padding: 0.8cm; font-size: 10.5pt; }"
  , "  h1 { font-size: 16pt; } .card, table { break-inside: avoid; }"
  , "  a { color: #000; text-decoration: none; } }"
  ]
