-- | 代数構造の型クラス階層.
--
-- APS (G2Zoo.APS) の土台となる PreOrder に加え, 二項演算を持つ代数構造を提供する.
-- Haskell 標準の 'Semigroup'/'Monoid' との名前衝突を避けるため,
-- 本プロジェクト固有の名前 (語尾 @G@) を用いる.
--
-- 階層の概観:
--
-- @
--   HeytingAlgebra          -- 含意付き有界分配束
--         |
--   BoundedLattice          -- 有界束 (MeetSemilattice + JoinSemilattice)
--      /      \\
--   MeetSemilattice   JoinSemilattice
--         |
--      PreOrder              -- G2Zoo.PreOrder の前順序と連結
--
--   GroupG                  -- 群
--     |
--   MonoidG                 -- 単位元付き結合的マグマ
--     |
--   Associative             -- 結合的マグマ
--     |
--   Magma                   -- 閉じた二項演算
-- @
--
-- 代数的領域 ('IsCompact') は将来の拡張のためのスタブ.
module G2Zoo.Algebra
  ( -- * 群様構造
    Magma (..)
  , Associative
  , CommutativeMagma
  , MonoidG (..)
  , GroupG (..)
    -- * 束構造
  , MeetSemilattice (..)
  , JoinSemilattice (..)
  , BoundedLattice
    -- * Heyting 代数
  , HeytingAlgebra (..)
    -- * 代数的領域スタブ
  , IsCompact (..)
    -- * 有限モデル上の整合性検査
  , checkAssoc
  , checkComm
  , checkMonoidLaws
  , checkGroupLaws
  , checkMeetSemilattice
  , checkJoinSemilattice
  , checkHeytingResiduation
  ) where

import G2Zoo.PreOrder

-- ============================================================================
-- 群様構造
-- ============================================================================

-- | マグマ: 閉じた二項演算 @⊕@ を持つ代数構造.
--
-- 法則は課さない. 結合律は 'Associative', 可換律は 'CommutativeMagma' で宣言.
class Magma a where
  oper :: a -> a -> a

-- | 結合的マグマのマーカ.
--
-- 期待される法則: @oper (oper x y) z = oper x (oper y z)@.
-- 法則は型では強制せず, 'checkAssoc' で有限モデル上を検査する.
class Magma a => Associative a

-- | 可換マグマのマーカ.
--
-- 期待される法則: @oper x y = oper y x@.
class Magma a => CommutativeMagma a

-- | 単位元付きモノイド.
--
-- 期待される法則: @oper unitG x = x@, @oper x unitG = x@.
class Associative a => MonoidG a where
  unitG :: a

-- | 群: 逆元を持つモノイド.
--
-- 期待される法則: @oper x (invG x) = unitG@, @oper (invG x) x = unitG@.
class MonoidG a => GroupG a where
  invG :: a -> a

-- ============================================================================
-- 束構造
-- ============================================================================

-- | 交わり半束 (Meet-semilattice).
--
-- 期待される法則:
-- @meet x x = x@ (冪等), @meet x y = meet y x@ (可換),
-- @meet x (meet y z) = meet (meet x y) z@ (結合).
-- さらに @x ≤ y ⟺ meet x y = x@ (PreOrder との整合性).
class PreOrder a => MeetSemilattice a where
  meet :: a -> a -> a

-- | 結び半束 (Join-semilattice).
--
-- 期待される法則:
-- @join x x = x@ (冪等), @join x y = join y x@ (可換),
-- @join x (join y z) = join (join x y) z@ (結合).
-- さらに @x ≤ y ⟺ join x y = y@ (PreOrder との整合性).
class PreOrder a => JoinSemilattice a where
  join :: a -> a -> a

-- | 有界束: 交わりと結びを持ち, ⊤ と ⊥ を最大元・最小元とする.
class (MeetSemilattice a, JoinSemilattice a) => BoundedLattice a

