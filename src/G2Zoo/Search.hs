-- | 有限 APS モデルの全列挙と反例探索.
--
-- 型クラス階層 (G2Zoo.APS) は \"利用者が法則を満たすと宣言する\" 経路だが,
-- 本モジュールは前順序を持つ有限台集合の上で \\(\\square\\) と \\(\\boxtimes\\) を全列挙し,
-- 与えられた前提条件を満たすが結論を満たさないモデルを機械的に発見する.
module G2Zoo.Search
  ( -- * 抽象モデル
    Carrier (..)
  , APSData (..)
  , fromInstance
    -- * 公理と命題 (APSData 上)
  , apsA1
  , apsA2
  , apsA3
  , apsA4
  , apsA4'
  , apsAllAxioms
  , apsConsistent
  , apsG2
  , apsFG2
  , apsWFG2
  , apsFLoeb
  , apsLoeb
  , apsHasDiamFP
  , apsHasBoxFP
    -- * 列挙と探索
  , allFunctions
  , enumerateModels
  , Hypothesis (..)
  , hyp
  , searchSeparation
    -- * 標準的な担体 (線形)
  , linearCarrier
  , linearCarrier2
  , linearCarrier3
  , linearCarrier4
  , linearCarrier5
    -- * 拡張担体 (非線形・部分順序)
  , diamondCarrier
  , m3Carrier
  , pentagonCarrier
    -- * モデルの表示
  , showModel
    -- * 含意付き APS データ
  , ImpAPSData (..)
  , apsImpInternalization
  , lukasiewiczImpData
  , godelImpData
    -- * 既定の分離問題
  , Query (..)
  , Expected (..)
  , defaultQueries
  ) where

import Control.Monad (replicateM)
import Data.List    (intercalate)
import Data.Maybe   (fromMaybe, listToMaybe)
import Data.Proxy   (Proxy (..))

import G2Zoo.APS
import G2Zoo.PreOrder

-- | 有限台集合と前順序 + 区別された 2 元 \\(\\top\\) / \\(\\bot\\) からなる「担体」.
data Carrier a = Carrier
  { cUniverse :: [a]
  , cLeq      :: a -> a -> Bool
  , cTop      :: a
  , cBot      :: a
  , cName     :: String  -- ^ 担体の識別名 (表示用)
  }

-- | 担体 + \\(\\square\\) + \\(\\boxtimes\\) からなる完全な APS データ. APS 公理は仮定しない.
data APSData a = APSData
  { dCarrier :: Carrier a
  , dBox     :: a -> a
  , dDiam    :: a -> a
  }

-- | 型クラスインスタンスから APSData を取り出す.
fromInstance :: forall a. (PreAPS a, Bounded a, Enum a) => Proxy a -> APSData a
fromInstance _ = APSData
  { dCarrier = Carrier
      { cUniverse = universe :: [a]
      , cLeq      = leq
      , cTop      = top
      , cBot      = bot
      , cName     = "型クラスインスタンス"
      }
  , dBox  = box
  , dDiam = diam
  }

-- ----------------------------------------------------------------------------
-- 公理 / 命題
-- ----------------------------------------------------------------------------

-- | A1: @x ≤ y ⇒ □x ≤ □y ∧ ☒y ≤ ☒x@.
apsA1 :: APSData a -> Bool
apsA1 m = and
  [ not (le x y) || (le (b x) (b y) && le (d y) (d x))
  | x <- u, y <- u
  ]
  where
    u  = cUniverse (dCarrier m)
    le = cLeq (dCarrier m)
    b  = dBox m
    d  = dDiam m

-- | A2: @⊤ ≤ ☒⊥@.
apsA2 :: APSData a -> Bool
apsA2 m = cLeq (dCarrier m) (cTop (dCarrier m)) (dDiam m (cBot (dCarrier m)))

