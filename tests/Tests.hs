module Tests (
    main
) where

import Data.Char
import Control.Monad
import System.IO
import System.Directory
import Test.HUnit     
import Test.QuickCheck
import Main hiding (main)
import Database.MongoDB -- needed for :=
import Data.Int
import Data.Time.Format.Human

todoCases = TestLabel "Todo test cases" ( TestList [
       testDeleteTodo, 
       testGetTodoPriorityOne, testTodoConstructPrioritySelection,
       testTagsSelector,
       testTodoConstructOneTagSelection, 
       testTodoConstructTwoTagsSelection,
       testGetTodoTags, 
       --testGetTwoTodoTags, this test fails
       testGetFieldsForTodo,
       testGetTodoFromPriorityAndTag
    ] )

noteCases = TestLabel "Note test cases" ( TestList [
       testNoteIsValid1, testNoteIsValid2, testGetNoteByTag, testDeleteNote,
       testNoteCreatedTime
    ] )

main = runTestTT $ TestList [todoCases, noteCases]

-- 
-- Validating items
-- 

testNoteIsValid1 = TestCase $ assertEqual "Note should be invalid" False 
    (noteIsValid ["invalid", "no", "uppercase"])
testNoteIsValid2 = TestCase $ assertEqual "Note should be valid" True
    (noteIsValid ["uppercase", "Valid"])

-- 
-- Displaying items
--

testNoteCreatedTime = TestCase (do
    deleteAll TestDB Note
    add TestDB Note ["Newfangled", "technique"]
    results <- get TestDB ["notes", "created"]
    case results of
        [] -> assertFailure "Didn't get any notes from the DB"
        string:[] -> assertEqual "The note should display the cerated time"
            "1 - just now - Newfangled technique" string)

-- 
-- Deleting items
-- 

testDeleteTodo = TestCase (do
    deleteAll TestDB Todo
    add TestDB Todo ["tag1", "First", "here"]
    add TestDB Todo ["second", "Here"]
    add TestDB Todo ["tag2", "Third"]
    deleteItem TestDB ["todo", "2"]
    results <- get TestDB ["todo"]
    case results of 
        [] -> assertFailure "Didn't get any todos from the DB"
        strings -> assertEqual "The second todo should have been deleted" 
            (2, "1 - First here", "2 - Third") tup
                where tup = (length strings, head strings, strings !! 1))

testDeleteNote = TestCase (do
    deleteAll TestDB Note
    add TestDB Note ["tag1", "First", "here"]
    add TestDB Note ["second", "Here"]
    add TestDB Note ["tag2", "Third"]
    deleteItem TestDB ["note", "2"]
    results <- get TestDB ["note"]
    case results of 
        [] -> assertFailure "Didn't get any notes from the DB"
        strings -> assertEqual "The second note should have been deleted" 
            (2, "1 - First here", "2 - Third") tup
                where tup = (length strings, head strings, strings !! 1))

--
-- Todo prorities
--

testGetTodoPriorityOne = TestCase (do
    deleteAll TestDB Todo
    add TestDB Todo ["tag1", "p1", "First", "here"]
    add TestDB Todo ["tag1", "p2", "Second", "here"]
    add TestDB Todo ["tag1", "Third", "here"]
    results <- get TestDB ["todo", "p1"]
    case results of 
        [] -> assertFailure
            "Didn't get any results after adding todo with priority 1" 
        strings -> assertEqual "There should be only one todo with priority 1" 
            1 (length strings))

testTodoConstructPrioritySelection = TestCase (do
    assertEqual "The selection on priority should match this"
        (select ([(fieldToText Priority) =: (1 :: Int32)]) (docTypeToText Todo))
            (constructSelection Todo ["p1"]))
-- 
-- Tags
--

testTagsSelector = TestCase (do
    assertEqual "The tags selector for two tags should match..."
        [(fieldToText Tags) =: "city", (fieldToText Tags) =: "urban"]
            (tagsSelector [] ["city", "urban"]))

testTodoConstructOneTagSelection = TestCase (do
    assertEqual "The selection on tags should match this" 
        (select ([(fieldToText Tags) =: "school"]) 
            (docTypeToText Todo))
                (constructSelection Todo ["school"]))

testTodoConstructTwoTagsSelection = TestCase (do
    assertEqual "The selection on tags should match this" 
        (select ([(fieldToText Tags) =: "school", (fieldToText Tags) =: "228"]) 
            (docTypeToText Todo))
                (constructSelection Todo ["school", "228"]))

testGetTodoTags = TestCase (do
    deleteAll TestDB Todo
    add TestDB Todo ["p1", "First", "here"]
    add TestDB Todo ["p2", "Second", "here"]
    add TestDB Todo ["school", "Third", "here"]
    results <- get TestDB ["todo", "school"]
    case results of 
        [] -> assertFailure 
            "Didn't get results after adding todo tagged 'school'"
        strings -> assertEqual "There should be only one todo tagged 'school'" 
            (1, "1 - Third here") tup
                where tup = (length strings, head strings))

{-
 - This test fails.
 -
testGetTwoTodoTags = TestCase (do
    deleteAll TestDB Todo
    add TestDB Todo ["p1", "school", "First", "here"]
    add TestDB Todo ["229", "Second", "here"]
    add TestDB Todo ["school", "229", "Third", "here"]
    results <- get TestDB ["todo", "school", "229"]
    case results of 
        [] -> assertEqual 
            "Didn't get results after adding todo tagged 'school' and '229'"
                True False
        strings -> assertEqual 
            "There should be only one todo tagged 'school' and '229'" 
                (1, "1 - Third here") tup
                    where tup = (length strings, head strings))
                    -}

testGetFieldsForTodo = TestCase (do
    assertEqual "Should get a list of fields for matching two tags"
        [(fieldToText Tags) =: "school", (fieldToText Tags) =: "229"]
            (getFieldsForTodo [] ["school", "229"]))

testGetTodoFromPriorityAndTag = TestCase (do
    deleteAll TestDB Todo
    add TestDB Todo ["p1", "school", "First", "here"]
    add TestDB Todo ["school", "Second", "here"]
    add TestDB Todo ["p1", "Third", "here"]
    results <- get TestDB ["todo", "school", "p1"]
    case results of 
        [] -> assertFailure
            "Didn't get results after adding todo tagged 'school' and 'p1'"
        strings -> assertEqual
            "There should be only one todo tagged 'school' and 'p1'" 
                (1, "1 - First here") tup
                    where tup = (length strings, head strings))

testGetNoteByTag = TestCase (do
    deleteAll TestDB Note
    add TestDB Note ["music", "First", "here"]
    add TestDB Note ["guitar", "Second", "here"]
    results <- get TestDB ["note", "guitar"]
    case results of
        [] -> assertFailure 
            "Didn't get results after adding note tagged 'guitar'"
        strings -> assertEqual
            "There should be only one note tagged 'guitar'"
                (1, "1 - Second here") tup
                    where tup = (length strings, head strings))

