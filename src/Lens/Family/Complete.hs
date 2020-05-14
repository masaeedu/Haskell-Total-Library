{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE TypeOperators     #-}
{-# LANGUAGE CPP               #-}

module Lens.Family.Complete
    ( Full(..)
    , GFull(..) -- TODO: Why isn't GEmpty exported from the other module?
    , _cocase
    , at

    -- * Re-exports
    , (&)
    , (&&&)
    ) where

#if __GLASGOW_HASKELL__ >= 710
import Data.Functor.Identity
import Data.Function ((&))
#endif
import Control.Arrow ((&&&))
import GHC.Generics

-- A typeclass for trivially inhabited types
class Full a where
    trivial :: x -> a

    default trivial :: (Generic a, GFull (Rep a)) => x -> a
    trivial = to . gtrivial

instance Full () where
    trivial = const ()

instance (Full a, Full b) => Full (a, b) where
    trivial = trivial &&& trivial

instance Full a => Full (Either a b) where
    trivial = Left . trivial

class GFull f where
    gtrivial :: x -> f a

instance GFull U1 where
    gtrivial = const U1

instance (GFull a, GFull b) => GFull (a :*: b) where
    gtrivial x = gtrivial x :*: gtrivial x

instance Full a => GFull (K1 i a) where
    gtrivial = K1 . trivial

instance GFull a => GFull (M1 i c a) where
    gtrivial = M1 . gtrivial

instance GFull a => GFull (a :+: b) where
    gtrivial = L1 . gtrivial

-- | Synonym for `trivial`, used to check if a copattern is complete
_cocase :: Full a => x -> a
_cocase = trivial

-- TODO: Figure out whether the reference to Lens.Family.etc needs fixing, the module seems to be missing
-- | Copattern match on a `Lens.Family.Traversal`
at
    :: ((() -> Identity b) -> s -> Identity t)
    -> (i -> b)
    -> (i -> s)
    -> i
    -> t
at p f g = convert p . (f &&& g)
  where
  convert p (b, s) = runIdentity $ p (const $ Identity $ b) s

-- TODO: Figure out whether this needs to be in a common module
#if __GLASGOW_HASKELL__ < 710
-- | The identity functor
newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity
  where
  fmap f (Identity a) = Identity $ f a

instance Applicative Identity where
    pure = Identity
    Identity f <*> Identity a = Identity $ f a

-- | Operator for post-fix function application
(&) :: a -> (a -> b) -> b
x & f = f x
infixl 1 &
#endif
