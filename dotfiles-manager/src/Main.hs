
import Data.Algorithm.Diff
import Data.Algorithm.DiffOutput

import Options.Applicative
import System.Directory

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

data Target = All | Awesome | Bash | Emacs | Vim | Unknown
            deriving (Show, Read, Eq)

run :: CmdOptions -> IO ()
run (CmdOptions t diff fetch push) =
    do
      let target = case t of
                     "all" -> All
                     "awesome" -> Awesome
                     "bash" -> Bash
                     "emacs" -> Emacs
                     "vim" -> Vim
                     _ -> Unknown
      if target == Unknown then
            putStrLn $ "Unknown target" ++ t ++ "cannot proceed"
      else
          do
            --putStrLn $ "Target known: " ++ (show target)
            if diff then
                diffFiles target
            else
                return ()
            if fetch then
                putStrLn "Unimplemented"
            else
                return ()
            if push then
                putStrLn "Unimplemented"
            else
                return ()


lineToList :: a -> [a]
lineToList = \x -> [x]

diffFiles :: Target -> IO ()
diffFiles target =
    do
      homeDir <- getHomeDirectory
      case target of
        All ->
            do
              diffEmacs homeDir
              diffAwesome homeDir
              diffBash homeDir
              diffVim homeDir
        Awesome ->
            diffAwesome homeDir
        Bash ->
            diffBash homeDir
        Emacs ->
            diffEmacs homeDir
        Vim ->
            diffVim homeDir
        _ -> putStrLn "unimplemented"

diffEmacs homeDir =
    diffFile (homeDir ++ "/dotfiles/emacs/.emacs") (homeDir ++ "/.emacs")

diffAwesome homeDir =
    diffFile (homeDir ++ "/dotfiles/awesome/.config/awesome/rc.lua") (homeDir ++ "/.config/awesome/rc.lua")

diffBash homeDir =
    diffFile (homeDir ++ "/dotfiles/bash/.bashrc") (homeDir ++ "/.bashrc")

diffVim homeDir =
    diffFile (homeDir ++ "/dotfiles/vim/.vimrc") (homeDir ++ "/.vimrc")

diffFile :: FilePath -> FilePath -> IO ()
diffFile filepath1 filepath2 =
    do
      file1 <- readFile $ filepath1
      file2 <- readFile $ filepath2
      let first = map lineToList $ lines file1
      let second = map lineToList $ lines file2
      putStrLn $ ppDiff $ getDiff first second

main = execParser opts >>= run
    where
      opts = info (helper <*> cmdOptions)
             ( fullDesc
             <> progDesc "Manage dotfiles"
             <> header "dotfiles-manager - a test for optparse-applicative" )
