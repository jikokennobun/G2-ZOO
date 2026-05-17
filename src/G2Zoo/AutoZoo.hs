-- | 動物園の自動生成。
--
-- 命題のリストと文脈（公理の組）のリストから、各 (P, Q) ペアに対して
-- 「P が Q を含意するか」を有限モデル探索で機械的に判定し、
-- その結果から動物園の辺を構築する。
--
-- 既定の動作:
--
-- * P ⇒ Q が成立する最も弱い文脈を青の実線で表示
-- * P ⇒ Q が反例を持つ最も強い文脈を赤の点線で表示（成立する文脈も存在する場合のみ）
-- * すべての文脈で反例しか出ない場合は描かない（無情報な辺を減らす）
module G2Zoo.AutoZoo
  ( -- * データ型
    AutoProp (..)
  , AutoContext (..)
    -- * 推論
  , inferProved
  , buildAutoZoo
    -- * 既定リスト
  , defaultAutoProps
  , defaultAutoContexts
  ) where

import Data.Maybe (isNothing, listToMaybe)

import G2Zoo.APS  ()
import G2Zoo.Search
import G2Zoo.Zoo

-- | 動物園に並べる命題。
data AutoProp a = AutoProp
  { apName    :: String              -- ^ 表示用の名前
  , apEnum    :: Prop                -- ^ 動物園ノードへの対応
  , apChecker :: APSData a -> Bool   -- ^ APSData 上の述語
  }

-- | 仮定する公理セット（文脈）。
data AutoContext a = AutoContext
  { acCtx    :: Context              -- ^ 動物園ラベルへの対応
  , acAxioms :: [APSData a -> Bool]  -- ^ 仮定する公理
  }

-- | 与えられた担体と文脈で「from の述語＋公理 ⇒ to の述語」を検証する。
-- 反例が見つからなければ True（成立）、見つかれば False（反例あり）。
inferProved
  :: Eq a => Carrier a
  -> AutoContext a
  -> AutoProp a
  -> AutoProp a
  -> Bool
inferProved c ctx from to = isNothing $
  searchSeparation c hypotheses (hyp (apName to) (apChecker to))
  where
    hypotheses = [ Hypothesis "" ax | ax <- acAxioms ctx ]
              ++ [ hyp (apName from) (apChecker from) ]

-- | 全ペアの含意関係を機械的に判定し、動物園の辺リストを返す。
--
-- 視認性のためペア (P, Q) あたり辺は最大1本にする:
--
-- * 成立する文脈が1つ以上ある場合: 最も弱い文脈を Proved として1本だけ描く。
-- * すべての文脈で反例しか出ない場合: 最も強い文脈を Separated として1本だけ描く。
-- * 何も得られない場合: 辺を出さない。
buildAutoZoo
  :: Eq a => Carrier a
  -> [AutoContext a]
  -> [AutoProp a]
  -> [Edge]
buildAutoZoo c ctxs props =
  concatMap pairEdges
    [ (from, to) | from <- props, to <- props, apEnum from /= apEnum to ]
  where
    pairEdges (from, to) =
      let provedFirst = listToMaybe
            [ ctx | ctx <- ctxs, inferProved c ctx from to ]
          sepLast = listToMaybe
            [ ctx | ctx <- reverse ctxs, not (inferProved c ctx from to) ]
          mkEdge kind ctx =
            Edge (apEnum from) (apEnum to) (acCtx ctx) kind ""
      in case (provedFirst, sepLast) of
           (Just pc, _)       -> [ mkEdge Proved pc ]
           (Nothing, Just sc) -> [ mkEdge Separated sc ]
           (Nothing, Nothing) -> []

-- | 既定の命題リスト。不完全性現象の中心命題と WFG2 / FLoeb を含む。
defaultAutoProps :: [AutoProp Int]
defaultAutoProps =
  [ AutoProp "G2"     PG2          apsG2
  , AutoProp "WFG2"   PWFG2        apsWFG2
  , AutoProp "FG2"    PFG2         apsFG2
  , AutoProp "∃☒-FP" PHasDiamFP    apsHasDiamFP
  , AutoProp "FLoeb"  PFLoeb       apsFLoeb
  , AutoProp "Loeb"   PLoeb        apsLoeb
  ]

-- | 既定の文脈リスト。前にあるほど弱い（仮定が少ない）。
defaultAutoContexts :: [AutoContext Int]
defaultAutoContexts =
  [ AutoContext (CCustom "A1")       [ apsA1 ]
  , AutoContext (CCustom "A1+A2")    [ apsA1, apsA2 ]
  , AutoContext (CCustom "A1+A2+A4") [ apsA1, apsA2, apsA4 ]
  , AutoContext COverAPS             [ apsA1, apsA2, apsA3, apsA4 ]
  ]
