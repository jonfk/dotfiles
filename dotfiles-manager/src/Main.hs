
import Data.Algorithm.Diff
import Data.Algorithm.DiffOutput

import Options.Applicative

data CmdOptions = CmdOptions
  { target :: String
  , diff :: Bool
  , fetch :: Bool
  , push :: Bool}

cmdOptions :: Parser CmdOptions
cmdOptions = CmdOptions
         <$> strOption
         ( long "target"
         <> short 't'
         <> value "all"
         <> metavar "TARGET"
         <> help "Target to manage" )
         <*> switch
         ( long "diff"
         <> short 'd'
         <> help "Show the diff for the target" )
         <*> switch
         ( long "fetch"
         <> short 'f'
         <> help "Fetch the changes from dotfiles")
         <*> switch
         ( long "push"
         <> short 'p'
         <> help "Push changes to configs to dotfiles")

run :: CmdOptions -> IO ()
run (CmdOptions h False _ _) = putStrLn $ "Hello, " ++ h
run _ = return ()

main = execParser opts >>= greet
    where
      opts = info (helper <*> cmdOptions)
             ( fullDesc
             <> progDesc "Manage dotfiles"
             <> header "dotfiles-manager - a test for optparse-applicative" )
