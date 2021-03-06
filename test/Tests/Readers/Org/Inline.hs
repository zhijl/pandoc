{-# LANGUAGE OverloadedStrings #-}
module Tests.Readers.Org.Inline (tests) where

import Data.List (intersperse)
import Test.Tasty (TestTree, testGroup)
import Tests.Helpers ((=?>))
import Tests.Readers.Org.Shared ((=:), spcSep)
import Text.Pandoc
import Text.Pandoc.Builder
import Text.Pandoc.Shared (underlineSpan)
import qualified Data.Text as T
import qualified Tests.Readers.Org.Inline.Note as Note
import qualified Tests.Readers.Org.Inline.Smart as Smart

tests :: [TestTree]
tests =
  [ "Plain String" =:
      "Hello, World" =?>
      para (spcSep [ "Hello,", "World" ])

  , "Emphasis" =:
      "/Planet Punk/" =?>
      para (emph . spcSep $ ["Planet", "Punk"])

  , "Strong" =:
      "*Cider*" =?>
      para (strong "Cider")

  , "Strong Emphasis" =:
      "/*strength*/" =?>
      para (emph . strong $ "strength")

  , "Emphasized Strong preceded by space" =:
      " */super/*" =?>
      para (strong . emph $ "super")

  , "Underline" =:
      "_underline_" =?>
      para (underlineSpan $ "underline")

  , "Strikeout" =:
      "+Kill Bill+" =?>
      para (strikeout . spcSep $ [ "Kill", "Bill" ])

  , "Verbatim" =:
      "=Robot.rock()=" =?>
      para (code "Robot.rock()")

  , "Code" =:
      "~word for word~" =?>
      para (code "word for word")

  , "Math $..$" =:
      "$E=mc^2$" =?>
       para (math "E=mc^2")

  , "Math $$..$$" =:
      "$$E=mc^2$$" =?>
      para (displayMath "E=mc^2")

  , "Math \\[..\\]" =:
      "\\[E=ℎν\\]" =?>
      para (displayMath "E=ℎν")

  , "Math \\(..\\)" =:
      "\\(σ_x σ_p ≥ \\frac{ℏ}{2}\\)" =?>
      para (math "σ_x σ_p ≥ \\frac{ℏ}{2}")

  , "Symbol" =:
      "A * symbol" =?>
      para (str "A" <> space <> str "*" <> space <> "symbol")

  , "Superscript simple expression" =:
      "2^-λ" =?>
      para (str "2" <> superscript "-λ")

  , "Superscript multi char" =:
      "2^{n-1}" =?>
      para (str "2" <> superscript "n-1")

  , "Subscript simple expression" =:
      "a_n" =?>
      para (str "a" <> subscript "n")

  , "Subscript multi char" =:
      "a_{n+1}" =?>
      para (str "a" <> subscript "n+1")

  , "Linebreak" =:
      "line \\\\ \nbreak" =?>
      para ("line" <> linebreak <> "break")

  , "Inline note" =:
      "[fn::Schreib mir eine E-Mail]" =?>
      para (note $ para "Schreib mir eine E-Mail")

  , "Markup-chars not occuring on word break are symbols" =:
      T.unlines [ "this+that+ +so+on"
                , "seven*eight* nine*"
                , "+not+funny+"
                ] =?>
      para ("this+that+ +so+on" <> softbreak <>
            "seven*eight* nine*" <> softbreak <>
            strikeout "not+funny")

  , "No empty markup" =:
      "// ** __ <> == ~~ $$" =?>
      para (spcSep [ "//", "**", "__", "<>", "==", "~~", "$$" ])

  , "Adherence to Org's rules for markup borders" =:
      "/t/& a/ / ./r/ (*l*) /e/! /b/." =?>
      para (spcSep [ emph $ "t/&" <> space <> "a"
                   , "/"
                   , "./r/"
                   , "(" <> strong "l" <> ")"
                   , emph "e" <> "!"
                   , emph "b" <> "."
                   ])

  , "Quotes are allowed border chars" =:
      "/'yep/ *sure\"*" =?>
      para (emph "'yep" <> space <> strong "sure\"")

  , "Spaces are forbidden border chars" =:
      "/nada /" =?>
      para "/nada /"

  , "Markup should work properly after a blank line" =:
    T.unlines ["foo", "", "/bar/"] =?>
    (para $ text "foo") <> (para $ emph $ text "bar")

  , "Inline math must stay within three lines" =:
      T.unlines [ "$a", "b", "c$", "$d", "e", "f", "g$" ] =?>
      para ((math "a\nb\nc") <> softbreak <>
            "$d" <> softbreak <> "e" <> softbreak <>
            "f" <> softbreak <> "g$")

  , "Single-character math" =:
      "$a$ $b$! $c$?" =?>
      para (spcSep [ math "a"
                   , "$b$!"
                   , (math "c") <> "?"
                   ])

  , "Markup may not span more than two lines" =:
      "/this *is +totally\nnice+ not*\nemph/" =?>
      para ("/this" <> space <>
              strong ("is" <> space <>
                      strikeout ("totally" <>
                        softbreak <> "nice") <>
                      space <> "not") <>
              softbreak <> "emph/")

  , "Sub- and superscript expressions" =:
     T.unlines [ "a_(a(b)(c)d)"
               , "e^(f(g)h)"
               , "i_(jk)l)"
               , "m^()n"
               , "o_{p{q{}r}}"
               , "s^{t{u}v}"
               , "w_{xy}z}"
               , "1^{}2"
               , "3_{{}}"
               , "4^(a(*b(c*)d))"
               ] =?>
     para (mconcat $ intersperse softbreak
                  [ "a" <> subscript "(a(b)(c)d)"
                  , "e" <> superscript "(f(g)h)"
                  , "i" <> (subscript "(jk)") <> "l)"
                  , "m" <> (superscript "()") <> "n"
                  , "o" <> subscript "p{q{}r}"
                  , "s" <> superscript "t{u}v"
                  , "w" <> (subscript "xy") <> "z}"
                  , "1" <> (superscript "") <> "2"
                  , "3" <> subscript "{}"
                  , "4" <> superscript ("(a(" <> strong "b(c" <> ")d))")
                  ])
  , "Verbatim text can contain equal signes (=)" =:
      "=is_subst = True=" =?>
      para (code "is_subst = True")

  , testGroup "Images"
    [ "Image" =:
        "[[./sunset.jpg]]" =?>
        (para $ image "./sunset.jpg" "" "")

    , "Image with explicit file: prefix" =:
        "[[file:sunrise.jpg]]" =?>
        (para $ image "sunrise.jpg" "" "")

    , "Multiple images within a paragraph" =:
        T.unlines [ "[[file:sunrise.jpg]]"
                  , "[[file:sunset.jpg]]"
                  ] =?>
        (para $ (image "sunrise.jpg" "" "")
             <> softbreak
             <> (image "sunset.jpg" "" ""))

    , "Image with html attributes" =:
        T.unlines [ "#+ATTR_HTML: :width 50%"
                  , "[[file:guinea-pig.gif]]"
                  ] =?>
        (para $ imageWith ("", [], [("width", "50%")]) "guinea-pig.gif" "" "")
    ]

  , "Explicit link" =:
      "[[http://zeitlens.com/][pseudo-random /nonsense/]]" =?>
      (para $ link "http://zeitlens.com/" ""
                   ("pseudo-random" <> space <> emph "nonsense"))

  , "Self-link" =:
      "[[http://zeitlens.com/]]" =?>
      (para $ link "http://zeitlens.com/" "" "http://zeitlens.com/")

  , "Absolute file link" =:
      "[[/url][hi]]" =?>
      (para $ link "file:///url" "" "hi")

  , "Link to file in parent directory" =:
      "[[../file.txt][moin]]" =?>
      (para $ link "../file.txt" "" "moin")

  , "Empty link (for gitit interop)" =:
      "[[][New Link]]" =?>
      (para $ link "" "" "New Link")

  , "Image link" =:
      "[[sunset.png][file:dusk.svg]]" =?>
      (para $ link "sunset.png" "" (image "dusk.svg" "" ""))

  , "Image link with non-image target" =:
      "[[http://example.com][./logo.png]]" =?>
      (para $ link "http://example.com" "" (image "./logo.png" "" ""))

  , "Plain link" =:
      "Posts on http://zeitlens.com/ can be funny at times." =?>
      (para $ spcSep [ "Posts", "on"
                     , link "http://zeitlens.com/" "" "http://zeitlens.com/"
                     , "can", "be", "funny", "at", "times."
                     ])

  , "Angle link" =:
      "Look at <http://moltkeplatz.de> for fnords." =?>
      (para $ spcSep [ "Look", "at"
                     , link "http://moltkeplatz.de" "" "http://moltkeplatz.de"
                     , "for", "fnords."
                     ])

  , "Absolute file link" =:
      "[[file:///etc/passwd][passwd]]" =?>
      (para $ link "file:///etc/passwd" "" "passwd")

  , "File link" =:
      "[[file:target][title]]" =?>
      (para $ link "target" "" "title")

  , "Anchor" =:
      "<<anchor>> Link here later." =?>
      (para $ spanWith ("anchor", [], []) mempty <>
              "Link" <> space <> "here" <> space <> "later.")

  , "Inline code block" =:
      "src_emacs-lisp{(message \"Hello\")}" =?>
      (para $ codeWith ( ""
                       , [ "commonlisp" ]
                       , [ ("org-language", "emacs-lisp") ])
                       "(message \"Hello\")")

  , "Inline code block with arguments" =:
      "src_sh[:export both :results output]{echo 'Hello, World'}" =?>
      (para $ codeWith ( ""
                       , [ "bash" ]
                       , [ ("org-language", "sh")
                         , ("export", "both")
                         , ("results", "output")
                         ]
                       )
                       "echo 'Hello, World'")

  , "Inline code block with toggle" =:
      "src_sh[:toggle]{echo $HOME}" =?>
      (para $ codeWith ( ""
                       , [ "bash" ]
                       , [ ("org-language", "sh")
                         , ("toggle", "yes")
                         ]
                       )
                       "echo $HOME")

  , "Citation" =:
      "[@nonexistent]" =?>
      let citation = Citation
                     { citationId = "nonexistent"
                     , citationPrefix = []
                     , citationSuffix = []
                     , citationMode = NormalCitation
                     , citationNoteNum = 0
                     , citationHash = 0}
      in (para $ cite [citation] "[@nonexistent]")

  , "Citation containing text" =:
      "[see @item1 p. 34-35]" =?>
      let citation = Citation
                     { citationId = "item1"
                     , citationPrefix = [Str "see"]
                     , citationSuffix = [Space ,Str "p.",Space,Str "34-35"]
                     , citationMode = NormalCitation
                     , citationNoteNum = 0
                     , citationHash = 0}
      in (para $ cite [citation] "[see @item1 p. 34-35]")

  , "Org-ref simple citation" =:
    "cite:pandoc" =?>
    let citation = Citation
                   { citationId = "pandoc"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = AuthorInText
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "cite:pandoc")

  , "Org-ref simple citation with underscores" =:
    "cite:pandoc_org_ref" =?>
    let citation = Citation
                   { citationId = "pandoc_org_ref"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = AuthorInText
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "cite:pandoc_org_ref")

  , "Org-ref simple citation succeeded by comma" =:
    "cite:pandoc," =?>
    let citation = Citation
                   { citationId = "pandoc"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = AuthorInText
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "cite:pandoc" <> str ",")

  , "Org-ref simple citation succeeded by dot" =:
    "cite:pandoc." =?>
    let citation = Citation
                   { citationId = "pandoc"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = AuthorInText
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "cite:pandoc" <> str ".")

  , "Org-ref simple citation succeeded by colon" =:
    "cite:pandoc:" =?>
    let citation = Citation
                   { citationId = "pandoc"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = AuthorInText
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "cite:pandoc" <> str ":")

  , "Org-ref simple citep citation" =:
    "citep:pandoc" =?>
    let citation = Citation
                   { citationId = "pandoc"
                   , citationPrefix = mempty
                   , citationSuffix = mempty
                   , citationMode = NormalCitation
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "citep:pandoc")

  , "Org-ref extended citation" =:
    "[[citep:Dominik201408][See page 20::, for example]]" =?>
    let citation = Citation
                   { citationId = "Dominik201408"
                   , citationPrefix = toList "See page 20"
                   , citationSuffix = toList ", for example"
                   , citationMode = NormalCitation
                   , citationNoteNum = 0
                   , citationHash = 0
                   }
    in (para $ cite [citation] "[[citep:Dominik201408][See page 20::, for example]]")

  , testGroup "Berkeley-style citations" $
    let pandocCite = Citation
          { citationId = "Pandoc"
          , citationPrefix = mempty
          , citationSuffix = mempty
          , citationMode = NormalCitation
          , citationNoteNum = 0
          , citationHash = 0
          }
        pandocInText = pandocCite { citationMode = AuthorInText }
        dominikCite = Citation
          { citationId = "Dominik201408"
          , citationPrefix = mempty
          , citationSuffix = mempty
          , citationMode = NormalCitation
          , citationNoteNum = 0
          , citationHash = 0
          }
        dominikInText = dominikCite { citationMode = AuthorInText }
    in [
        "Berkeley-style in-text citation" =:
          "See @Dominik201408." =?>
            (para $ "See "
                  <> cite [dominikInText] "@Dominik201408"
                  <> ".")

      , "Berkeley-style parenthetical citation list" =:
          "[(cite): see; @Dominik201408;also @Pandoc; and others]" =?>
          let pandocCite'  = pandocCite {
                               citationPrefix = toList "also"
                             , citationSuffix = toList "and others"
                             }
              dominikCite' = dominikCite {
                               citationPrefix = toList "see"
                             }
          in (para $ cite [dominikCite', pandocCite'] "")

      , "Berkeley-style plain citation list" =:
          "[cite: See; @Dominik201408; and @Pandoc; and others]" =?>
          let pandocCite' = pandocInText {
                              citationPrefix = toList "and"
                            }
          in (para $ "See "
                  <> cite [dominikInText] ""
                  <> "," <> space
                  <> cite [pandocCite'] ""
                  <> "," <> space <> "and others")
    ]

  , "Inline LaTeX symbol" =:
      "\\dots" =?>
      para "…"

  , "Inline LaTeX command" =:
      "\\textit{Emphasised}" =?>
      para (emph "Emphasised")

  , "Inline LaTeX command with spaces" =:
      "\\emph{Emphasis mine}" =?>
      para (emph "Emphasis mine")

  , "Inline LaTeX math symbol" =:
      "\\tau" =?>
      para (emph "τ")

  , "Unknown inline LaTeX command" =:
      "\\notacommand{foo}" =?>
      para (rawInline "latex" "\\notacommand{foo}")

  , "Export snippet" =:
      "@@html:<kbd>M-x org-agenda</kbd>@@" =?>
      para (rawInline "html" "<kbd>M-x org-agenda</kbd>")

  , "MathML symbol in LaTeX-style" =:
      "There is a hackerspace in Lübeck, Germany, called nbsp (unicode symbol: '\\nbsp')." =?>
      para ("There is a hackerspace in Lübeck, Germany, called nbsp (unicode symbol: ' ').")

  , "MathML symbol in LaTeX-style, including braces" =:
      "\\Aacute{}stor" =?>
      para "Ástor"

  , "MathML copy sign" =:
      "\\copy" =?>
      para "©"

  , "MathML symbols, space separated" =:
      "\\ForAll \\Auml" =?>
      para "∀ Ä"

  , "LaTeX citation" =:
      "\\cite{Coffee}" =?>
      let citation = Citation
                     { citationId = "Coffee"
                     , citationPrefix = []
                     , citationSuffix = []
                     , citationMode = NormalCitation
                     , citationNoteNum = 0
                     , citationHash = 0}
      in (para . cite [citation] $ rawInline "latex" "\\cite{Coffee}")

  , "Macro" =:
      T.unlines [ "#+MACRO: HELLO /Hello, $1/"
                , "{{{HELLO(World)}}}"
                ] =?>
      para (emph "Hello, World")

  , "Macro repeting its argument" =:
      T.unlines [ "#+MACRO: HELLO $1$1"
                , "{{{HELLO(moin)}}}"
                ] =?>
      para "moinmoin"

  , "Macro called with too few arguments" =:
      T.unlines [ "#+MACRO: HELLO Foo $1 $2 Bar"
                , "{{{HELLO()}}}"
                ] =?>
      para "Foo Bar"

  , testGroup "Footnotes" Note.tests
  , testGroup "Smart punctuation" Smart.tests
  ]
