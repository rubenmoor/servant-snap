{-# LANGUAGE OverloadedStrings #-}
module Servant.Server.Internal.PathInfo where

import qualified Data.ByteString.Char8 as B
import           Data.List             (unfoldr)
import           Data.Text             (Text)
import qualified Data.Text             as T
import qualified Data.Text.Encoding    as T
--import           Network.Wai                 (Request, pathInfo)
import           Snap.Core

import           Debug.Trace

traceShow' a = traceShow a a

rqPath :: Request -> B.ByteString
rqPath r = B.append (rqContextPath r) (rqPathInfo r)

pathInfo :: Request -> [Text]
pathInfo = traceShow' . tail . T.splitOn "/" . T.decodeUtf8 . rqPath

pathSafeTail :: Request -> ([B.ByteString], [B.ByteString])
pathSafeTail r =
  let contextParts = B.split '/' (rqContextPath r)
      restParts    = B.split '/' (rqPathInfo r)
  in case (contextParts, restParts) of
       ([],[])   ->  ([], [])
       (_:xs, y)  -> (xs, y)
       ([], _:ys) -> ([], ys)

-- TODO: Is this right? Does it drop leading/trailing slashes?
reqSafeTail :: Request -> Request
reqSafeTail r = let (ctx,inf) = pathSafeTail r
                in  r { rqContextPath = B.intercalate "/" ctx
                      , rqPathInfo    = B.intercalate "/" inf
                      }

-- | Like `null . pathInfo`, but works with redundant trailing slashes.
pathIsEmpty :: Request -> Bool
pathIsEmpty = f . processedPathInfo
  where
    f []   = True
    f [""] = True
    f _    = False


splitMatrixParameters :: Text -> (Text, Text)
splitMatrixParameters = T.break (== ';')

parsePathInfo :: Request -> [Text]
parsePathInfo = filter (/= "") . mergePairs . map splitMatrixParameters . pathInfo
  where mergePairs = concat . unfoldr pairToList
        pairToList []          = Nothing
        pairToList ((a, b):xs) = Just ([a, b], xs)

-- | Returns a processed pathInfo from the request.
--
-- In order to handle matrix parameters in the request correctly, the raw pathInfo needs to be
-- processed, so routing works as intended. Therefor this function should be used to access
-- the pathInfo for routing purposes.
processedPathInfo :: Request -> [Text]
processedPathInfo r =
  case pinfo of
    (x:xs) | T.head x == ';' -> xs
    _                        -> pinfo
  where pinfo = parsePathInfo r
