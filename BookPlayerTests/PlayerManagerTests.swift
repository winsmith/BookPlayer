//
//  PlayerManagerTests.swift
//  BookPlayerTests
//
//  Created by gianni.carlo on 18/5/22.
//  Copyright © 2022 Tortuga Power. All rights reserved.
//

import Foundation
import MediaPlayer

@testable import BookPlayer
@testable import BookPlayerKit
import Combine
import XCTest

class PlayerManagerTests: XCTestCase {
  var sut: PlayerManager!

  override func setUp() {
    // Clean up stored configs
    UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.chapterContextEnabled.rawValue)
    UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.remainingTimeEnabled.rawValue)
    self.sut = PlayerManager(
      libraryService: EmptyLibraryServiceMock(),
      playbackService: EmptyPlaybackServiceMock(),
      speedService: EmptySpeedServiceMock()
    )
  }

  private func generatePlayableItem() -> PlayableItem {
    let testChapter = PlayableChapter(
      title: "test chapter 1",
      author: "test author chapter",
      start: 0,
      duration: 50,
      relativePath: "",
      index: 0
    )
    let testChapter2 = PlayableChapter(
      title: "test chapter 2",
      author: "test author chapter 2",
      start: 51,
      duration: 100,
      relativePath: "",
      index: 1
    )
    return PlayableItem(
      title: "test book",
      author: "test author",
      chapters: [testChapter, testChapter2],
      currentTime: 0,
      duration: 100,
      relativePath: "",
      parentFolder: nil,
      percentCompleted: 10,
      isFinished: false,
      isBoundBook: false
    )
  }

  func testUpdatingEmptyNowPlayingBookTime() {
    self.sut.setNowPlayingBookTime()

    XCTAssertNil(self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate])
    XCTAssertNil(self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime])
    XCTAssertNil(self.sut.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration])
    XCTAssertNil(self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress])
  }

  func testUpdatingGlobalNowPlayingBookTime() {
    // playback speed shouldn't affect duration time set
    self.sut.setSpeed(2)
    // mocked playable item
    let playableItem = generatePlayableItem()
    playableItem.currentTime = 20

    self.sut.currentItem = playableItem
    self.sut.setNowPlayingBookTime()

    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double) == 1)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double) == 20)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double) == 100)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] as? Double) == 0.2)
  }

  func testUpdatingGlobalRemainingNowPlayingBookTime() {
    // playback speed should affect duration time set
    self.sut.setSpeed(2)
    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.remainingTimeEnabled.rawValue)
    // mocked playable item
    let playableItem = generatePlayableItem()
    playableItem.currentTime = 20

    self.sut.currentItem = playableItem
    self.sut.setNowPlayingBookTime()

    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double) == 1)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double) == 20)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double) == 60)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] as? Double) == 0.2)
  }

  func testUpdatingChapterNowPlayingBookTime() {
    // playback speed shouldn't affect duration time set
    self.sut.setSpeed(2)
    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.chapterContextEnabled.rawValue)
    // mocked playable item
    let playableItem = generatePlayableItem()
    playableItem.currentTime = 10

    self.sut.currentItem = playableItem
    self.sut.setNowPlayingBookTime()

    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double) == 1)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double) == 10)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double) == 50)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] as? Double) == 0.20)
  }

  func testUpdatingChapterRemainingNowPlayingBookTime() {
    // playback speed should affect duration time set
    self.sut.setSpeed(2)
    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.remainingTimeEnabled.rawValue)
    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.chapterContextEnabled.rawValue)
    // mocked playable item
    let playableItem = generatePlayableItem()
    playableItem.currentTime = 10

    self.sut.currentItem = playableItem
    self.sut.setNowPlayingBookTime()

    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double) == 1)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double) == 10)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] as? Double) == 30)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] as? Double) == 0.20)
  }

  func testUpdatingEmptyNowPlayingBookTitle() {
    let playableItem = generatePlayableItem()
    let chapter = playableItem.chapters.first!

    self.sut.setNowPlayingBookTitle(chapter: chapter)

    XCTAssertNil(self.sut.nowPlayingInfo[MPMediaItemPropertyTitle])
    XCTAssertNil(self.sut.nowPlayingInfo[MPMediaItemPropertyArtist])
    XCTAssertNil(self.sut.nowPlayingInfo[MPMediaItemPropertyAlbumTitle])
  }

  func testUpdatingNowPlayingBookTitle() {
    let playableItem = generatePlayableItem()
    let chapter = playableItem.chapters.first!

    self.sut.currentItem = playableItem
    self.sut.setNowPlayingBookTitle(chapter: chapter)

    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyTitle] as? String) == chapter.title)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyArtist] as? String) == playableItem.title)
    XCTAssertTrue((self.sut.nowPlayingInfo[MPMediaItemPropertyAlbumTitle] as? String) == playableItem.author)
  }
}
