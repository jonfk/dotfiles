
import Data.Algorithm.Diff
import Data.Algorithm.DiffOutput
import System.Environment
import System.IO

--abdiff = getDiff a b
--output = ppDiff abdiff

lineToList :: a -> [a]
lineToList = \x -> [x]

main = do
  args <- getArgs
  print args
  if length args > 2 then
      putStrLn "Cannot diff more than 2 files"
  else
      do
        file1 <- readFile $ head args
        file2 <- readFile $ last args
        let first = map lineToList $ lines file1
        let second = map lineToList $ lines file2
        putStrLn $ ppDiff $ getDiff first second