-- | A3: @x ≤ □y ∧ x ≤ ☒y ⇒ x ≤ ☒⊤@.
apsA3 :: APSData a -> Bool
apsA3 m = and
  [ not (le x (b y) && le x (d y)) || le x (d (cTop c))
  | x <- u, y <- u
  ]
  where
    c  = dCarrier m
    u  = cUniverse c
    le = cLeq c
    b  = dBox m
    d  = dDiam m

-- | A4: @☒x ≤ □☒x@.
apsA4 :: APSData a -> Bool
apsA4 m = and [ le (d x) (b (d x)) | x <- u ]
  where
    c  = dCarrier m
    u  = cUniverse c
    le = cLeq c
    b  = dBox m
    d  = dDiam m

-- | A4': @□x ≤ □□x@ (D3, 様相公理 4).
apsA4' :: APSData a -> Bool
apsA4' m = and [ le (b x) (b (b x)) | x <- u ]
  where
    c  = dCarrier m
    u  = cUniverse c
    le = cLeq c
    b  = dBox m

-- | A1-A4 すべて.
apsAllAxioms :: APSData a -> Bool
apsAllAxioms m = apsA1 m && apsA2 m && apsA3 m && apsA4 m

-- | 無矛盾性 @¬(⊤ ≤ ⊥)@.
apsConsistent :: APSData a -> Bool
apsConsistent m = not (cLeq c (cTop c) (cBot c))
  where c = dCarrier m

-- | G2: @☒⊤ ≤ ⊥ ⇒ ⊤ ≤ ⊥@.
apsG2 :: APSData a -> Bool
apsG2 m = not (le (d (cTop c)) (cBot c)) || le (cTop c) (cBot c)
  where
    c  = dCarrier m
    le = cLeq c
    d  = dDiam m

-- | FG2: @☒☒⊤ ≤ ☒⊤@.
apsFG2 :: APSData a -> Bool
apsFG2 m = le (d (d (cTop c))) (d (cTop c))
  where
    c  = dCarrier m
    le = cLeq c
    d  = dDiam m

-- | WFG2: @☒⊤ ≤ ⊥ ⇒ ☒☒⊤ ≤ ⊥@. FG2 より弱く G2 より強い.
apsWFG2 :: APSData a -> Bool
apsWFG2 m = not (le (d (cTop c)) (cBot c)) || le (d (d (cTop c))) (cBot c)
  where
    c  = dCarrier m
    le = cLeq c
    d  = dDiam m

-- | FLoeb: @∀x. □□x ≤ □x@. G2 側の FG2 に対応する Loeb 側の定式化.
apsFLoeb :: APSData a -> Bool
apsFLoeb m = and [ le (b (b x)) (b x) | x <- u ]
  where
    c  = dCarrier m
    u  = cUniverse c
    le = cLeq c
    b  = dBox m

-- | Löb: @∀x. □x ≤ x ⇒ ⊤ ≤ x@.
apsLoeb :: APSData a -> Bool
apsLoeb m = and
  [ not (le (b x) x) || le (cTop c) x
  | x <- u
  ]
  where
    c  = dCarrier m
    u  = cUniverse c
    le = cLeq c
    b  = dBox m

-- | 同値関係 @x =_s y :⇔ x ≤ y ∧ y ≤ x@ の APSData 版.
dataEquiv :: APSData a -> a -> a -> Bool
dataEquiv m x y = le x y && le y x
  where le = cLeq (dCarrier m)

-- | ☒-不動点の存在 @∃p. p =_s ☒p@.
apsHasDiamFP :: APSData a -> Bool
apsHasDiamFP m = any (\p -> dataEquiv m p (dDiam m p)) (cUniverse (dCarrier m))

-- | □-不動点の存在 @∃p. p =_s □p@.
apsHasBoxFP :: APSData a -> Bool
apsHasBoxFP m = any (\p -> dataEquiv m p (dBox m p)) (cUniverse (dCarrier m))

