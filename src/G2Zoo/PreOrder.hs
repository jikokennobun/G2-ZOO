-- | 前順序および単項演算子付き前順序の型クラス階層.
--
-- APS (Abstract Provability Structure) を組み立てるための土台.
-- ここで定義する各クラスは「メソッドのみ」を提供し,
-- 反射律・推移律・単調性などの代数法則は意図的に型クラス制約から外している.
-- 法則の充足は "G2Zoo.Properties" の述語で個別のモデル上で検査する.
module G2Zoo.PreOrder
  ( -- * 前順序
    PreOrder (..)
  , equiv
  , universe
    -- * 単項演算子
  , Box (..)
  , Diamond (..)
  , Mono (..)
  ) where

-- | 前順序 (反射律と推移律を満たすことを意図する) を表す型クラス.
--
-- @leq x y@ で @x ≤ y@ を表現する.
-- @top@ は最大要素候補 @⊤@, @bot@ は最小要素候補 @⊥@ を表す.
-- ただし APS の文脈では @x ≤ ⊤@ や @⊥ ≤ x@ は仮定しないので,
-- これらは「区別された 2 元」程度の意味しかない.
class Eq a => PreOrder a where
  leq :: a -> a -> Bool
  top :: a
  bot :: a

-- | 前順序に基づく同値関係 @x =_s y :⇔ x ≤ y ∧ y ≤ x@.
equiv :: PreOrder a => a -> a -> Bool
equiv x y = leq x y && leq y x

-- | 有限な台集合の列挙. APS の公理や命題を全数検査するときに使う.
universe :: (Bounded a, Enum a) => [a]
universe = [minBound .. maxBound]

-- | 証明可能性演算子 @□@.
class PreOrder a => Box a where
  box :: a -> a

-- | 反証可能性演算子 @☒@.
class PreOrder a => Diamond a where
  diam :: a -> a

-- | 単調性を持つ汎用単項演算子 (Box / Diamond と独立に使いたい時のため).
class PreOrder a => Mono a where
  mono :: a -> a
