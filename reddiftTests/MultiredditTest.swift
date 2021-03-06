//
//  MultiTest.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import XCTest

extension MultiredditTest {
    /// Get user's multireddit list
    func getOwnMultireddit() -> [Multireddit] {
        let msg = "Get own multireddit list."
        var list:[Multireddit] = []
        let documentOpenExpectation = self.expectationWithDescription("getMineMultireddit")
        do {
            try self.session?.getMineMultireddit({ (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multireddits):
                    list.appendContentsOf(multireddits)
                }
                XCTAssert(list.count > 0, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
        return list
    }
    
    /// Create a new multireddit
    func createMultireddit(name:String) -> Multireddit? {
        var createdMultireddit:Multireddit? = nil
        let msg = "Create a new multireddit whose name is \(name)."
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.createMultireddit(name, descriptionMd: "", completion: { (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multireddit):
                    createdMultireddit = multireddit
                }
                XCTAssert(createdMultireddit != nil, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
        return createdMultireddit
    }
    
    /// Delete specified multireddit.
    func deleteMultireddit(multireddit:Multireddit) {
        let msg = "Delete multireddit whose name is \(multireddit.name)."
        var isSucceeded = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.deleteMultireddit(multireddit, completion: { (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success:
                    isSucceeded = true
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
    }

    /// Add a subreddit to the specified multireddit.
    func addSubredditToMultireddit(subredditDisplayName:String, multireddit:Multireddit) {
        let msg = "Add subreddit, \(subredditDisplayName) to multireddit whose name is \(multireddit.name)."
        var isSucceeded:Bool = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.addSubredditToMultireddit(multireddit, subredditDisplayName: subredditDisplayName, completion: { (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success:
                    isSucceeded = true
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
    }
}

class MultiredditTest: SessionTestSpec {
    let createdMultiredditName = "created"
    let nameForCopy = "copied"
    let nameForRename = "renamed"
    
    var createdMultireddit:Multireddit? = nil
    var copiedMultireddit:Multireddit? = nil
    var renamedMultireddit:Multireddit? = nil
    var defaultMultiredditNameList:[String] = []
    
    override func setUp() {
        super.setUp()
        
        /// Save number of own multireddits before test starts.
        self.defaultMultiredditNameList = getOwnMultireddit().map({$0.name})
        /// Create a new multireddit for testing.
        self.createdMultireddit = createMultireddit(createdMultiredditName)
    }
    
    override func tearDown() {
        super.tearDown()
        
        /// Clean up all multireddits that are generated for testing.
        if let multireddit = self.createdMultireddit { deleteMultireddit(multireddit); self.createdMultireddit = nil }
        if let multireddit = self.renamedMultireddit { deleteMultireddit(multireddit); self.renamedMultireddit = nil }
        if let multireddit = self.copiedMultireddit { deleteMultireddit(multireddit); self.copiedMultireddit = nil }
        
        /// Assert when multireddit list's status is NOT restored.
        XCTAssert(defaultMultiredditNameList.hasSameElements(getOwnMultireddit().map({$0.name})))
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Confirm the multireddit list.
     3. Delete the multireddit.
    */
    func testCreateAndDeleteMultireddit() {
        let expected = defaultMultiredditNameList + [createdMultiredditName]
        XCTAssert(expected.hasSameElements(getOwnMultireddit().map({$0.name})))
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Rename the multireddit list.
     3. Confirm the multireddit list.
     4. Delete added multireddits.
     */
    func testRenameMultireddit() {
        let nameForRename = "renamed"
        let msg = "Test renaming a multireddit."
        var isSucceeded = false
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.renameMultireddit(multireddit, newDisplayName: nameForRename, completion:{ (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multireddit):
                    self.renamedMultireddit = multireddit
                    self.createdMultireddit = nil
                    isSucceeded = (multireddit.displayName == nameForRename)
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }

        let currentMultiredditNameList = getOwnMultireddit().map({$0.displayName})
        XCTAssert([nameForRename].checkAllElementsIncludedIn(currentMultiredditNameList), "error")
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Copy the multireddit list.
     3. Confirm the multireddit list.
     4. Delete added multireddits.
     */
    func testCopyMultireddit() {
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        let msg = "Test copying a multireddit."
        var isSucceeded = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.copyMultireddit(multireddit, newDisplayName: nameForCopy, completion:{ (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multireddit):
                    self.copiedMultireddit = multireddit
                    isSucceeded = (multireddit.displayName == self.nameForCopy)
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }

        let expected = defaultMultiredditNameList + [createdMultiredditName, nameForCopy]
        XCTAssert(expected.hasSameElements(getOwnMultireddit().map({$0.name})))
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Copy the multireddit list.
     3. Rename orinal multireddit with copied multireddit's name, illegally.
     4. Catch error code 409.
     5. Delete added multireddits.
     */
    func testRenameMultiredditError() {
        let failedName = nameForCopy
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        let msg = "Test copying a multireddit with the existing name, as \(nameForCopy)."
        var isSucceeded = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.copyMultireddit(multireddit, newDisplayName: nameForCopy, completion:{ (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multireddit):
                    self.copiedMultireddit = multireddit
                    isSucceeded = (multireddit.displayName == self.nameForCopy)
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
        
        let expected = defaultMultiredditNameList + [createdMultiredditName, nameForCopy]
        XCTAssert(expected.hasSameElements(getOwnMultireddit().map({$0.name})))
        
        do {
            let msg = "Test renaming the multireddit, as \(multireddit.name), with the existing name which is \(failedName)."
            var isSucceeded = false
            let documentOpenExpectation = self.expectationWithDescription(msg)
            do {
                try self.session?.renameMultireddit(multireddit, newDisplayName: failedName, completion:{ (result) -> Void in
                    switch result {
                    case .Failure(let error):
                        isSucceeded = (error.code == 409)
                    case .Success(let multireddit):
                        print(multireddit)
                        self.renamedMultireddit = multireddit
                    }
                    XCTAssert(isSucceeded, msg)
                    documentOpenExpectation.fulfill()
                })
                self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
            }
            catch { XCTFail((error as NSError).description) }
        }
        
        let expected2 = defaultMultiredditNameList + [createdMultiredditName, nameForCopy]
        XCTAssert(expected2.hasSameElements(getOwnMultireddit().map({$0.name})))
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Update the description of the multireddit using 'putMultiredditDescription'.
     3. Check, the description of the multireddit is "updated description"
     */
    func testPutMultiredditDescription() {
        let updatedDescription = "updated description"
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        let msg = "Test putting a new description to the multireddit, using 'putMultiredditDescription'."
        var isSucceeded = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.putMultiredditDescription(multireddit, description: updatedDescription, completion:{ (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let multiredditDescription):
                    if multiredditDescription.bodyMd == updatedDescription {
                        isSucceeded = true
                    }
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Update the description of the multireddit using 'updateMultireddit'.
     3. Check, the description of the multireddit is "updated description"
     */
    func testUpdateMultiredditDescription() {
        let updatedDescription = "updated description"
        guard var multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        let msg = "Test updating a new description to the multireddit, using 'updateMultireddit'."
        var isSucceeded = false
        multireddit.iconName = .Science
        multireddit.descriptionMd = updatedDescription
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.updateMultireddit(multireddit, completion: { (result) -> Void in
                switch result {
                case .Failure(let error):
                    print(error.description)
                case .Success(let updatedMultireddit):
                    XCTAssert(updatedMultireddit.descriptionMd == updatedDescription, msg)
                    XCTAssert(updatedMultireddit.iconName.rawValue == MultiredditIconName.Science.rawValue, msg)
                    isSucceeded = true
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
    }
    
    /**
     Test procedure
     1. Fetch the list of public multireddits of redditch_dev.
     2. Check, the list of public multireddits' name is ["public_test1", "public_test2"].
     */
    func testGetAndConfirmPublicMultiredditList() {
        do {
            let msg = "Test getting redditch_dev public multireddit list and check whether the list includes specified subreddits."
            var isSucceeded:Bool = false
            let documentOpenExpectation = self.expectationWithDescription(msg)
            do {
                try self.session?.getPublicMultiredditOfUsername("redditch_dev", completion: { (result) -> Void in
                    switch result {
                    case .Failure(let error):
                        print(error.description)
                    case .Success(let multireddits):
                        isSucceeded = (["public_test1", "public_test2"].hasSameElements(multireddits.map({$0.name})))
                    }
                    XCTAssert(isSucceeded, msg)
                    documentOpenExpectation.fulfill()
                })
                self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
            }
            catch { XCTFail((error as NSError).description) }
        }
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Add "swift" subreddit to the multireddit.
     3. Add "redditdev" subreddit to the multireddit.
     4. Check whether the multireddit includes "swift" and "redditdev".
     */
    func testAddSubredditFromMultireddit() {
        let targetSubreddits = ["swift", "redditdev"]
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        
        addSubredditToMultireddit(targetSubreddits[0], multireddit: multireddit)
        addSubredditToMultireddit(targetSubreddits[1], multireddit: multireddit)
        
        var candidates = getOwnMultireddit().filter({$0.name == multireddit.name})
        if candidates.count == 0 { XCTFail("Error"); return }
        let updatedMultireddit = candidates[0]
        XCTAssert(updatedMultireddit.subreddits.hasSameElements(targetSubreddits), "error")
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Add "swift" subreddit to the multireddit.
     3. Add "ahfuhaofhaeiufaheihihfiuawe" subreddit to the multireddit as error data.
     4. Catch error code 400.
     5. Check whether the multireddit includes only "swift".
     */
    func testAddSubredditFromMultiredditErrorCase() {
        let targetSubreddits = ["swift"]
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        
        addSubredditToMultireddit(targetSubreddits[0], multireddit: multireddit)
        
        let msg = "Test adding an inavaialbe subreddit to the multireddit."
        var isSucceeded:Bool = false
        let documentOpenExpectation = self.expectationWithDescription(msg)
        do {
            try self.session?.addSubredditToMultireddit(multireddit, subredditDisplayName: "ahfuhaofhaeiufaheihihfiuawe", completion: { (result) -> Void in
                switch result {
                case .Failure(let error):
                    isSucceeded = (error.code == 400)
                case .Success:
                    print("OK...?")
                }
                XCTAssert(isSucceeded, msg)
                documentOpenExpectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
        }
        catch { XCTFail((error as NSError).description) }
        
        var candidates = getOwnMultireddit().filter({$0.name == multireddit.name})
        if candidates.count == 0 { XCTFail("Error"); return }
        let updatedMultireddit = candidates[0]
        XCTAssert(updatedMultireddit.subreddits.hasSameElements(targetSubreddits), "error")
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Add "swift" subreddit to the multireddit.
     3. Add "redditdev" subreddit to the multireddit.
     4. Remove "redditdev" subreddit from the multireddit.
     5. Check whether the multireddit includes only "swift".
     */
    func testAddAndRemoveSubredditForMultireddit() {
        let targetSubreddits = ["swift", "redditdev"]
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        
        addSubredditToMultireddit(targetSubreddits[0], multireddit: multireddit)
        addSubredditToMultireddit(targetSubreddits[1], multireddit: multireddit)
        
        do {
            let msg = "Test adding and deleting an subreddit for the multireddit."
            print(msg)
            var isSucceeded:Bool = false
            let documentOpenExpectation = self.expectationWithDescription(msg)
            do {
                try self.session?.removeSubredditFromMultireddit(multireddit, subredditDisplayName: targetSubreddits[1], completion: { (result) -> Void in
                    switch result {
                    case .Failure(let error):
                        print(error.description)
                    case .Success:
                        isSucceeded = true
                    }
                    XCTAssert(isSucceeded, msg)
                    documentOpenExpectation.fulfill()
                })
                self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
            }
            catch { XCTFail((error as NSError).description) }
        }
        
        var candidates = getOwnMultireddit().filter({$0.name == multireddit.name})
        if candidates.count == 0 { XCTFail("Error"); return }
        let updatedMultireddit = candidates[0]
        XCTAssert(updatedMultireddit.subreddits.hasSameElements(["swift"]), "error")
    }
    
    /**
     Test procedure
     1. Create a new multireddit.
     2. Add "swift" subreddit to the multireddit.
     3. Add "redditdev" subreddit to the multireddit.
     4. Remove "ahfuhaofhaeiufaheihihfiuawe" subreddit from the multireddit.
     5. Catch error code 400.
     6. Check whether the multireddit includes "swift" and "redditdev".
     */
    func testAddAndRemoveSubredditForMultiredditErrorCase() {
        let targetSubreddits = ["swift", "redditdev"]
        guard let multireddit = self.createdMultireddit else { XCTFail("Error"); return }
        
        addSubredditToMultireddit(targetSubreddits[0], multireddit: multireddit)
        addSubredditToMultireddit(targetSubreddits[1], multireddit: multireddit)
        
        do {
            let msg = "Test adding and deleting an subreddit for the multireddit."
            print(msg)
            var isSucceeded:Bool = false
            let documentOpenExpectation = self.expectationWithDescription(msg)
            do {
                try self.session?.removeSubredditFromMultireddit(multireddit, subredditDisplayName: "ahfuhaofhaeiufaheihihfiuawe", completion: { (result) -> Void in
                    switch result {
                    case .Failure(let error):
                        isSucceeded = (error.code == 400)
                    case .Success:
                        print("OK...?")
                    }
                    XCTAssert(isSucceeded, msg)
                    documentOpenExpectation.fulfill()
                })
                self.waitForExpectationsWithTimeout(self.timeoutDuration, handler: nil)
            }
            catch { XCTFail((error as NSError).description) }
        }
        
        var candidates = getOwnMultireddit().filter({$0.name == multireddit.name})
        if candidates.count == 0 { XCTFail("Error"); return }
        let updatedMultireddit = candidates[0]
        XCTAssert(updatedMultireddit.subreddits.hasSameElements(targetSubreddits), "error")
    }
}
