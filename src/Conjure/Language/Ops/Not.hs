{-# LANGUAGE DeriveGeneric, DeriveDataTypeable, DeriveFunctor, DeriveTraversable, DeriveFoldable #-}

module Conjure.Language.Ops.Not where

import Conjure.Prelude
import Conjure.Language.Ops.Common


data OpNot x = OpNot x
    deriving (Eq, Ord, Show, Data, Functor, Traversable, Foldable, Typeable, Generic)

instance Serialize x => Serialize (OpNot x)
instance Hashable  x => Hashable  (OpNot x)
instance ToJSON    x => ToJSON    (OpNot x) where toJSON = genericToJSON jsonOptions
instance FromJSON  x => FromJSON  (OpNot x) where parseJSON = genericParseJSON jsonOptions

instance TypeOf x => TypeOf (OpNot x) where
    typeOf (OpNot a) = do TypeBool <- typeOf a ; return TypeBool

instance EvaluateOp OpNot where
    evaluateOp (OpNot x) = ConstantBool . not <$> boolOut x

instance SimplifyOp OpNot where
    simplifyOp _ _ = na "simplifyOp{OpNot}"

instance Pretty x => Pretty (OpNot x) where
    prettyPrec _ (OpNot a) = "!" <> prettyPrec 10000 a
