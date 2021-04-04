module Graphics.GPipe.Context.GLFW.InputSpec (spec) where

import           Test.Hspec                  (Spec, describe, it)

import           Graphics.GPipe
import qualified Graphics.GPipe.Context.GLFW       as GLFW
import qualified Graphics.GPipe.Context.GLFW.Input as Input
import qualified Test.Common                       as C
import qualified Test.Control                      as A
import           Text.Printf                       (printf)

spec :: Spec
spec = do
    describe "Input" $ do
        it "should listen for button inputs while rendering a scene to a window" $ do
            C.runContext GLFW.defaultHandleConfig $ do
                win <- newWindow (WindowFormatColorDepth RGB8 Depth16) (GLFW.defaultWindowConfig "Input")

                Input.setCursorPosCallback win $ Just (\x y -> printf "Cursor pos: %fx%f\n" x y)
                Input.setMouseButtonCallback win $ Just (\b s m -> printf "Mouse: %s %s\n" (show b) (show s))
                Input.setKeyCallback win $ Just (\k i s m -> printf "Key: %s %s %s\n" (show k) (show i) (show s))

                resources <- C.initRenderContext win [C.plane, C.yAxis]
                C.mainloop win (A.frames 120) resources C.continue
