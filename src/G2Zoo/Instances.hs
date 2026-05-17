-- | 具体的な有限 APS モデル.
--
-- seminar2 メモの Case1-4 をそのままインスタンスとして実装する.
--
-- 各 'Case_n' は基底集合として 'Value3' (3 点線形順序) を持ち,
-- 同じ ≤ の上に異なる □/☒ の組み合わせを与える.
-- 'Value3' は L_Id とそのまま対応するが Case4 のみ □ を恒等から外す.
module G2Zoo.Instances
  ( -- * 基底
    Value3 (..)
    -- * 線形 3 点モデル
  , Linear3 (..)
    -- * seminar2 の Case 達
  , Case1 (..)
  , Case2 (..)
  , Case3 (..)
  , Case4 (..)
    -- * 退化モデル
  , Trivial2 (..)
    -- * ImpAPS: Gödel 含意ラッパー
  , Case1Godel (..)
    -- * WFG2 ⇏ FG2 反例モデル (4点線形)
  , Value4 (..)
  , L4Id (..)
  ) where

import G2Zoo.APS
import G2Zoo.PreOrder

-- | 3 点線形順序の基底集合. @V3Bot < V3Mid < V3Top@.
data Value3 = V3Bot | V3Mid | V3Top
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | 単純な L_Id ベースの 3 点線形順序 (□ も ☒ も恒等). APS にはならない.
newtype Linear3 = Linear3 { unLinear3 :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Linear3 where
  leq (Linear3 a) (Linear3 b) = a <= b
  top = Linear3 V3Top
  bot = Linear3 V3Bot

instance Box Linear3 where
  box = id

instance Diamond Linear3 where
  diam = id

instance PreAPS Linear3

-- | Case1: A1-A4 を満たし G2 を満たすが FG2 を満たさないモデル.
--
-- @
--     ☒
--   ⊤ a
--   a ⊤
--   ⊥ ⊤
-- @
newtype Case1 = Case1 { unCase1 :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Case1 where
  leq (Case1 a) (Case1 b) = a <= b
  top = Case1 V3Top
  bot = Case1 V3Bot

instance Box Case1 where
  box = id

instance Diamond Case1 where
  diam (Case1 V3Top) = Case1 V3Mid
  diam (Case1 V3Mid) = Case1 V3Top
  diam (Case1 V3Bot) = Case1 V3Top

instance PreAPS Case1
instance APS    Case1

-- | Case2: A1-A4 を満たし G2 を満たすが ☒-不動点を持たないモデル.
--
-- Case1 と同型の構造を別名で持つ (seminar2 では Case1 と同表).
newtype Case2 = Case2 { unCase2 :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Case2 where
  leq (Case2 a) (Case2 b) = a <= b
  top = Case2 V3Top
  bot = Case2 V3Bot

instance Box Case2 where
  box = id

instance Diamond Case2 where
  diam (Case2 V3Top) = Case2 V3Mid
  diam (Case2 V3Mid) = Case2 V3Top
  diam (Case2 V3Bot) = Case2 V3Top

instance PreAPS Case2
instance APS    Case2

-- | Case3: A1, A2, A4 を満たし ☒-不動点を持つが FG2 を満たさないモデル.
--
-- @
--     ☒
--   ⊤ ⊥
--   a a
--   ⊥ ⊤
-- @
--
-- A3 は外れている (これが ∃☒-不動点 ⇒ FG2 を分離する).
newtype Case3 = Case3 { unCase3 :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Case3 where
  leq (Case3 a) (Case3 b) = a <= b
  top = Case3 V3Top
  bot = Case3 V3Bot

instance Box Case3 where
  box = id

instance Diamond Case3 where
  diam (Case3 V3Top) = Case3 V3Bot
  diam (Case3 V3Mid) = Case3 V3Mid
  diam (Case3 V3Bot) = Case3 V3Top

instance PreAPS Case3

instance FixedPointAPS Case3 where
  diamFixedPoint = Case3 V3Mid

-- | Case4: A1-A3 + ∃☒-不動点を満たすが A4 を満たさず A4' は満たすモデル.
-- A4 と A4' の差を分離する.
--
-- @
--     □ ☒
--   ⊤ ⊥ ⊥
--   a ⊥ a
--   ⊥ ⊥ ⊤
-- @
newtype Case4 = Case4 { unCase4 :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Case4 where
  leq (Case4 a) (Case4 b) = a <= b
  top = Case4 V3Top
  bot = Case4 V3Bot

instance Box Case4 where
  box _ = Case4 V3Bot

instance Diamond Case4 where
  diam (Case4 V3Top) = Case4 V3Bot
  diam (Case4 V3Mid) = Case4 V3Mid
  diam (Case4 V3Bot) = Case4 V3Top

instance PreAPS Case4

instance FixedPointAPS Case4 where
  diamFixedPoint = Case4 V3Mid

-- | 2 点退化モデル ({⊥, ⊤}, ⊥ < ⊤, □ = id, ☒ ≡ ⊥).
-- (☆) 反例モデル (Syntactical Result メモの (1), (3), (5), (6), (9), (10)).
data Trivial2 = T2Bot | T2Top
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Trivial2 where
  leq a b = a <= b
  top = T2Top
  bot = T2Bot

instance Box Trivial2 where
  box = id

instance Diamond Trivial2 where
  diam _ = T2Bot

instance PreAPS Trivial2

-- ============================================================================
-- ImpAPS インスタンス: Case1 担体 (3点線形) での含意演算の比較
-- ============================================================================

-- | Case1 に Łukasiewicz 含意 @x → y = min(⊤, ⊤ − x + y)@ を付加する.
--
-- {V3Bot=0, V3Mid=1, V3Top=2} で @min(2, 2−x+y)@ を計算する.
instance ImpAPS Case1 where
  imp (Case1 x) (Case1 y) =
    Case1 $ toEnum (min 2 (2 - fromEnum x + fromEnum y))

-- | Case1 と同じ APS 構造を持ち, Gödel 含意 @x → y = ⊤@ if @x ≤ y@, else @y@
-- を採用したラッパー型.
--
-- 内在化条件 @⊤ ≤ x→y ⟺ x ≤ y@ を Łukasiewicz と比較するためのモデル.
newtype Case1Godel = Case1Godel { unCase1Godel :: Value3 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder Case1Godel where
  leq (Case1Godel a) (Case1Godel b) = a <= b
  top = Case1Godel V3Top
  bot = Case1Godel V3Bot

instance Box Case1Godel where
  box = id

instance Diamond Case1Godel where
  diam (Case1Godel V3Top) = Case1Godel V3Mid
  diam (Case1Godel V3Mid) = Case1Godel V3Top
  diam (Case1Godel V3Bot) = Case1Godel V3Top

instance PreAPS Case1Godel
instance APS    Case1Godel

instance ImpAPS Case1Godel where
  imp x y
    | leq x y   = top
    | otherwise = y

-- ============================================================================
-- WFG2 ⇏ FG2 反例モデル: 4点線形, □=id
-- ============================================================================

-- | 4点線形順序の基底集合. @V4Bot < V4A < V4B < V4Top@.
data Value4 = V4Bot | V4A | V4B | V4Top
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | L4Id: WFG2 は満たすが FG2 を満たさない APS モデル.
--
-- □ = id, ☒⊤=a, ☒b=a, ☒a=b, ☒⊥=⊤.
-- WFG2 の前提 ☒⊤=a > ⊥ なので WFG2 は空虚に真.
-- FG2: ☒☒⊤ = ☒a = b, ☒⊤ = a, b ≤ a は偽 → FG2 失敗.
newtype L4Id = L4Id { unL4Id :: Value4 }
  deriving (Eq, Ord, Show, Enum, Bounded)

instance PreOrder L4Id where
  leq (L4Id a) (L4Id b) = a <= b
  top = L4Id V4Top
  bot = L4Id V4Bot

instance Box L4Id where
  box = id

instance Diamond L4Id where
  diam (L4Id V4Top) = L4Id V4A
  diam (L4Id V4B)   = L4Id V4A
  diam (L4Id V4A)   = L4Id V4B
  diam (L4Id V4Bot) = L4Id V4Top

instance PreAPS L4Id
instance APS    L4Id