-- ----------------------------------------------------------------------------
-- 列挙と探索
-- ----------------------------------------------------------------------------

-- | 有限集合 @xs@ から自分自身への関数を全列挙する. 個数は @|xs|^|xs|@.
allFunctions :: Eq a => [a] -> [a -> a]
allFunctions xs = [ mkFun (zip xs ys) | ys <- replicateM n xs ]
  where
    n = length xs
    mkFun tbl x = fromMaybe (error "allFunctions: input out of domain") (lookup x tbl)

-- | 担体を固定して \\(\\square\\) と \\(\\boxtimes\\) を全通り取った APS モデルを生成する.
enumerateModels :: Eq a => Carrier a -> [APSData a]
enumerateModels c =
  [ APSData c b d
  | b <- ops
  , d <- ops
  ]
  where
    ops = allFunctions (cUniverse c)

-- | 名前付きの仮説. 失敗時の説明に名前を使う.
data Hypothesis a = Hypothesis
  { hypName    :: String
  , hypChecker :: APSData a -> Bool
  }

-- | 'Hypothesis' を組み立てるヘルパ.
hyp :: String -> (APSData a -> Bool) -> Hypothesis a
hyp = Hypothesis

-- | 「前提達を満たすが結論を満たさない」モデルを探す.
--
-- 担体は固定. \\(\\square\\) と \\(\\boxtimes\\) を全列挙する.
searchSeparation
  :: Eq a
  => Carrier a
  -> [Hypothesis a]   -- ^ 仮定したい命題達
  -> Hypothesis a     -- ^ 反例を作りたい結論
  -> Maybe (APSData a)
searchSeparation c premises conclusion = listToMaybe
  [ m
  | m <- enumerateModels c
  , all (\h -> hypChecker h m) premises
  , not (hypChecker conclusion m)
  ]

-- ----------------------------------------------------------------------------
-- 標準的な担体
-- ----------------------------------------------------------------------------

-- | n 点線形順序 @{0, 1, ..., n-1}, ≤@ の担体.
linearCarrier :: Int -> Carrier Int
linearCarrier n = Carrier
  { cUniverse = [0 .. n - 1]
  , cLeq      = (<=)
  , cTop      = n - 1
  , cBot      = 0
  , cName     = show n ++ "点線形"
  }

linearCarrier2 :: Carrier Int
linearCarrier2 = linearCarrier 2

linearCarrier3 :: Carrier Int
linearCarrier3 = linearCarrier 3

linearCarrier4 :: Carrier Int
linearCarrier4 = linearCarrier 4

linearCarrier5 :: Carrier Int
linearCarrier5 = linearCarrier 5

-- | 4点ダイアモンド半順序 @{⊥, a, b, ⊤}@.
--
-- @0=⊥, 1=a, 2=b, 3=⊤@. @a@ と @b@ は比較不可能.
-- Hasse 図: ⊥ < a < ⊤, ⊥ < b < ⊤, a ∥ b.
diamondCarrier :: Carrier Int
diamondCarrier = Carrier
  { cUniverse = [0, 1, 2, 3]
  , cLeq      = \x y -> x == y || (x, y) `elem` [(0,1),(0,2),(0,3),(1,3),(2,3)]
  , cTop      = 3
  , cBot      = 0
  , cName     = "4点ダイアモンド"
  }

-- | 5点 M3 (非分配モジュラ束) @{⊥, a, b, c, ⊤}@.
--
-- @0=⊥, 1=a, 2=b, 3=c, 4=⊤@. @a, b, c@ は互いに比較不可能で,
-- すべて ⊥ と ⊤ の間にある.
m3Carrier :: Carrier Int
m3Carrier = Carrier
  { cUniverse = [0, 1, 2, 3, 4]
  , cLeq      = \x y -> x == y || x == 0 || y == 4
  , cTop      = 4
  , cBot      = 0
  , cName     = "5点M3"
  }

