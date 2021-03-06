{-# LANGUAGE OverloadedStrings #-}

module Goals (
    testGoals
  , scoreGoal
  , getGoalScores
) where

import Database.MongoDB
import Utils
import Data.Time
import Data.Int
import Data.Text (unpack)

testGoals = undefined

scoreGoal :: DatabaseName -> ObjectId -> Int -> IO ()
scoreGoal dbName goalId score = do
  time <- getCurrentTime
  pipe <- sharedPipe
  run pipe dbName $ insert_ (docTypeToText GoalScore) $
    [(labelStr Created) =: time,
     (labelStr GoalId) =: goalId, 
     (labelStr ScoreLabel) =: score]
  return ()


formatGoalScore :: DatabaseName -> Document -> IO String
formatGoalScore dbName scoreDoc = do
  let ObjId goalId = valueAt (labelStr ItemId) scoreDoc
      selection = select ["_id" =: goalId] (docTypeToText Goal)
  pipe <- sharedPipe
  mDoc <- run pipe dbName $ findOne selection
  case mDoc of 
    Left failure -> do putStrLn $ show failure
                       return "failed"
    Right mDoc -> case mDoc of 
      Nothing -> return "Didn't find the goal with that goal id."
      Just goalDoc -> let String text = valueAt (labelStr TextLabel) goalDoc
                          Int32 score = valueAt (labelStr ScoreLabel) 
                            scoreDoc
                  in return $ (show score) ++ " - " ++ (unpack text)

  -- get the goal title by score goalId
  -- return a string like
  -- 27 - Brush teeth 3 times a day

formatGoalScores :: DatabaseName -> [Document] -> IO [String]
formatGoalScores dbName docs = mapM (formatGoalScore dbName) docs

getGoalScores :: DatabaseName -> IO [String]
getGoalScores dbName = do
  pipe <- sharedPipe
  let pipeline = [ ["$group" =: 
                      ["_id" =: ("$goalId" :: String),
                       "score" =: ["$sum" =: (1 :: Int32)]
                      ]
                    ] 
                  ]
  mDocs <- run pipe dbName $ aggregate (docTypeToText GoalScore) pipeline
  case mDocs of
    Left failure -> do putStrLn $ show failure
                       return []
    Right docs -> formatGoalScores dbName docs
