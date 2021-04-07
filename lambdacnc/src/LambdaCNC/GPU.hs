{-# LANGUAGE DeriveFunctor       #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies        #-}
module LambdaCNC.GPU
  ( main
  ) where

import qualified Control.Concurrent.MVar           as MVar
import           Control.Lens                      ((^.))
import           Control.Monad.IO.Class            (liftIO)
import           Data.Functor                      (void)
import           Graphics.GPipe
import qualified Graphics.GPipe.Context.GLFW       as GLFW
import qualified Graphics.GPipe.Context.GLFW.Input as Input
import qualified Graphics.GPipe.Engine             as Engine
import qualified LambdaCNC.Pipeline                as Pipeline
import qualified System.Directory                  as Dir
import qualified System.Environment                as Env
import           System.FilePath                   ((</>))


fps :: Double
fps = 24

windowSize :: V2 Int
windowSize = V2 1500 800


cleanupShaders :: IO ()
cleanupShaders = do
    let prefix = "generated-shaders"
    files <- map (prefix </>) . filter (/= "README.md") <$> Dir.listDirectory prefix
    mapM_ Dir.removeFile files


main :: IO ()
main = do
    Env.setEnv "GPIPE_DEBUG" "1"
    cleanupShaders

    runContextT GLFW.defaultHandleConfig{GLFW.configEventPolicy = Just $ GLFW.WaitTimeout $ 1 / fps } $ do
        win <- newWindow (WindowFormatColorDepth RGB8 Depth16) $ (GLFW.defaultWindowConfig "LambdaCNC (GPipe)")
            { GLFW.configWidth = windowSize^._x
            , GLFW.configHeight = windowSize^._y
            , GLFW.configHints =
                [ GLFW.WindowHint'Samples (Just 8)
                ]
            }

        pipelineData <- Pipeline.initialise win
        pipelineState <- liftIO $ MVar.newMVar Pipeline.startState

        void $ Input.setKeyCallback win $ Just $ \k i s m ->
            MVar.modifyMVar_ pipelineState (\state -> return $ Pipeline.keyCallback state k i s m)

        Engine.mainloop win False Pipeline.renderings pipelineData pipelineState