-- | 5点ペンタゴン (N5, 非モジュラ束) @{⊥, a, b, c, ⊤}@.
--
-- @0=⊥, 1=a, 2=b, 3=c, 4=⊤@. 鎖 @⊥ < a < c < ⊤@ と
-- 孤立原子 @⊥ < b < ⊤@ (@b@ は @a, c@ と比較不可能).
pentagonCarrier :: Carrier Int
pentagonCarrier = Carrier
  { cUniverse = [0, 1, 2, 3, 4]
  , cLeq      = \x y -> (x, y) `elem` pairs
  , cTop      = 4
  , cBot      = 0
  , cName     = "5点ペンタゴン(N5)"
  }
  where
    pairs = [ (x, x) | x <- [0..4] ]
         ++ [(0,1),(0,2),(0,3),(0,4)]
         ++ [(1,3),(1,4)]
         ++ [(2,4)]
         ++ [(3,4)]

-- ----------------------------------------------------------------------------
-- 表示
-- ----------------------------------------------------------------------------

-- | モデルを人間可読な形にする.
showModel :: Show a => APSData a -> String
showModel m = unlines
  [ "  担体: " ++ cName c ++ "  " ++ show (cUniverse c)
      ++ "  ⊥=" ++ show (cBot c) ++ " ⊤=" ++ show (cTop c)
  , "  □:  " ++ intercalate ", " [ show x ++ "↦" ++ show (dBox m x)  | x <- cUniverse c ]
  , "  ☒:  " ++ intercalate ", " [ show x ++ "↦" ++ show (dDiam m x) | x <- cUniverse c ]
  ]
  where c = dCarrier m

-- ----------------------------------------------------------------------------
-- 含意付き APS データ
-- ----------------------------------------------------------------------------

-- | 含意演算 @x → y@ を付加した APS データ.
--
-- 'iBase' の APS の上に, 内在化条件 @⊤ ≤ x→y ⟺ x ≤ y@ を意図した
-- 二項演算 'iImp' を追加する.
data ImpAPSData a = ImpAPSData
  { iBase :: APSData a
  , iImp  :: a -> a -> a
  }

-- | 内在化条件 @⊤ ≤ x→y ⟺ x ≤ y@ を検査する.
apsImpInternalization :: ImpAPSData a -> Bool
apsImpInternalization m = and
  [ le (cTop c) (i x y) == le x y
  | x <- u, y <- u
  ]
  where
    b  = iBase m
    c  = dCarrier b
    u  = cUniverse c
    le = cLeq c
    i  = iImp m

-- | Łukasiewicz 含意 @x → y = min(⊤, ⊤ − x + y)@ を付加する.
--
-- 担体の要素が整数で @⊤ = cTop@ の線形順序であることを仮定する.
lukasiewiczImpData :: APSData Int -> ImpAPSData Int
lukasiewiczImpData b = ImpAPSData
  { iBase = b
  , iImp  = \x y -> min t (t - x + y)
  }
  where t = cTop (dCarrier b)

-- | Gödel 含意 @x → y = ⊤@ if @x ≤ y@, else @y@ を付加する.
godelImpData :: APSData Int -> ImpAPSData Int
godelImpData b = ImpAPSData
  { iBase = b
  , iImp  = \x y -> if cLeq (dCarrier b) x y then cTop (dCarrier b) else y
  }

-- ----------------------------------------------------------------------------
-- 既定の分離問題集
-- ----------------------------------------------------------------------------

-- | 1 件の分離問題. 名前 + 担体 + 前提 + 結論 + 反例存在の期待.
data Query = Query
  { queryName     :: String
  , queryRun      :: IO (Maybe String)  -- ^ 実行結果の表示文字列
  , queryExpect   :: Expected
  }

-- | 期待結果. @Sep@ なら反例が見つかるはず, @NoSep@ なら見つからないはず.
data Expected = Sep | NoSep deriving (Eq, Show)

