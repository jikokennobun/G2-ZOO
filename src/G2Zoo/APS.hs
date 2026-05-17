-- | APS (Abstract Provability Structure) とその近縁構造の型クラス階層.
--
-- Beklemishev & Shamkanov (2016) "Some abstract versions of Gödel's second
-- incompleteness theorem based on non-classical logics" に従う.
--
-- 階層 (上位ほど強い):
--
-- @
--   FixedPointAPS    LoebAPS       ImpAPS
--          \\            |            /
--           +---- APS ----+
--                 |
--               PreAPS
--                 |
--           Box, Diamond
--                 |
--             PreOrder
-- @
--
-- 公理 A1-A4 や Loeb 条件は型クラスの法則として宣言だけ行い,
-- 充足検査は "G2Zoo.Properties" 側で行う.
module G2Zoo.APS
  ( PreAPS
  , APS
  , FixedPointAPS (..)
  , BoxFixedPointAPS (..)
  , LoebAPS
  , ImpAPS (..)
  ) where

import G2Zoo.PreOrder

-- | Box と Diamond の両方を持つ前順序. APS の土台.
class (Box a, Diamond a) => PreAPS a

-- | APS. 公理 A1-A4 を満たすことを意図する.
--
-- * A1: @x ≤ y ⇒ □x ≤ □y ∧ ☒y ≤ ☒x@ (単調性 / 反単調性)
-- * A2: @⊤ ≤ ☒⊥@
-- * A3: @x ≤ □y ∧ x ≤ ☒y ⇒ x ≤ ☒⊤@
-- * A4: @☒x ≤ □☒x@
class PreAPS a => APS a

-- | ☒-不動点 @p =_s ☒p@ を持つ PreAPS.
--
-- B&S 2016 の主定理は @APS + FixedPointAPS@ を要請する.
-- ここでは APS 公理を独立に検査したいため基底を 'PreAPS' に弱めている.
class PreAPS a => FixedPointAPS a where
  diamFixedPoint :: a

-- | □-不動点 @p =_s □p@ を持つ PreAPS. ゲーデル型 (Gödel-style) 不動点に対応.
class PreAPS a => BoxFixedPointAPS a where
  boxFixedPoint :: a

-- | Löb 規則 @□x ≤ x ⇒ ⊤ ≤ x@ を満たすことを宣言するマーカ.
--
-- 法則は型では保証せず, 'G2Zoo.Properties' の述語で検査する.
class PreAPS a => LoebAPS a

-- | 含意 (→) を持つ APS. @x → y@ は @x ≤ y@ の内在化を意図する.
--
-- 期待される性質 (検査側で確認):
--
-- * @T ≤ x → y \<=\> x ≤ y@   (内在化)
-- * @□(x → y) → (□x → □y) ≤_s ⊤@  (D2 風)
class APS a => ImpAPS a where
  imp :: a -> a -> a