-- | Heyting 代数: 有界分配束 + 含意 @x → y@ (残留演算).
--
-- 残留条件: @x ≤ y → z ⟺ x ∧ y ≤ z@ が期待される.
--
-- APS の 'G2Zoo.APS.ImpAPS' における内在化条件 @⊤ ≤ x→y ⟺ x ≤ y@ は,
-- meet が定義できない構造 (前順序のみ) でも意味を持つ点で残留とは異なる.
-- 線形順序上では両者は一致する.
class BoundedLattice a => HeytingAlgebra a where
  himp :: a -> a -> a

-- ============================================================================
-- 代数的領域スタブ
-- ============================================================================

-- | コンパクト元の述語.
--
-- 代数的領域 (algebraic domain) = dcpo + コンパクト生成系 に向けたスタブ.
-- 連続束・Scott 位相・Way-below 関係の完全形式化は将来の課題.
class PreOrder a => IsCompact a where
  isCompact :: a -> Bool

-- ============================================================================
-- 有限モデル上の整合性検査
-- ============================================================================

-- | 結合律の有限検査: @∀x,y,z. oper (oper x y) z = oper x (oper y z)@.
checkAssoc :: (Magma a, Eq a) => [a] -> Bool
checkAssoc xs = and
  [ oper (oper x y) z == oper x (oper y z)
  | x <- xs, y <- xs, z <- xs
  ]

-- | 可換律の有限検査: @∀x,y. oper x y = oper y x@.
checkComm :: (Magma a, Eq a) => [a] -> Bool
checkComm xs = and [ oper x y == oper y x | x <- xs, y <- xs ]

-- | 単位元律の有限検査: @∀x. oper unitG x = x ∧ oper x unitG = x@.
checkMonoidLaws :: (MonoidG a, Eq a) => [a] -> Bool
checkMonoidLaws xs = and
  [ oper unitG x == x && oper x unitG == x
  | x <- xs
  ]

-- | 逆元律の有限検査: @∀x. oper x (invG x) = unitG ∧ oper (invG x) x = unitG@.
checkGroupLaws :: (GroupG a, Eq a) => [a] -> Bool
checkGroupLaws xs = and
  [ oper x (invG x) == unitG && oper (invG x) x == unitG
  | x <- xs
  ]

-- | 交わり半束律の有限検査 (冪等・可換・結合 + PreOrder 整合性).
checkMeetSemilattice :: MeetSemilattice a => [a] -> Bool
checkMeetSemilattice xs = and $
  [ meet x x == x                             -- 冪等
  | x <- xs ]
  ++
  [ meet x y == meet y x                      -- 可換
  | x <- xs, y <- xs ]
  ++
  [ meet x (meet y z) == meet (meet x y) z    -- 結合
  | x <- xs, y <- xs, z <- xs ]
  ++
  [ leq (meet x y) x && leq (meet x y) y      -- meet は下界
  | x <- xs, y <- xs ]

-- | 結び半束律の有限検査 (冪等・可換・結合 + PreOrder 整合性).
checkJoinSemilattice :: JoinSemilattice a => [a] -> Bool
checkJoinSemilattice xs = and $
  [ join x x == x                             -- 冪等
  | x <- xs ]
  ++
  [ join x y == join y x                      -- 可換
  | x <- xs, y <- xs ]
  ++
  [ join x (join y z) == join (join x y) z    -- 結合
  | x <- xs, y <- xs, z <- xs ]
  ++
  [ leq x (join x y) && leq y (join x y)      -- join は上界
  | x <- xs, y <- xs ]

-- | Heyting 残留の有限検査: @x ≤ y → z ⟺ meet x y ≤ z@.
checkHeytingResiduation :: HeytingAlgebra a => [a] -> Bool
checkHeytingResiduation xs = and
  [ leq x (himp y z) == leq (meet x y) z
  | x <- xs, y <- xs, z <- xs
  ]
