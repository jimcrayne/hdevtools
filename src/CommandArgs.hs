{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE CPP #-}
module CommandArgs
    ( HDevTools(..)
    , loadHDevTools
    )
where

import Data.Version (showVersion)
import Paths_hdevtools (version)
import System.Console.CmdArgs.Implicit
import System.Environment (getProgName)
import System.Info (arch, os)
import qualified Config

programVersion :: String
programVersion =
    "version " ++ showVersion version

cabalVersion :: String
cabalVersion =
    "cabal-" ++ VERSION_Cabal

fullVersion :: String
fullVersion =
    concat
        [ programVersion
        , " ("
        , "ghc-", Config.cProjectVersion, "-", arch, "-", os
        , ", ", cabalVersion
        , ")"
        ]

data HDevTools
    = Admin
        { socket       :: Maybe FilePath
        , start_server :: Bool
        , noDaemon     :: Bool
        , status       :: Bool
        , stop_server  :: Bool
        }
    | Check
        { socket  :: Maybe FilePath
        , ghcOpts :: [String]
        , cabalOpts :: [String]
        , path    :: Maybe String
        , file    :: String
        , json    :: Bool
        }
    | ModuleFile
        { socket  :: Maybe FilePath
        , ghcOpts :: [String]
        , cabalOpts :: [String]
        , module_ :: String
        }
    | Info
        { socket     :: Maybe FilePath
        , ghcOpts    :: [String]
        , cabalOpts  :: [String]
        , path       :: Maybe String
        , file       :: String
        , identifier :: String
        }
    | Type
        { socket  :: Maybe FilePath
        , ghcOpts :: [String]
        , cabalOpts  :: [String]
        , path    :: Maybe String
        , file    :: String
        , line    :: Int
        , col     :: Int
        }
    | FindSymbol
        { socket :: Maybe FilePath
        , ghcOpts :: [String]
        , cabalOpts :: [String]
        , symbol :: String
        , files :: [String]
        }
    deriving (Show, Data, Typeable)

dummyAdmin :: HDevTools
dummyAdmin = Admin
    { socket       = Nothing
    , start_server = False
    , noDaemon     = False
    , status       = False
    , stop_server  = False
    }

dummyCheck :: HDevTools
dummyCheck = Check
    { socket  = Nothing
    , ghcOpts = []
    , cabalOpts = []
    , path    = Nothing
    , file    = ""
    , json    = False
    }

dummyModuleFile :: HDevTools
dummyModuleFile = ModuleFile
    { socket  = Nothing
    , ghcOpts = []
    , cabalOpts = []
    , module_ = ""
    }

dummyInfo :: HDevTools
dummyInfo = Info
    { socket     = Nothing
    , ghcOpts    = []
    , cabalOpts = []
    , path       = Nothing
    , file       = ""
    , identifier = ""
    }

dummyType :: HDevTools
dummyType = Type
    { socket  = Nothing
    , ghcOpts = []
    , cabalOpts = []
    , path    = Nothing
    , file    = ""
    , line    = 0
    , col     = 0
    }

dummyFindSymbol :: HDevTools
dummyFindSymbol = FindSymbol
    { socket = Nothing
    , ghcOpts = []
    , cabalOpts = []
    , symbol = ""
    , files = []
    }

admin :: Annotate Ann
admin = record dummyAdmin
    [ socket       := def += typFile += help "socket file to use"
    , start_server := def            += help "start server"
    , noDaemon     := def            += help "do not daemonize (only if --start-server)"
    , status       := def            += help "show status of server"
    , stop_server  := def            += help "shutdown the server"
    ] += help "Interactions with the server"

check :: Annotate Ann
check = record dummyCheck
    [ socket   := def += typFile      += help "socket file to use"
    , ghcOpts  := def += typ "OPTION" += help "ghc options"
    , cabalOpts := def += typ "OPTION"  += help "cabal options"
    , path     := def += typFile      += help "path to target file"
    , file     := def += typFile      += argPos 0 += opt ""
    , json     := def                 += help "render output as JSON"
    ] += help "Check a haskell source file for errors and warnings"

moduleFile :: Annotate Ann
moduleFile = record dummyModuleFile
    [ socket   := def += typFile += help "socket file to use"
    , ghcOpts  := def += typ "OPTION" += help "ghc options"
    , cabalOpts := def += typ "OPTION"  += help "cabal options"
    , module_  := def += typ "MODULE" += argPos 0
    ] += help "Get the haskell source file corresponding to a module name"

info :: Annotate Ann
info = record dummyInfo
    [ socket     := def += typFile      += help "socket file to use"
    , ghcOpts    := def += typ "OPTION" += help "ghc options"
    , cabalOpts := def += typ "OPTION"  += help "cabal options"
    , path       := def += typFile      += help "path to target file"
    , file       := def += typFile      += argPos 0 += opt ""
    , identifier := def += typ "IDENTIFIER" += argPos 1
    ] += help "Get info from GHC about the specified identifier"

type_ :: Annotate Ann
type_ = record dummyType
    [ socket   := def += typFile += help "socket file to use"
    , ghcOpts  := def += typ "OPTION" += help "ghc options"
    , cabalOpts := def += typ "OPTION"  += help "cabal options"
    , path     := def += typFile      += help "path to target file"
    , file     := def += typFile      += argPos 0 += opt ""
    , line     := def += typ "LINE"   += argPos 1
    , col      := def += typ "COLUMN" += argPos 2
    ] += help "Get the type of the expression at the specified line and column"

findSymbol :: Annotate Ann
findSymbol = record dummyFindSymbol
    [ socket   := def += typFile += help "socket file to use"
    , ghcOpts  := def += typ "OPTION" += help "ghc options"
    , cabalOpts := def += typ "OPTION"  += help "cabal options"
    , symbol   := def += typ "SYMBOL" += argPos 0
    , files    := def += typFile += args
    ] += help "List the modules where the given symbol could be found"

full :: String -> Annotate Ann
full progName = modes_ [admin += auto, check, moduleFile, info, type_, findSymbol]
        += helpArg [name "h", groupname "Help"]
        += versionArg [groupname "Help"]
        += program progName
        += summary (progName ++ ": " ++ fullVersion)

loadHDevTools :: IO HDevTools
loadHDevTools = do
    progName <- getProgName
    (cmdArgs_ (full progName) :: IO HDevTools)
