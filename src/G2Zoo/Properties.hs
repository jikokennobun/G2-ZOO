-- | 型クラスインスタンスに対する公理・命題の検査.
--
-- 各述語は内部的に "G2Zoo.Search" の APSData-ベース実装に委譲する.
-- これにより有限モデル探索と同じロジックを再利用できる.
module G2Zoo.Properties
  ( -- * 公理の検査
    checkA1
  , checkA2
  , checkA3
  , checkA4
  , checkA4'
  , checkAllAPSAxioms
    -- * 命題の検査
  , checkConsistency
  , checkG2
  , checkFG2
  , checkWFG2
  , checkFLoeb
  , checkLoeb
  , checkHasDiamFP
  , checkHasBoxFP
    -- * ImpAPS の検査
  , checkImpInternalization
    -- * モデルの要約
  , Report (..)
  , reportOn
  ) where

import Data.Proxy (Proxy)

import G2Zoo.APS
import G2Zoo.PreOrder
import G2Zoo.Search

-- | A1: @x ≤ y ⇒ □x ≤ □y ∧ ☒y ≤ ☒x@.
checkA1 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkA1 = apsA1 . fromInstance

-- | A2: @⊤ ≤ ☒⊥@.
checkA2 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkA2 = apsA2 . fromInstance

-- | A3: @x ≤ □y ∧ x ≤ ☒y ⇒ x ≤ ☒⊤@.
checkA3 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkA3 = apsA3 . fromInstance

-- | A4: @☒x ≤ □☒x@.
checkA4 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkA4 = apsA4 . fromInstance

-- | A4': @□x ≤ □□x@.
checkA4' :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkA4' = apsA4' . fromInstance

-- | A1-A4 すべて.
checkAllAPSAxioms :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkAllAPSAxioms = apsAllAxioms . fromInstance

-- | 無矛盾性 @¬(⊤ ≤ ⊥)@.
checkConsistency :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkConsistency = apsConsistent . fromInstance

-- | G2.
checkG2 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkG2 = apsG2 . fromInstance

-- | FG2.
checkFG2 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkFG2 = apsFG2 . fromInstance

-- | WFG2: @☒⊤ ≤ ⊥ ⇒ ☒☒⊤ ≤ ⊥@.
checkWFG2 :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkWFG2 = apsWFG2 . fromInstance

-- | FLoeb: @∀x. □□x ≤ □x@.
checkFLoeb :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkFLoeb = apsFLoeb . fromInstance

-- | Löb 規則.
checkLoeb :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkLoeb = apsLoeb . fromInstance

-- | ☒-不動点の存在.
checkHasDiamFP :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkHasDiamFP = apsHasDiamFP . fromInstance

-- | □-不動点の存在.
checkHasBoxFP :: (PreAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkHasBoxFP = apsHasBoxFP . fromInstance

-- | ImpAPS の内在化条件 @⊤ ≤ x→y ⟺ x ≤ y@ を型クラスで検査する.
checkImpInternalization :: forall a. (ImpAPS a, Bounded a, Enum a) => Proxy a -> Bool
checkImpInternalization _ = and
  [ (top `leq` imp x y) == leq x y
  | x <- universe :: [a]
  , y <- universe :: [a]
  ]

-- | 与えられた APS モデルに対する公理・命題の充足表.
data Report = Report
  { reportName        :: String
  , reportA1          :: Bool
  , reportA2          :: Bool
  , reportA3          :: Bool
  , reportA4          :: Bool
  , reportA4Prime     :: Bool
  , reportConsistent  :: Bool
  , reportG2          :: Bool
  , reportWFG2        :: Bool
  , reportFG2         :: Bool
  , reportFLoeb       :: Bool
  , reportLoeb        :: Bool
  , reportHasDiamFP   :: Bool
  , reportHasBoxFP    :: Bool
  } deriving (Eq, Show)

-- | 名前と型引数を渡してモデルの 'Report' を計算する.
reportOn :: (PreAPS a, Bounded a, Enum a) => String -> Proxy a -> Report
reportOn name p = Report
  { reportName       = name
  , reportA1         = checkA1 p
  , reportA2         = checkA2 p
  , reportA3         = checkA3 p
  , reportA4         = checkA4 p
  , reportA4Prime    = checkA4' p
  , reportConsistent = checkConsistency p
  , reportG2         = checkG2 p
  , reportWFG2       = checkWFG2 p
  , reportFG2        = checkFG2 p
  , reportFLoeb      = checkFLoeb p
  , reportLoeb       = checkLoeb p
  , reportHasDiamFP  = checkHasDiamFP p
  , reportHasBoxFP   = checkHasBoxFP p
  }
