//
// Created by Qiao Zhang on 2/18/17.
// Copyright (c) 2017 Qiao Zhang. All rights reserved.
//

import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!

func playBackgroundMusic(filename: String) {
  let resourceUrl = Bundle.main.url(forResource: filename,
                                    withExtension: nil)
  guard let url = resourceUrl else { return }
  do {
    try backgroundMusicPlayer = AVAudioPlayer(contentsOf: url)
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
  } catch {
    return
  }
}
