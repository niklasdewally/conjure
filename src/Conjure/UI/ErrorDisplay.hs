module Conjure.UI.ErrorDisplay where
import Conjure.Prelude
import Conjure.Language.Validator
import Text.Megaparsec
import Data.Void (Void)
import qualified Data.Set as Set
import Conjure.Language.AST.Syntax
import Conjure.Language.AST.ASTParser
import Conjure.Language.NewLexer
import Conjure.Language.Lexemes
import qualified Data.Text
import qualified Data.Text as T
import Data.Map.Strict (mapWithKey, assocs)
import Conjure.Language.Pretty



type Parser t = Parsec DiagnosticForPrint Text t

data DiagnosticForPrint = DiagnosticForPrint {
    dStart :: Int,
    dLength :: Int,
    dMessage :: Diagnostic
} deriving (Show,Eq,Ord)

instance ShowErrorComponent DiagnosticForPrint where
  errorComponentLen (DiagnosticForPrint {dLength=l}) = l

  showErrorComponent DiagnosticForPrint {dMessage=message}= case message of
    Error et ->  displayError et
    Warning wt -> displayWarning wt
    Info it -> "Info: " ++ show it

tokenErrorToDisplay :: LToken -> String
tokenErrorToDisplay (RealToken _ ) = error "tokenError with valid token"
tokenErrorToDisplay (SkippedToken t) = "Unexpected " ++ show t
tokenErrorToDisplay (MissingToken (lexeme->l)) = "Missing " ++ case l of
    L_Missing s -> s
    LMissingIdentifier -> "<identifier>"
    _ -> T.unpack $ lexemeText l

displayWarning :: WarningType -> String
displayWarning (UnclassifiedWarning txt) = "Warning" ++ T.unpack txt
displayWarning AmbiguousTypeWarning = "Ambiguous type occurred"

displayError :: ErrorType -> String
displayError x = case x of
  TokenError lt -> tokenErrorToDisplay lt
  SyntaxError txt -> "Syntax Error: " ++ T.unpack txt
  SemanticError txt -> "Error: " ++ T.unpack txt
  CustomError txt -> "Error: " ++ T.unpack txt
  TypeError expected got -> "Type error: Expected: " ++ show (pretty expected) ++ " Got: " ++ show (pretty got)
  ComplexTypeError msg ty -> "Type error: Expected:" ++ show msg ++ " got " ++ (show $ pretty ty)
  SkippedTokens -> "Skipped tokens"
  UnexpectedArg -> "Unexpected argument"
  MissingArgsError expected got -> "Insufficient args, expected " ++ (show expected) ++ " got " ++ (show got)
  InternalError -> "Pattern match failiure"
  InternalErrorS txt -> "Something went wrong:" ++ T.unpack txt
  WithReplacements e alts -> displayError e ++ "\n\tValid alternatives: " ++ intercalate "," (show <$> alts)
  KindError a b -> show $ "Tried to use a " <> pretty b <> " where " <> pretty a <> " was expected"

showDiagnosticsForConsole :: [ValidatorDiagnostic] -> Text -> String
showDiagnosticsForConsole errs text
    =   case runParser (captureErrors errs) "Errors" text of
            Left peb -> errorBundlePretty peb
            Right _ -> "No printable errors from :" ++ (show . length $ errs)


printSymbolTable :: SymbolTable -> IO ()
printSymbolTable tab = putStrLn "Symbol table" >> ( mapM_  printEntry $ assocs tab)
    where
        printEntry :: (Text ,SymbolTableValue) -> IO ()
        printEntry (a,(r,c,t)) = putStrLn $ show a ++ ":" ++ show (pretty t) ++ if c then " Enum" else ""

captureErrors :: [ValidatorDiagnostic] -> Parser ()
captureErrors = (mapM_ captureError) . collapseSkipped

collapseSkipped :: [ValidatorDiagnostic] -> [ValidatorDiagnostic]
collapseSkipped [] = []
collapseSkipped [x] = [x]
collapseSkipped ((ValidatorDiagnostic regx ex) :(ValidatorDiagnostic regy ey):rs) 
    | isSkipped ex && isSkipped ey && sameLine (drSourcePos regx) (drSourcePos regy) 
    = collapseSkipped $ ValidatorDiagnostic (catDr regx regy) (Error $ SkippedTokens ) : rs
    where 
        isSkipped (Error (TokenError (SkippedToken  _))) = True
        isSkipped (Error SkippedTokens) = True
        isSkipped _ = False
        sameLine :: SourcePos -> SourcePos -> Bool
        sameLine (SourcePos _ l1 _) (SourcePos _ l2 _) = l1 == l2
        catDr :: DiagnosticRegion -> DiagnosticRegion -> DiagnosticRegion
        catDr (DiagnosticRegion sp _ o _) (DiagnosticRegion _ en _ _) = DiagnosticRegion sp en o ((unPos (sourceColumn en) - unPos (sourceColumn sp)))
collapseSkipped (x:xs) = x : collapseSkipped xs
            

captureError :: ValidatorDiagnostic -> Parser ()
captureError (ValidatorDiagnostic reg message) |reg == global = do
    let printError = DiagnosticForPrint 0 0 message
    registerFancyFailure (Set.singleton(ErrorCustom printError) )
captureError (ValidatorDiagnostic area message) = do
    setOffset $ drOffset area
    let printError = DiagnosticForPrint (drOffset area) (drLength area) message
    registerFancyFailure (Set.singleton(ErrorCustom printError) )



val :: String -> IO ()
val s = do
    let str = s
    let other = []
    let txt = Data.Text.pack str
    let lexed = parseMaybe eLex txt
    let stream = ETokenStream txt $ fromMaybe other lexed
    -- parseTest parseProgram stream
    let progStruct = runParser parseProgram "TEST" stream

    case progStruct of
        Left _ -> putStrLn "error"
        Right p@(ProgramTree{}) -> let qpr = runValidator (validateModel p) (initialState p){typeChecking=True} in
            case qpr of
                (model, vds,st) -> do
                    print (show model)
                    putStrLn $ show vds
                    printSymbolTable $ symbolTable st
                    putStrLn $ show $ (regionInfo st)
                    putStrLn $ showDiagnosticsForConsole vds txt

            -- putStrLn $ show qpr


valFile :: String -> IO ()
valFile p = do
    path <- readFileIfExists p
    case path of
      Nothing -> putStrLn "NO such file"
      Just s -> val s
    return ()
-- putStrLn validateFind
