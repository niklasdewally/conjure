module Conjure.Representations.Function.Function1DPartial
    ( function1DPartial
    ) where

-- conjure
import Conjure.Prelude
import Conjure.Language.Definition
import Conjure.Language.Domain
import Conjure.Language.DomainSize
-- import Conjure.Language.Type
import Conjure.Language.TypeOf
import Conjure.Language.Lenses
import Conjure.Language.Pretty
import Conjure.Representations.Internal
import Conjure.Representations.Enum


function1DPartial :: MonadFail m => Representation m
function1DPartial = Representation chck downD structuralCons downC up

    where

        domainCanIndexMatrix DomainBool{} = True
        domainCanIndexMatrix DomainInt {} = True
        domainCanIndexMatrix DomainEnum{} = True
        domainCanIndexMatrix _            = False

        toIntDomain dom =
            case dom of
                DomainBool -> return (DomainInt [RangeBounded (fromInt 0) (fromInt 1)])
                DomainInt{} -> return dom
                DomainEnum{} -> do
                    Just [(_,domInt)] <- rDownD enum ("", dom)
                    return domInt
                _ -> fail ("toIntDomain, not supported:" <+> pretty dom)

        domainValues dom =
            case dom of
                DomainBool -> return [ConstantBool False, ConstantBool True]
                DomainInt rs -> map ConstantInt <$> valuesInIntDomain rs
                DomainEnum ename (Just (vals, [])) ->
                    return $ map (ConstantEnum ename vals) vals
                DomainEnum ename (Just (vals, rs)) -> do
                    let rsInt = map (fmap (ConstantInt . enumNameToInt vals)) rs
                    intVals <- valuesInIntDomain rsInt
                    return $ map (ConstantEnum ename vals . enumIntToName vals) intVals
                _ -> fail ("domainValues, not supported:" <+> pretty dom)

        chck f (DomainFunction _
                    attrs@(FunctionAttr _ FunctionAttr_Partial _)
                    innerDomainFr
                    innerDomainTo) | domainCanIndexMatrix innerDomainFr =
            DomainFunction "Function1DPartial" attrs
                <$> f innerDomainFr
                <*> f innerDomainTo
        chck _ _ = []

        nameFlags  name = mconcat [name, "_", "Function1DPartial_Flags"]
        nameValues name = mconcat [name, "_", "Function1DPartial_Values"]

        downD (name, DomainFunction "Function1DPartial"
                    (FunctionAttr _ FunctionAttr_Partial _)
                    innerDomainFr'
                    innerDomainTo) | domainCanIndexMatrix innerDomainFr' = do
            innerDomainFr <- toIntDomain innerDomainFr'
            return $ Just
                [ ( nameFlags name
                  , DomainMatrix
                      (forgetRepr innerDomainFr)
                      DomainBool
                  )
                , ( nameValues name
                  , DomainMatrix
                      (forgetRepr innerDomainFr)
                      innerDomainTo
                  )
                ]
        downD _ = fail "N/A {downD}"

        structuralCons (name, DomainFunction "Function1DPartial"
                    (FunctionAttr sizeAttr FunctionAttr_Partial jectivityAttr)
                    innerDomainFr'
                    innerDomainTo) | domainCanIndexMatrix innerDomainFr' = do
            innerDomainFr <- toIntDomain innerDomainFr'
            let flags = Reference (nameFlags name)
                              (Just (DeclHasRepr
                                          Find
                                          (nameFlags name)
                                          (DomainMatrix (forgetRepr innerDomainFr) DomainBool)))

            let values = Reference (nameValues name)
                              (Just (DeclHasRepr
                                          Find
                                          (nameValues name)
                                          (DomainMatrix (forgetRepr innerDomainFr) innerDomainTo)))

            innerDomainFrTy <- typeOf innerDomainFr
            innerDomainToTy <- typeOf innerDomainTo

            let injectiveCons  fresh = return $ -- list
                    let
                        iName = fresh `at` 0
                        jName = fresh `at` 1
                    in
                        -- forAll &i : &innerDomainFr .
                        --     forAll &j : &innerDomainTo .
                        --         &flags[&i] /\ &flags[&j] -> &values[&i] != &values[&j]
                        make opAnd [
                            make opMapOverDomain
                                (mkLambda iName innerDomainFrTy $ \ i ->
                                    make opAnd [
                                        make opMapOverDomain
                                            (mkLambda jName innerDomainToTy $ \ j ->
                                                make opImply
                                                    (make opAnd
                                                        [ make opIndexing flags i
                                                        , make opIndexing flags j
                                                        ])
                                                    (make opNeq
                                                        (make opIndexing values i)
                                                        (make opIndexing values j)
                                                    )
                                            )
                                            (Domain (forgetRepr innerDomainTo))
                                    ]
                                )
                                (Domain (forgetRepr innerDomainFr))
                        ]

            let surjectiveCons fresh = return $ -- list
                    let
                        iName = fresh `at` 0
                        jName = fresh `at` 1
                    in
                        -- forAll &i : &innerDomainTo .
                        --     exists &j : &innerDomainFr .
                        --         &flags[&j] /\ &values[&j] = &i
                        make opAnd [
                            make opMapOverDomain
                                (mkLambda iName innerDomainToTy $ \ i ->
                                    make opOr [
                                        make opMapOverDomain
                                            (mkLambda jName innerDomainFrTy $ \ j ->
                                                make opAnd
                                                    [ make opIndexing flags j
                                                    , make opEq (make opIndexing values j) i
                                                    ]
                                            )
                                            (Domain (forgetRepr innerDomainFr))
                                    ]
                                )
                                (Domain (forgetRepr innerDomainTo))       
                        ]

            let jectivityCons = case jectivityAttr of
                    ISBAttr_None       -> const []
                    ISBAttr_Injective  -> injectiveCons
                    ISBAttr_Surjective -> surjectiveCons
                    ISBAttr_Bijective  -> \ fresh -> injectiveCons fresh ++ surjectiveCons fresh

            let cardinality iName = make opSum [make opMapOverDomain
                                        (mkLambda iName innerDomainFrTy $ \ i ->
                                            make opToInt (make opIndexing flags i)
                                        )
                                        (Domain (forgetRepr innerDomainFr))
                                    ]

            let sizeCons fresh = case sizeAttr of
                    SizeAttrNone           -> []
                    SizeAttrSize x         -> [ make opEq  x (cardinality (headInf fresh)) ]
                    SizeAttrMinSize x      -> [ make opLeq x (cardinality (headInf fresh)) ]
                    SizeAttrMaxSize y      -> [ make opGeq y (cardinality (headInf fresh)) ]
                    SizeAttrMinMaxSize x y -> [ make opLeq x (cardinality (headInf fresh))
                                              , make opGeq y (cardinality (headInf fresh)) ]

            return $ Just $ \ fresh -> jectivityCons fresh ++ sizeCons fresh

        structuralCons _ = fail "N/A {structuralCons}"

        -- downC (name, DomainSet "Explicit" (SetAttrSize size) innerDomain, ConstantSet constants) =
        --     let outIndexDomain = DomainInt [RangeBounded (ConstantInt 1) size]
        --     in  return $ Just
        --             [ ( outName name
        --               , DomainMatrix   outIndexDomain innerDomain
        --               , ConstantMatrix outIndexDomain constants
        --               ) ]
        downC _ = fail "N/A {downC}"

        -- up ctxt (name, domain@(DomainFunction "Function1DPartial"
        --                         (FunctionAttr _ FunctionAttr_Partial _)
        --                         innerDomainFr _)) =
        --     case (lookup (nameFlags name) ctxt, lookup (nameValues name) ctxt) of
        --         (Just flagMatrix, Just valuesMatrix)
        --         Nothing -> fail $ vcat $
        --             [ "No value for:" <+> pretty (outName name)
        --             , "When working on:" <+> pretty name
        --             , "With domain:" <+> pretty domain
        --             ] ++
        --             ("Bindings in context:" : prettyContext ctxt)
        --         Just constant ->
        --             case constant of
        --                 ConstantMatrix _ vals -> do
        --                     froms <- domainValues innerDomainFr
        --                     return ( name
        --                            , ConstantFunction (zip froms vals)
        --                            )
        --                 _ -> fail $ vcat
        --                         [ "Expecting a matrix literal for:" <+> pretty (outName name)
        --                         , "But got:" <+> pretty constant
        --                         , "When working on:" <+> pretty name
        --                         , "With domain:" <+> pretty domain
        --                         ]
        up _ _ = fail "N/A {up}"