-- | 既定の分離問題集。seminar2 の Case1／Case3 の機械的再発見と、
-- A1 上の ∃☒-FP と FG2 の関係の検証を含む。
defaultQueries :: [Query]
defaultQueries =
  [ mkQuery "A1+A2+A3+A4 ⇒ FG2 (Case1 を再発見)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4 ]
      (hyp "FG2" apsFG2) Sep

  , mkQuery "A1+A2+A3+A4 ⇒ ∃☒-FP (Case2 を再発見)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4 ]
      (hyp "∃☒-FP" apsHasDiamFP) Sep

  , mkQuery "A1+A2+A4 + ∃☒-FP ⇒ FG2 (Case3 を再発見)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A4" apsA4
      , hyp "∃☒-FP" apsHasDiamFP
      ]
      (hyp "FG2" apsFG2) Sep

  , mkQuery "A1+A2+FG2 ⇒ G2 (Syntactical Fact: 反例なし)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "FG2" apsFG2 ]
      (hyp "G2" apsG2) NoSep

  , mkQuery "APS + ∃☒-FP ⇒ FG2 (B&S 2016: 反例なし)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
      , hyp "∃☒-FP" apsHasDiamFP
      ]
      (hyp "FG2" apsFG2) NoSep

  , mkQuery "APS + ∃☒-FP ⇒ G2 (B&S 2016: 反例なし)"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
      , hyp "∃☒-FP" apsHasDiamFP
      ]
      (hyp "G2" apsG2) NoSep

  -- A1 上の ∃☒-FP と FG2 の関係（利用者の主張: 一致するはず）
  , mkQuery "A1 ⇒ (FG2 ⇒ ∃☒-FP)  [3点線形]"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "FG2" apsFG2 ]
      (hyp "∃☒-FP" apsHasDiamFP) NoSep

  , mkQuery "A1 ⇒ (∃☒-FP ⇒ FG2)  [3点線形]"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "∃☒-FP" apsHasDiamFP ]
      (hyp "FG2" apsFG2) Sep

  -- ダイアモンド担体での B&S 主定理の確認と分離の再発見
  , mkQuery "APS + ∃☒-FP ⇒ FG2 [4点ダイアモンド]"
      diamondCarrier
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
      , hyp "∃☒-FP" apsHasDiamFP ]
      (hyp "FG2" apsFG2) NoSep

  , mkQuery "A1+A2+A3+A4 ⇒ FG2 [4点ダイアモンド]"
      diamondCarrier
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4 ]
      (hyp "FG2" apsFG2) Sep

  , mkQuery "A1+A2+A3+A4 ⇒ FG2 [5点線形]"
      linearCarrier5
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4 ]
      (hyp "FG2" apsFG2) Sep

  -- WFG2 関連: FG2 ⇒ WFG2 ⇒ G2 の確認と WFG2 ⇏ FG2 の反例
  , mkQuery "FG2 ⇒ WFG2 [3点線形]: 反例なし"
      linearCarrier3
      [ hyp "FG2" apsFG2 ]
      (hyp "WFG2" apsWFG2) NoSep

  , mkQuery "A1+A2+WFG2 ⇒ G2 [3点線形]: 反例なし"
      linearCarrier3
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "WFG2" apsWFG2 ]
      (hyp "G2" apsG2) NoSep

  , mkQuery "APS+WFG2 ⇏ FG2 [4点線形]: L4反例"
      linearCarrier4
      [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
      , hyp "WFG2" apsWFG2 ]
      (hyp "FG2" apsFG2) Sep
  ]
  where
    mkQuery name c ps q exp_ = Query
      { queryName = name
      , queryRun  = pure $
          case searchSeparation c ps q of
            Just m  -> Just (showModel m)
            Nothing -> Nothing
      , queryExpect = exp_
      }
