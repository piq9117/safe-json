{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-orphans #-}
module Instances (
    DotNetTime()
  , DList()
  , VP.Vector()
  , Value()
  ) where


import Data.Aeson
#if MIN_VERSION_aeson(2,0,0)
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
#endif
import Data.DList (DList, fromList, toList)
import Data.Int (Int64)
import Data.Time (NominalDiffTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import qualified Data.Vector.Primitive as VP

#if MIN_VERSION_base(4,13,0)
import Test.Tasty.QuickCheck (oneof, resize)
#else
import Test.Tasty.QuickCheck (Arbitrary(..), oneof, resize)
#endif
import Test.QuickCheck.Arbitrary.Generic
import Test.QuickCheck.Instances()

instance Arbitrary DotNetTime where
  arbitrary = do
      diff <- arbitrary
      -- DotNetTime is only accurate to the millisecond
      let floored = (/ 1000)
                  . fromIntegral
                  . (floor :: NominalDiffTime -> Int64)
                  $ (diff :: NominalDiffTime) * 1000
      return $ DotNetTime $ posixSecondsToUTCTime floored
  shrink = fmap DotNetTime . shrink . fromDotNetTime

instance Arbitrary a => Arbitrary (DList a) where
  arbitrary = fromList <$> arbitrary
  shrink = fmap fromList . shrink . toList

instance (Arbitrary a, VP.Prim a) => Arbitrary (VP.Vector a) where
  arbitrary = VP.fromList <$> arbitrary
  shrink = fmap VP.fromList . shrink . VP.toList

instance Arbitrary Value where
  arbitrary = oneof
    [ resize 5 $ Object <$> arbitrary
    , resize 5 $ Array <$> arbitrary
    , String <$> arbitrary
    , Number <$> arbitrary
    , Bool <$> arbitrary
    , pure Null
    ]
  shrink = genericShrink

#if !MIN_VERSION_aeson(1,5,2)
-- | This is here just to test 'Set' in 'parseCollection'
instance Ord Value where
  Null `compare` Null = EQ
  Null `compare` _    = LT
  _    `compare` Null = GT
  a `compare` b
    | Bool   a' <- a, Bool   b' <- b = a' `compare` b'
    | Number a' <- a, Number b' <- b = a' `compare` b'
    | String a' <- a, String b' <- b = a' `compare` b'
    | Array  a' <- a, Array  b' <- b = a' `compare` b'
    | Object a' <- a, Object b' <- b = a' `compare` b'
  Bool{}   `compare` _      = LT
  Number{} `compare` Bool{} = GT
  Number{} `compare` _      = LT
  String{} `compare` Bool{}   = GT
  String{} `compare` Number{} = GT
  String{} `compare` _        = LT
  Array{}  `compare` Object{} = LT
  _        `compare` _        = GT
#endif

#if MIN_VERSION_aeson(2,0,0)
instance Arbitrary v => Arbitrary (KM.KeyMap v) where
    arbitrary = KM.fromList <$> arbitrary

instance Arbitrary K.Key where
    arbitrary = K.fromText <$> arbitrary
#endif
